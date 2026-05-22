<?php

namespace App\Services;

use App\Models\SalesInvoice;
use App\Models\SalesInvoiceLine;
use App\Models\Customer;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;

/**
 * SalesInvoiceService — Full business logic for sales invoicing.
 *
 * Responsibilities:
 *  - Draft creation (store)
 *  - Line GST computation via GstCalculator
 *  - Header aggregation
 *  - Post: status → confirmed, double-entry via AccountingEngine, stock deduction
 *  - Cancel: soft-cancel + ledger reversal
 */
class SalesInvoiceService
{
    public function __construct(
        protected GstCalculator           $gst,
        protected AccountingEngine        $accounting,
        protected NumberingSequenceService $numbering,
    ) {}

    // ── Public API ──────────────────────────────────────────────────────────

    /**
     * Create a draft (or posted) sales invoice from validated request data.
     */
    public function createFromRequest(array $data, int $userId): SalesInvoice
    {
        return DB::connection('tenant')->transaction(function () use ($data, $userId) {
            $customer = Customer::findOrFail($data['customer_id']);
            $supplyType = $this->resolveSupplyType($data, $customer);

            $invoiceNumber = $data['invoice_number'] ?? $this->numbering->next('sales_invoice');

            $invoice = SalesInvoice::create([
                'invoice_number'  => $invoiceNumber,
                'invoice_date'    => $data['invoice_date'],
                'due_date'        => $data['due_date'] ?? null,
                'customer_id'     => $data['customer_id'],
                'customer_billing_address' => $data['customer_billing_address'] ?? $customer->billing_address ?? null,
                'customer_phone'  => $data['customer_phone'] ?? $customer->phone ?? null,
                'customer_pincode'=> $data['customer_pincode'] ?? $customer->pincode ?? null,
                'customer_gstin'  => $data['customer_gstin'] ?? $customer->gstin ?? null,
                'supply_type'     => $supplyType,
                'invoice_type'    => $data['invoice_type'],
                'place_of_supply' => $data['place_of_supply'],
                'payment_terms'   => $data['payment_terms'] ?? null,
                'narration'       => $data['narration'] ?? null,
                'notes'           => $data['notes'] ?? null,
                'internal_notes'  => $data['internal_notes'] ?? null,
                'terms_conditions' => $data['terms_conditions'] ?? null,
                'status'          => 'draft',
                'custom_fields'   => $data['custom_fields'] ?? null,
                'created_by'      => $userId,
                // Totals set below after lines are saved
                'subtotal'        => 0,
                'discount_amount' => 0,
                'taxable_amount'  => 0,
                'cgst_amount'     => 0,
                'sgst_amount'     => 0,
                'igst_amount'     => 0,
                'cess_amount'     => 0,
                'round_off'       => 0,
                'total_amount'    => 0,
                'paid_amount'     => 0,
                'balance_amount'  => 0,
            ]);

            $this->saveLines($invoice, $data['lines'], $supplyType);
            $this->recalcTotals($invoice);

            if (($data['status'] ?? 'draft') === 'posted') {
                $this->post($invoice, $userId);
            }

            return $invoice->fresh(['lines', 'customer']);
        });
    }

    /**
     * Update a draft invoice.
     */
    public function updateFromRequest(SalesInvoice $invoice, array $data, int $userId): SalesInvoice
    {
        if ($invoice->status !== 'draft') {
            throw new \RuntimeException('Only draft invoices can be edited.');
        }

        return DB::connection('tenant')->transaction(function () use ($invoice, $data, $userId) {
            $customer = Customer::findOrFail($data['customer_id']);
            $supplyType = $this->resolveSupplyType($data, $customer);

            $invoice->update([
                'invoice_number'  => $data['invoice_number'] ?? $invoice->invoice_number,
                'invoice_date'    => $data['invoice_date'],
                'due_date'        => $data['due_date'] ?? null,
                'customer_id'     => $data['customer_id'],
                'customer_billing_address' => $data['customer_billing_address'] ?? $customer->billing_address ?? null,
                'customer_phone'  => $data['customer_phone'] ?? $customer->phone ?? null,
                'customer_pincode'=> $data['customer_pincode'] ?? $customer->pincode ?? null,
                'customer_gstin'  => $data['customer_gstin'] ?? $customer->gstin ?? null,
                'supply_type'     => $supplyType,
                'invoice_type'    => $data['invoice_type'],
                'place_of_supply' => $data['place_of_supply'],
                'payment_terms'   => $data['payment_terms'] ?? null,
                'narration'       => $data['narration'] ?? null,
                'notes'           => $data['notes'] ?? null,
                'internal_notes'  => $data['internal_notes'] ?? null,
                'terms_conditions' => $data['terms_conditions'] ?? null,
                'custom_fields'   => $data['custom_fields'] ?? null,
            ]);

            $invoice->lines()->delete();
            $this->saveLines($invoice, $data['lines'], $supplyType);
            $this->recalcTotals($invoice);

            return $invoice->fresh(['lines', 'customer']);
        });
    }

