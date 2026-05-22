<?php

namespace App\Services;

use App\Models\PurchaseInvoice;
use App\Models\PurchaseInvoiceLine;
use App\Models\Vendor;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;

/**
 * PurchaseInvoiceService — Business logic for vendor purchase invoicing.
 *
 * Responsibilities:
 *  - Draft creation and update
 *  - Line GST computation via GstCalculator
 *  - Header aggregation
 *  - Post: status → confirmed, double-entry via AccountingEngine,
 *           stock increment (WAC), ITC registration, PO status update
 *  - Cancel: soft-cancel + ledger reversal
 *  - Attachment path storage
 */
class PurchaseInvoiceService
{
    public function __construct(
        protected GstCalculator            $gst,
        protected AccountingEngine         $accounting,
        protected NumberingSequenceService $numbering,
    ) {}

    // ── Public API ──────────────────────────────────────────────────────────

    public function createFromRequest(array $data, int $userId): PurchaseInvoice
    {
        return DB::connection('tenant')->transaction(function () use ($data, $userId) {
            $vendor = Vendor::findOrFail($data['vendor_id']);
            $supplyType = $this->resolveSupplyType($data);

            $invoiceNumber = $this->numbering->next('purchase_invoice');

            $invoice = PurchaseInvoice::create([
                'invoice_number'       => $invoiceNumber,
                'vendor_invoice_number' => $data['vendor_invoice_number'] ?? null,
                'vendor_invoice_date'  => $data['vendor_invoice_date'] ?? null,
                'entry_date'           => $data['entry_date'] ?? now()->toDateString(),
                'invoice_date'         => $data['entry_date'] ?? now()->toDateString(),
                'due_date'             => $data['due_date'] ?? null,
                'vendor_id'            => $data['vendor_id'],
                'vendor_gstin'         => $vendor->gstin ?? null,
                'supply_type'          => $supplyType,
                'reverse_charge'       => $data['reverse_charge'] ?? false,
                'purchase_order_id'    => $data['purchase_order_id'] ?? null,
                'narration'            => $data['narration'] ?? null,
                'notes'                => $data['notes'] ?? null,
                'custom_fields'        => $data['custom_fields'] ?? null,
                'status'               => 'draft',
                'created_by'           => $userId,
                'subtotal'             => 0,
                'discount_amount'      => 0,
                'taxable_amount'       => 0,
                'cgst_amount'          => 0,
                'sgst_amount'          => 0,
                'igst_amount'          => 0,
                'cess_amount'          => 0,
                'round_off'            => 0,
                'total_amount'         => 0,
                'paid_amount'          => 0,
                'balance_amount'       => 0,
            ]);

            $this->saveLines($invoice, $data['lines'], $supplyType);
            $this->recalcTotals($invoice);

            if (($data['status'] ?? 'draft') === 'posted') {
                $this->post($invoice, $userId);
            }

            return $invoice->fresh(['lines', 'vendor']);
        });
    }

    public function updateFromRequest(PurchaseInvoice $invoice, array $data, int $userId): PurchaseInvoice
    {
        if ($invoice->status !== 'draft') {
            throw new \RuntimeException('Only draft purchase invoices can be edited.');
        }

        return DB::connection('tenant')->transaction(function () use ($invoice, $data, $userId) {
            $vendor = Vendor::findOrFail($data['vendor_id']);
            $supplyType = $this->resolveSupplyType($data);

            $invoice->update([
                'vendor_invoice_number' => $data['vendor_invoice_number'] ?? null,
                'vendor_invoice_date'   => $data['vendor_invoice_date'] ?? null,
                'entry_date'            => $data['entry_date'] ?? $invoice->entry_date,
                'invoice_date'          => $data['entry_date'] ?? $invoice->invoice_date,
                'due_date'              => $data['due_date'] ?? null,
                'vendor_id'             => $data['vendor_id'],
                'vendor_gstin'          => $vendor->gstin ?? null,
                'supply_type'           => $supplyType,
                'reverse_charge'        => $data['reverse_charge'] ?? false,
                'purchase_order_id'     => $data['purchase_order_id'] ?? null,
                'narration'             => $data['narration'] ?? null,
                'notes'                 => $data['notes'] ?? null,
                'custom_fields'         => $data['custom_fields'] ?? null,
            ]);

            $invoice->lines()->delete();
            $this->saveLines($invoice, $data['lines'], $supplyType);
            $this->recalcTotals($invoice);

            return $invoice->fresh(['lines', 'vendor']);
        });
    }

    public function post(PurchaseInvoice $invoice, int $userId): PurchaseInvoice
    {
        if ($invoice->status !== 'draft') {
            throw new \RuntimeException('Only draft purchase invoices can be posted.');
        }

        DB::connection('tenant')->transaction(function () use ($invoice, $userId) {
            $invoice->update(['status' => 'confirmed']);
            $this->postLedgerEntries($invoice, $userId);
            $this->incrementStock($invoice);
            $this->updatePurchaseOrderStatus($invoice);
        });

        return $invoice->fresh();
    }

