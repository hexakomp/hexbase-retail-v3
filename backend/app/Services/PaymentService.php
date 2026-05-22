<?php

namespace App\Services;

use App\Models\Payment;
use App\Models\PaymentAllocation;
use App\Models\PurchaseInvoice;
use Illuminate\Support\Facades\DB;

/**
 * PaymentService — Business logic for vendor payment (money out) processing.
 *
 * Responsibilities:
 *  - Draft creation and update (with optional purchase invoice allocations)
 *  - Post: status → confirmed, double-entry, update invoice outstanding amounts
 *  - Cancel: reverse ledger, restore invoice outstanding amounts
 */
class PaymentService
{
    public function __construct(
        protected AccountingEngine         $accounting,
        protected NumberingSequenceService $numbering,
    ) {}

    // ── Public API ───────────────────────────────────────────────────────────

    public function createFromRequest(array $data, int $userId): Payment
    {
        return DB::connection('tenant')->transaction(function () use ($data, $userId) {
            $paymentNumber = $this->numbering->next('payment');

            $payment = Payment::create([
                'payment_number'   => $paymentNumber,
                'payment_date'     => $data['payment_date'],
                'vendor_id'        => $data['vendor_id'],
                'bank_account_id'  => $data['bank_account_id'] ?? null,
                'payment_mode'     => $data['payment_mode'] ?? 'bank_transfer',
                'reference_number' => $data['reference_number'] ?? null,
                'amount'           => $data['amount'],
                'tds_amount'       => $data['tds_amount'] ?? 0,
                'advance_amount'   => 0,
                'narration'        => $data['narration'] ?? null,
                'notes'            => $data['notes'] ?? null,
                'custom_fields'    => $data['custom_fields'] ?? null,
                'status'           => 'draft',
                'created_by'       => $userId,
            ]);

            $this->saveAllocations($payment, $data['allocations'] ?? []);

            if (($data['status'] ?? 'draft') === 'confirmed') {
                $this->post($payment, $userId);
            }

            return $payment->fresh(['vendor', 'allocations.purchaseInvoice']);
        });
    }

    public function updateFromRequest(Payment $payment, array $data, int $userId): Payment
    {
        if ($payment->status !== 'draft') {
            throw new \RuntimeException('Only draft payments can be edited.');
        }

        return DB::connection('tenant')->transaction(function () use ($payment, $data, $userId) {
            $payment->update([
                'payment_date'     => $data['payment_date'],
                'vendor_id'        => $data['vendor_id'],
                'bank_account_id'  => $data['bank_account_id'] ?? null,
                'payment_mode'     => $data['payment_mode'] ?? $payment->payment_mode,
                'reference_number' => $data['reference_number'] ?? null,
                'amount'           => $data['amount'],
                'tds_amount'       => $data['tds_amount'] ?? $payment->tds_amount,
                'narration'        => $data['narration'] ?? null,
                'notes'            => $data['notes'] ?? null,
                'custom_fields'    => $data['custom_fields'] ?? null,
            ]);

            $payment->allocations()->delete();
            $this->saveAllocations($payment, $data['allocations'] ?? []);

            return $payment->fresh(['vendor', 'allocations.purchaseInvoice']);
        });
    }

    public function post(Payment $payment, int $userId): Payment
    {
        if ($payment->status !== 'draft') {
            throw new \RuntimeException('Only draft payments can be posted.');
        }

        $payment->loadMissing('allocations');
        $totalAllocated = $payment->allocations->sum('allocated_amount');

        if ($totalAllocated > $payment->amount) {
            throw new \RuntimeException(
                'Total allocated amount (' . $totalAllocated . ') exceeds payment amount (' . $payment->amount . ').'
            );
        }

        $advanceAmount = round($payment->amount - $totalAllocated, 2);

        DB::connection('tenant')->transaction(function () use ($payment, $advanceAmount, $userId) {
            $payment->update([
                'status'         => 'confirmed',
                'advance_amount' => $advanceAmount,
            ]);

            // Update each purchase invoice outstanding balance
            foreach ($payment->allocations as $alloc) {
                DB::connection('tenant')
                    ->table('purchase_invoices')
                    ->where('id', $alloc->purchase_invoice_id)
                    ->decrement('balance_amount', $alloc->allocated_amount);

                $inv = PurchaseInvoice::find($alloc->purchase_invoice_id);
                if ($inv && $inv->balance_amount <= 0) {
                    $inv->update(['status' => 'paid', 'balance_amount' => 0]);
                } elseif ($inv) {
                    $inv->update(['status' => 'partially_paid']);
                }
            }

            $this->postLedgerEntries($payment, $userId);
        });

        return $payment->fresh();
    }

