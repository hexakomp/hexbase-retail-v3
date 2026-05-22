<?php

namespace App\Services;

use App\Models\Receipt;
use App\Models\ReceiptAllocation;
use App\Models\SalesInvoice;
use Illuminate\Support\Facades\DB;

/**
 * ReceiptService — Business logic for customer receipt (money in) processing.
 *
 * Responsibilities:
 *  - Draft creation and update (with optional invoice allocations)
 *  - Post: status → confirmed, double-entry, update invoice outstanding amounts
 *  - Cancel: reverse ledger, restore invoice outstanding amounts
 */
class ReceiptService
{
    public function __construct(
        protected AccountingEngine         $accounting,
        protected NumberingSequenceService $numbering,
    ) {}

    // ── Public API ───────────────────────────────────────────────────────────

    public function createFromRequest(array $data, int $userId): Receipt
    {
        return DB::connection('tenant')->transaction(function () use ($data, $userId) {
            $receiptNumber = $this->numbering->next('receipt');

            $receipt = Receipt::create([
                'receipt_number'   => $receiptNumber,
                'receipt_date'     => $data['receipt_date'],
                'customer_id'      => $data['customer_id'],
                'bank_account_id'  => $data['bank_account_id'] ?? null,
                'payment_mode'     => $data['payment_mode'] ?? 'cash',
                'reference_number' => $data['reference_number'] ?? null,
                'amount'           => $data['amount'],
                'advance_amount'   => 0,
                'narration'        => $data['narration'] ?? null,
                'notes'            => $data['notes'] ?? null,
                'custom_fields'    => $data['custom_fields'] ?? null,
                'status'           => 'draft',
                'created_by'       => $userId,
            ]);

            $this->saveAllocations($receipt, $data['allocations'] ?? []);

            if (($data['status'] ?? 'draft') === 'confirmed') {
                $this->post($receipt, $userId);
            }

            return $receipt->fresh(['customer', 'allocations.salesInvoice']);
        });
    }

    public function updateFromRequest(Receipt $receipt, array $data, int $userId): Receipt
    {
        if ($receipt->status !== 'draft') {
            throw new \RuntimeException('Only draft receipts can be edited.');
        }

        return DB::connection('tenant')->transaction(function () use ($receipt, $data, $userId) {
            $receipt->update([
                'receipt_date'     => $data['receipt_date'],
                'customer_id'      => $data['customer_id'],
                'bank_account_id'  => $data['bank_account_id'] ?? null,
                'payment_mode'     => $data['payment_mode'] ?? $receipt->payment_mode,
                'reference_number' => $data['reference_number'] ?? null,
                'amount'           => $data['amount'],
                'narration'        => $data['narration'] ?? null,
                'notes'            => $data['notes'] ?? null,
                'custom_fields'    => $data['custom_fields'] ?? null,
            ]);

            $receipt->allocations()->delete();
            $this->saveAllocations($receipt, $data['allocations'] ?? []);

            return $receipt->fresh(['customer', 'allocations.salesInvoice']);
        });
    }

    public function post(Receipt $receipt, int $userId): Receipt
    {
        if ($receipt->status !== 'draft') {
            throw new \RuntimeException('Only draft receipts can be posted.');
        }

        $receipt->loadMissing('allocations');
        $totalAllocated = $receipt->allocations->sum('allocated_amount');

        if ($totalAllocated > $receipt->amount) {
            throw new \RuntimeException(
                'Total allocated amount (' . $totalAllocated . ') exceeds receipt amount (' . $receipt->amount . ').'
            );
        }

        $advanceAmount = round($receipt->amount - $totalAllocated, 2);

        DB::connection('tenant')->transaction(function () use ($receipt, $advanceAmount, $userId) {
            $receipt->update([
                'status'         => 'confirmed',
                'advance_amount' => $advanceAmount,
            ]);

            // Update each sales invoice outstanding balance
            foreach ($receipt->allocations as $alloc) {
                DB::connection('tenant')
                    ->table('sales_invoices')
                    ->where('id', $alloc->sales_invoice_id)
                    ->decrement('balance_amount', $alloc->allocated_amount);

                // Update invoice status: paid / partially_paid
                $inv = SalesInvoice::find($alloc->sales_invoice_id);
                if ($inv && $inv->balance_amount <= 0) {
                    $inv->update(['status' => 'paid', 'balance_amount' => 0]);
                } elseif ($inv) {
                    $inv->update(['status' => 'partially_paid']);
                }
            }

            $this->postLedgerEntries($receipt, $userId);
        });

        return $receipt->fresh();
    }

    public function cancel(Receipt $receipt, string $reason, int $userId): Receipt
    {
        if ($receipt->status === 'draft') {
            // Draft cancellations just soft-delete
            $receipt->delete();

            return $receipt;
        }

        DB::connection('tenant')->transaction(function () use ($receipt, $reason, $userId) {
            // Restore invoice outstanding balances
            foreach ($receipt->allocations as $alloc) {
                DB::connection('tenant')
                    ->table('sales_invoices')
                    ->where('id', $alloc->sales_invoice_id)
                    ->increment('balance_amount', $alloc->allocated_amount);

                // Revert invoice status back to confirmed / partially_paid
                $inv = SalesInvoice::find($alloc->sales_invoice_id);
                if ($inv) {
                    $inv->update(['status' => $inv->balance_amount > 0 ? 'confirmed' : 'paid']);
                }
            }

            $this->accounting->reverse(
                $receipt,
                now()->toDateString(),
                'REV-' . $receipt->receipt_number,
                $userId
            );

            $receipt->update([
                'status'    => 'cancelled',
                'narration' => trim(($receipt->narration ?? '') . "\nCancelled: {$reason}"),
            ]);
        });

        return $receipt->fresh();
    }

    // ── Private helpers ──────────────────────────────────────────────────────

    private function saveAllocations(Receipt $receipt, array $allocations): void
    {
        foreach ($allocations as $alloc) {
            $allocatedAmount = (float) ($alloc['allocated_amount'] ?? 0);
            if ($allocatedAmount <= 0) {
                continue;
            }

            ReceiptAllocation::create([
                'receipt_id'       => $receipt->id,
                'sales_invoice_id' => $alloc['sales_invoice_id'],
                'allocated_amount' => $allocatedAmount,
            ]);
        }
    }

    private function postLedgerEntries(Receipt $receipt, int $userId): void
    {
        // Debit: cash or bank account (money received)
        // Credit: accounts receivable (outstanding cleared)

        $debitAccountCode = $this->resolveDebitAccount($receipt);

        $entries = [
            [
                'account_code' => $debitAccountCode,
                'debit'        => $receipt->amount,
                'credit'       => 0,
                'narration'    => "Receipt {$receipt->receipt_number}",
            ],
            [
                'account_code' => '2001',
                'debit'        => 0,
                'credit'       => $receipt->amount,
                'narration'    => "Receipt {$receipt->receipt_number}",
            ],
        ];

        $this->accounting->post(
            $entries,
            $receipt->receipt_number,
            $receipt->receipt_date->toDateString(),
            $receipt,
            $userId
        );
    }

    private function resolveDebitAccount(Receipt $receipt): string
    {
        if ($receipt->payment_mode === 'cash') {
            return 'CASH';
        }

        // Resolve bank account ledger code from bank_accounts table
        if ($receipt->bank_account_id) {
            $accountCode = DB::connection('tenant')
                ->table('bank_accounts')
                ->where('id', $receipt->bank_account_id)
                ->value('account_code');

            if ($accountCode) {
                return $accountCode;
            }
        }

        return 'BANK';
    }
}