    public function cancel(PurchaseInvoice $invoice, string $reason, int $userId): PurchaseInvoice
    {
        if ($invoice->status === 'cancelled') {
            throw new \RuntimeException('Purchase invoice is already cancelled.');
        }

        // Check for payment allocations
        $allocationCount = DB::connection('tenant')
            ->table('payment_allocations')
            ->where('purchase_invoice_id', $invoice->id)
            ->count();

        if ($allocationCount > 0) {
            throw new \RuntimeException('Cannot cancel: payment allocations exist against this invoice.', 409);
        }

        DB::connection('tenant')->transaction(function () use ($invoice, $reason, $userId) {
            $invoice->update([
                'status'    => 'cancelled',
                'narration' => trim(($invoice->narration ?? '') . "\nCancelled: {$reason}"),
            ]);

            if (in_array($invoice->status, ['confirmed', 'partially_paid', 'paid'])) {
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

    public function storeAttachment(PurchaseInvoice $invoice, string $path): PurchaseInvoice
    {
        $invoice->update(['attachment_path' => $path]);

        return $invoice->fresh();
    }

    // ── Private helpers ──────────────────────────────────────────────────

    private function resolveSupplyType(array $data): string
    {
        if (! empty($data['supply_type'])) {
            return $data['supply_type'];
        }

        $settingsJson = Storage::disk('local')->get('company/settings.json');
        $settings     = $settingsJson ? (json_decode($settingsJson, true) ?? []) : [];
        $companyState = $settings['state_code'] ?? '';

        $vendorState = '';
        if (! empty($data['vendor_id'])) {
            $vendor = Vendor::find($data['vendor_id']);
            $vendorState = $vendor?->state_code ?? '';
        }

        if (empty($vendorState) || empty($companyState)) {
            return 'intra';
        }

        return strtoupper($companyState) === strtoupper($vendorState) ? 'intra' : 'inter';
    }

    private function saveLines(PurchaseInvoice $invoice, array $linesData, string $supplyType): void
    {
        $rows = [];
        foreach ($linesData as $i => $lineData) {
            $computed = $this->computeLine($lineData, $supplyType);
            $rows[] = array_merge($computed, [
                'purchase_invoice_id' => $invoice->id,
                'product_id'          => $lineData['product_id'],
                'description'         => $lineData['description'] ?? null,
                'hsn_sac'             => $lineData['hsn_sac'],
                'unit'                => $lineData['unit'] ?? $lineData['uom'] ?? 'PCS',
                'itc_eligible'        => (bool) ($lineData['itc_eligible'] ?? false),
                'sort_order'          => $i,
                'custom_columns'      => isset($lineData['custom_columns'])
                    ? json_encode($lineData['custom_columns']) : null,
            ]);
        }

        PurchaseInvoiceLine::insert($rows);
    }

    private function computeLine(array $lineData, string $supplyType): array
    {
        $qty      = (float) ($lineData['quantity'] ?? 0);
        $rate     = (float) ($lineData['rate'] ?? $lineData['unit_price'] ?? 0);
        $discPct  = (float) ($lineData['discount_percent'] ?? $lineData['discount_pct'] ?? 0);
        $gstRate  = (float) ($lineData['gst_rate'] ?? 0);
        $cessRate = (float) ($lineData['cess_rate'] ?? 0);

        $subtotal       = round($qty * $rate, 2);
        $discountAmount = round($subtotal * $discPct / 100, 2);
        $taxableAmount  = round($subtotal - $discountAmount, 2);

        $tax       = $this->gst->calcLine($taxableAmount, $gstRate, $supplyType, $cessRate);
        $lineTotal = round($taxableAmount + $tax['total_tax'], 2);

        return [
            'quantity'        => $qty,
            'unit_price'      => $rate,
            'discount_pct'    => $discPct,
            'discount_amount' => $discountAmount,
            'taxable_amount'  => $taxableAmount,
            'gst_rate'        => (int) $gstRate,
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

    private function recalcTotals(PurchaseInvoice $invoice): void
    {
        $lines = $invoice->lines;

        $subtotal       = $lines->sum(fn ($l) => $l->quantity * $l->unit_price);
        $discountAmount = $lines->sum('discount_amount');
        $taxableAmount  = $lines->sum('taxable_amount');
        $cgstAmount     = $lines->sum('cgst_amount');
        $sgstAmount     = $lines->sum('sgst_amount');
        $igstAmount     = $lines->sum('igst_amount');
        $cessAmount     = $lines->sum('cess_amount');
        $grandExact     = $taxableAmount + $cgstAmount + $sgstAmount + $igstAmount + $cessAmount;
        $grandRounded   = round($grandExact);
        $roundOff       = round($grandRounded - $grandExact, 2);

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

    private function postLedgerEntries(PurchaseInvoice $invoice, int $userId): void
    {
        // Debit: purchase/expense account (cost goes up)
        // Debit: ITC receivable for eligible GST
        // Credit: accounts_payable (liability goes up)

        $eligibleLines     = $invoice->lines->where('itc_eligible', true);
        $itcCgst           = $eligibleLines->sum('cgst_amount');
        $itcSgst           = $eligibleLines->sum('sgst_amount');
        $itcIgst           = $eligibleLines->sum('igst_amount');
        $nonItcTax         = ($invoice->cgst_amount - $itcCgst)
                           + ($invoice->sgst_amount - $itcSgst)
                           + ($invoice->igst_amount - $itcIgst)
                           + $invoice->cess_amount;

        // Purchase cost = taxable + non-eligible tax
        $purchaseCost = round($invoice->taxable_amount + $nonItcTax, 2);

        $entries = [
            [
                'account_code' => 'PURCHASE',
                'debit'        => $purchaseCost,
                'credit'       => 0,
                'narration'    => "Purchase Invoice {$invoice->invoice_number}",
            ],
            [
                'account_code' => 'PAYABLE',
                'debit'        => 0,
                'credit'       => $invoice->total_amount,
                'narration'    => "Purchase Invoice {$invoice->invoice_number}",
            ],
        ];

        if ($itcCgst > 0) {
            $entries[] = [
                'account_code' => 'ITC-CGST',
                'debit'        => $itcCgst,
                'credit'       => 0,
                'narration'    => "ITC CGST on {$invoice->invoice_number}",
            ];
        }

        if ($itcSgst > 0) {
            $entries[] = [
                'account_code' => 'ITC-SGST',
                'debit'        => $itcSgst,
                'credit'       => 0,
                'narration'    => "ITC SGST on {$invoice->invoice_number}",
            ];
        }

        if ($itcIgst > 0) {
            $entries[] = [
                'account_code' => 'ITC-IGST',
                'debit'        => $itcIgst,
                'credit'       => 0,
                'narration'    => "ITC IGST on {$invoice->invoice_number}",
            ];
        }

        if (abs($invoice->round_off) > 0) {
            if ($invoice->round_off > 0) {
                $entries[] = [
                    'account_code' => 'ROUND-OFF',
                    'debit'        => 0,
                    'credit'       => $invoice->round_off,
                    'narration'    => "Round-off {$invoice->invoice_number}",
                ];
            } else {
                $entries[] = [
                    'account_code' => 'ROUND-OFF',
                    'debit'        => abs($invoice->round_off),
                    'credit'       => 0,
                    'narration'    => "Round-off {$invoice->invoice_number}",
                ];
            }
        }

        $this->accounting->post(
            $entries,
            $invoice->invoice_number,
            ($invoice->invoice_date ?? now())->toDateString(),
            $invoice,
            $userId
        );
    }

    private function incrementStock(PurchaseInvoice $invoice): void
    {
        foreach ($invoice->lines as $line) {
            $product = DB::connection('tenant')
                ->table('products')
                ->where('id', $line->product_id)
                ->where('track_inventory', true)
                ->first();

            if (! $product) {
                continue;
            }

            $currentStock = (float) $product->current_stock;
            $avgCost      = (float) $product->avg_cost;
            $newQty       = $currentStock + $line->quantity;
            $newAvgCost   = $newQty > 0
                ? round(($currentStock * $avgCost + $line->quantity * $line->unit_price) / $newQty, 4)
                : $line->unit_price;

            DB::connection('tenant')
                ->table('products')
                ->where('id', $line->product_id)
                ->update([
                    'current_stock' => $newQty,
                    'avg_cost'      => $newAvgCost,
                ]);

            DB::connection('tenant')->table('inventory_movements')->insert([
                'product_id'     => $line->product_id,
                'movement_type'  => 'purchase',
                'quantity'       => $line->quantity,
                'reference_type' => PurchaseInvoice::class,
                'reference_id'   => $invoice->id,
                'narration'      => "Purchase: {$invoice->invoice_number}",
                'movement_date'  => ($invoice->invoice_date ?? now())->toDateString(),
                'created_at'     => now(),
                'updated_at'     => now(),
            ]);
        }
    }

    private function updatePurchaseOrderStatus(PurchaseInvoice $invoice): void
    {
        if (! $invoice->purchase_order_id) {
            return;
        }

        DB::connection('tenant')
            ->table('purchase_orders')
            ->where('id', $invoice->purchase_order_id)
            ->update([
                'status'                    => 'received',
                'converted_to_invoice_id'   => $invoice->id,
            ]);
    }
}