    /**
     * Post a draft invoice: confirmed + double-entry + stock.
     */
    public function post(SalesInvoice $invoice, int $userId): SalesInvoice
    {
        if (! in_array($invoice->status, ['draft'])) {
            throw new \RuntimeException('Only draft invoices can be posted.');
        }

        DB::connection('tenant')->transaction(function () use ($invoice, $userId) {
            $invoice->update(['status' => 'confirmed']);
            $this->postLedgerEntries($invoice, $userId);
            $this->deductStock($invoice);
        });

        return $invoice->fresh();
    }

    /**
     * Cancel an invoice and reverse ledger entries.
     */
    public function cancel(SalesInvoice $invoice, string $reason, int $userId): SalesInvoice
    {
        if ($invoice->status === 'cancelled') {
            throw new \RuntimeException('Invoice is already cancelled.');
        }

        DB::connection('tenant')->transaction(function () use ($invoice, $reason, $userId) {
            $invoice->update([
                'status'    => 'cancelled',
                'narration' => trim(($invoice->narration ?? '') . "\nCancelled: {$reason}"),
            ]);

            if (in_array($invoice->status_before_cancel ?? $invoice->status, ['confirmed', 'partially_paid', 'paid'])) {
                $this->accounting->reverse(
                    $invoice,
                    now()->toDateString(),
                    'REV-' . $invoice->invoice_number,
                    $userId
                );
            }
        });

        return $invoice->fresh();
    }

    /**
     * Stateless GST preview (no DB write).
     */
    public function preview(array $data): array
    {
        $customer = Customer::find($data['customer_id']);
        $supplyType = $this->resolveSupplyType($data, $customer);

        $lines = [];
        foreach ($data['lines'] as $lineData) {
            $lines[] = $this->computeLine($lineData, $supplyType);
        }

        return $this->gst->aggregateTotals($lines) + ['lines' => $lines];
    }

    // ── Private helpers ──────────────────────────────────────────────────

    private function resolveSupplyType(array $data, ?Customer $customer): string
    {
        if (! empty($data['supply_type'])) {
            return $data['supply_type'];
        }

        if ($data['invoice_type'] === 'export') {
            return 'export';
        }

        // Fetch company settings from DB
        $company = DB::connection('tenant')->table('company_settings')->first();
        $companyGstin = $company->gstin ?? '';
        $companyState = substr(trim($companyGstin), 0, 2);

        // Place of supply from request (usually customer GST state code)
        $pos = $data['place_of_supply'] ?? '';
        $customerGstin = $data['customer_gstin'] ?? ($customer ? $customer->gstin : '');

        // If customer GST is null or absent, it should default to intra-state (CGST and SGST)
        if (empty(trim($customerGstin))) {
            return 'intra';
        }

        // If POS is empty, try to get it from customer GSTIN
        if (empty($pos) && ! empty($customerGstin)) {
            $pos = substr(trim($customerGstin), 0, 2);
        }

        if (empty($companyState) || empty($pos)) {
            return 'intra'; // Default to intra if cannot determine
        }

        return $companyState === $pos ? 'intra' : 'inter';
    }

    private function saveLines(SalesInvoice $invoice, array $linesData, string $supplyType): void
    {
        $rows = [];
        foreach ($linesData as $i => $lineData) {
            $computed = $this->computeLine($lineData, $supplyType);
            $rows[] = array_merge($computed, [
                'sales_invoice_id' => $invoice->id,
                'product_id'       => $lineData['product_id'],
                'description'      => $lineData['description'] ?? null,
                'hsn_sac'          => $lineData['hsn_sac'],
                'unit'             => $lineData['unit'] ?? 'PCS',
                'sort_order'       => $i,
                'custom_columns'   => isset($lineData['custom_columns'])
                    ? json_encode($lineData['custom_columns']) : null,
            ]);
        }

        SalesInvoiceLine::insert($rows);
    }

    private function computeLine(array $lineData, string $supplyType): array
    {
        $qty      = (float) ($lineData['quantity'] ?? 0);
        $rate     = (float) ($lineData['rate'] ?? 0);
        $discPct  = (float) ($lineData['discount_percent'] ?? 0);
        $gstRate  = (float) ($lineData['gst_rate'] ?? 0);
        $cessRate = (float) ($lineData['cess_rate'] ?? 0);

        $subtotal        = round($qty * $rate, 2);
        $discountAmount  = round($subtotal * $discPct / 100, 2);
        $taxableAmount   = round($subtotal - $discountAmount, 2);

        $tax = $this->gst->calcLine($taxableAmount, $gstRate, $supplyType, $cessRate);

        $lineTotal = round($taxableAmount + $tax['total_tax'], 2);

        return [
            'quantity'        => $qty,
            'unit_price'      => $rate,
            'discount_pct'    => $discPct,
            'discount_amount' => $discountAmount,
            'taxable_amount'  => $taxableAmount,
            'gst_rate'        => $gstRate,
            'cgst_rate'       => $tax['cgst_rate'],
            'cgst_amount'     => $tax['cgst_amount'],
            'sgst_rate'       => $tax['sgst_rate'],
            'sgst_amount'     => $tax['sgst_amount'],
            'igst_rate'       => $tax['igst_rate'],
            'igst_amount'     => $tax['igst_amount'],
            'cess_rate'       => $tax['cess_rate'],
            'cess_amount'     => $tax['cess_amount'],
            'line_total'      => $lineTotal,
        ];
    }