    public function cancel(Payment $payment, string $reason, int $userId): Payment
    {
        if ($payment->status === 'draft') {
            $payment->delete();

            return $payment;
        }

        DB::connection('tenant')->transaction(function () use ($payment, $reason, $userId) {
            // Restore purchase invoice outstanding balances
            foreach ($payment->allocations as $alloc) {
                DB::connection('tenant')
                    ->table('purchase_invoices')
                    ->where('id', $alloc->purchase_invoice_id)
                    ->increment('balance_amount', $alloc->allocated_amount);

                $inv = PurchaseInvoice::find($alloc->purchase_invoice_id);
                if ($inv) {
                    $inv->update(['status' => $inv->balance_amount > 0 ? 'confirmed' : 'paid']);
                }
            }

            $this->accounting->reverse(
                $payment,
                now()->toDateString(),
                'REV-' . $payment->payment_number,
                $userId
            );

            $payment->update([
                'status'    => 'cancelled',
                'narration' => trim(($payment->narration ?? '') . "\nCancelled: {$reason}"),
            ]);
        });

        return $payment->fresh();
    }

    // ── Private helpers ──────────────────────────────────────────────────────

    private function saveAllocations(Payment $payment, array $allocations): void
    {
        foreach ($allocations as $alloc) {
            $allocatedAmount = (float) ($alloc['allocated_amount'] ?? 0);
            if ($allocatedAmount <= 0) {
                continue;
            }

            PaymentAllocation::create([
                'payment_id'          => $payment->id,
                'purchase_invoice_id' => $alloc['purchase_invoice_id'],
                'allocated_amount'    => $allocatedAmount,
            ]);
        }
    }

    private function postLedgerEntries(Payment $payment, int $userId): void
    {
        // Debit: accounts payable (vendor liability cleared)
        // Credit: cash or bank account (money paid out)

        $creditAccountCode = $this->resolveCreditAccount($payment);

        // Net amount paid: payment.amount - tds_amount
        // TDS is a tax deducted at source — not part of the cash outflow.
        $cashOut = $payment->amount - $payment->tds_amount;

        $entries = [
            [
                'account_code' => '2002',
                'debit'        => $payment->amount,
                'credit'       => 0,
                'narration'    => "Payment {$payment->payment_number}",
            ],
            [
                'account_code' => $creditAccountCode,
                'debit'        => 0,
                'credit'       => $cashOut,
                'narration'    => "Payment {$payment->payment_number}",
            ],
        ];

        // If TDS deducted, credit TDS-PAYABLE for the retained amount
        if ($payment->tds_amount > 0) {
            $entries[] = [
                'account_code' => '3004',
                'debit'        => 0,
                'credit'       => $payment->tds_amount,
                'narration'    => "TDS on payment {$payment->payment_number}",
            ];
        }

        $this->accounting->post(
            $entries,
            $payment->payment_number,
            $payment->payment_date->toDateString(),
            $payment,
            $userId
        );
    }

    private function resolveCreditAccount(Payment $payment): string
    {
        if ($payment->payment_mode === 'cash') {
            return 'CASH';
        }

        if ($payment->bank_account_id) {
            $accountCode = DB::connection('tenant')
                ->table('bank_accounts')
                ->where('id', $payment->bank_account_id)
                ->value('account_code');

            if ($accountCode) {
                return $accountCode;
            }
        }

        return 'BANK';
    }
}