    private function recalcTotals(SalesInvoice $invoice): void
    {
        $lines = $invoice->lines;

        $subtotal        = $lines->sum(fn ($l) => $l->quantity * $l->unit_price);
        $discountAmount  = $lines->sum('discount_amount');
        $taxableAmount   = $lines->sum('taxable_amount');
        $cgstAmount      = $lines->sum('cgst_amount');
        $sgstAmount      = $lines->sum('sgst_amount');
        $igstAmount      = $lines->sum('igst_amount');
        $cessAmount      = $lines->sum('cess_amount');
        $grandExact      = $taxableAmount + $cgstAmount + $sgstAmount + $igstAmount + $cessAmount;
        $grandRounded    = round($grandExact);
        $roundOff        = round($grandRounded - $grandExact, 2);

        $invoice->update([
            'subtotal'        => round($subtotal, 2),
            'discount_amount' => round($discountAmount, 2),
            'taxable_amount'  => round($taxableAmount, 2),
            'cgst_amount'     => round($cgstAmount, 2),
            'sgst_amount'     => round($sgstAmount, 2),
            'igst_amount'     => round($igstAmount, 2),
            'cess_amount'     => round($cessAmount, 2),
            'round_off'       => $roundOff,
            'total_amount'    => $grandRounded,
            'balance_amount'  => $grandRounded,
        ]);
    }

    private function postLedgerEntries(SalesInvoice $invoice, int $userId): void
    {
        // Debit: accounts_receivable (asset goes up)
        // Credit: sales (income goes up), then individual tax payable accounts
        $entries = [
            [
                'account_code' => '2001',
                'debit'        => $invoice->total_amount,
                'credit'       => 0,
                'narration'    => "Sales Invoice {$invoice->invoice_number}",
            ],
            [
                'account_code' => '4001',
                'debit'        => 0,
                'credit'       => $invoice->taxable_amount,
                'narration'    => "Sales Invoice {$invoice->invoice_number}",
            ],
        ];

        if ($invoice->cgst_amount > 0) {
            $entries[] = [
                'account_code' => '3001',
                'debit'        => 0,
                'credit'       => $invoice->cgst_amount,
                'narration'    => "CGST on {$invoice->invoice_number}",
            ];
        }

        if ($invoice->sgst_amount > 0) {
            $entries[] = [
                'account_code' => '3002',
                'debit'        => 0,
                'credit'       => $invoice->sgst_amount,
                'narration'    => "SGST on {$invoice->invoice_number}",
            ];
        }

        if ($invoice->igst_amount > 0) {
            $entries[] = [
                'account_code' => '3003',
                'debit'        => 0,
                'credit'       => $invoice->igst_amount,
                'narration'    => "IGST on {$invoice->invoice_number}",
            ];
        }

        if ($invoice->cess_amount > 0) {
            $entries[] = [
                'account_code' => '3006',
                'debit'        => 0,
                'credit'       => $invoice->cess_amount,
                'narration'    => "CESS on {$invoice->invoice_number}",
            ];
        }

        if (abs($invoice->round_off) > 0) {
            // Absorb round-off into a round-off account
            if ($invoice->round_off > 0) {
                $entries[] = [
                    'account_code' => '8001',
                    'debit'        => 0,
                    'credit'       => $invoice->round_off,
                    'narration'    => "Round-off {$invoice->invoice_number}",
                ];
            } else {
                $entries[] = [
                    'account_code' => '8001',
                    'debit'        => abs($invoice->round_off),
                    'credit'       => 0,
                    'narration'    => "Round-off {$invoice->invoice_number}",
                ];
            }
        }

        $this->accounting->post($entries, $invoice->invoice_number, $invoice->invoice_date->toDateString(), $invoice, $userId);
    }

    private function deductStock(SalesInvoice $invoice): void
    {
        foreach ($invoice->lines as $line) {
            DB::connection('tenant')
                ->table('products')
                ->where('id', $line->product_id)
                ->where('track_inventory', true)
                ->decrement('current_stock', $line->quantity);

            DB::connection('tenant')->table('inventory_movements')->insert([
                'product_id'    => $line->product_id,
                'movement_type' => 'sale',
                'quantity'      => -$line->quantity,
                'reference_type' => SalesInvoice::class,
                'reference_id'  => $invoice->id,
                'narration'     => "Sale: {$invoice->invoice_number}",
                'movement_date' => $invoice->invoice_date->toDateString(),
                'created_at'    => now(),
                'updated_at'    => now(),
            ]);
        }
    }
}
