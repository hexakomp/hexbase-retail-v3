<?php

namespace App\Services;

use App\Models\Quotation;
use App\Models\QuotationLine;
use App\Models\SalesInvoice;
use App\Models\SalesInvoiceLine;
use Illuminate\Support\Facades\DB;

/**
 * QuotationService — CRUD, status transitions, and conversion to sales invoice.
 */
class QuotationService
{
    public function __construct(private SalesInvoiceService $salesInvoiceService) {}

    /**
     * Generate next quotation number: QT-YYYYMMDD-XXXX
     */
    private function nextNumber(): string
    {
        $prefix = 'QT-' . date('Ymd') . '-';
        $last   = Quotation::where('quotation_number', 'like', $prefix . '%')
            ->orderByDesc('quotation_number')
            ->value('quotation_number');

        $seq = $last ? (int) substr($last, -4) + 1 : 1;
        return $prefix . str_pad($seq, 4, '0', STR_PAD_LEFT);
    }

    /**
     * Create a quotation with lines.
     */
    public function create(array $data): Quotation
    {
        return DB::connection('tenant')->transaction(function () use ($data) {
            $lines = $data['lines'] ?? [];
            unset($data['lines']);

            $totals = $this->calculateTotals($lines);

            $quotation = Quotation::create(array_merge($data, [
                'quotation_number' => $data['quotation_number'] ?? $this->nextNumber(),
                'status'           => 'draft',
            ], $totals));

            $this->saveLines($quotation, $lines);

            return $quotation->load('lines', 'customer');
        });
    }

    /**
     * Update a draft/sent quotation.
     */
    public function update(Quotation $quotation, array $data): Quotation
    {
        if (in_array($quotation->status, ['converted', 'rejected'])) {
            abort(422, 'Cannot edit a converted or rejected quotation.');
        }

        return DB::connection('tenant')->transaction(function () use ($quotation, $data) {
            $lines = $data['lines'] ?? null;
            unset($data['lines']);

            if ($lines !== null) {
                $totals = $this->calculateTotals($lines);
                $data   = array_merge($data, $totals);
                $quotation->lines()->delete();
                $this->saveLines($quotation, $lines);
            }

            $quotation->update($data);

            return $quotation->fresh(['lines', 'customer']);
        });
    }

    /**
     * Transition quotation status: draft → sent, sent → accepted/rejected.
     */
    public function post(Quotation $quotation): Quotation
    {
        if ($quotation->status !== 'draft') {
            abort(422, 'Only draft quotations can be sent.');
        }

        $quotation->update(['status' => 'sent']);

        return $quotation->fresh(['lines', 'customer']);
    }

    /**
     * Convert accepted quotation to a sales invoice.
     */
    public function convert(Quotation $quotation): SalesInvoice
    {
        if (!in_array($quotation->status, ['sent', 'accepted'])) {
            abort(422, 'Only sent or accepted quotations can be converted.');
        }

        if ($quotation->isExpired()) {
            abort(422, 'Quotation has expired. Please update validity date before converting.');
        }

        return DB::connection('tenant')->transaction(function () use ($quotation) {
            $quotation->load('lines');

            $invoiceLines = $quotation->lines->map(fn ($line) => [
                'product_id'      => $line->product_id,
                'description'     => $line->description,
                'hsn_sac'         => $line->hsn_sac,
                'quantity'        => $line->quantity,
                'unit'            => $line->unit,
                'unit_price'      => $line->unit_price,
                'discount_percent' => $line->discount_percent,
                'discount_amount' => $line->discount_amount,
                'taxable_amount'  => $line->taxable_amount,
                'gst_rate'        => $line->gst_rate,
                'cgst_rate'       => $line->cgst_rate,
                'sgst_rate'       => $line->sgst_rate,
                'igst_rate'       => $line->igst_rate,
                'cgst_amount'     => $line->cgst_amount,
                'sgst_amount'     => $line->sgst_amount,
                'igst_amount'     => $line->igst_amount,
                'cess_rate'       => $line->cess_rate,
                'cess_amount'     => $line->cess_amount,
                'total_amount'    => $line->total_amount,
                'sort_order'      => $line->sort_order,
            ])->toArray();

            $invoice = $this->salesInvoiceService->draft([
                'customer_id'     => $quotation->customer_id,
                'invoice_date'    => now()->toDateString(),
                'place_of_supply' => $quotation->place_of_supply,
                'narration'       => "Converted from Quotation #{$quotation->quotation_number}",
                'invoice_type'    => 'b2b',
                'lines'           => $invoiceLines,
            ]);

            $quotation->update([
                'status'               => 'converted',
                'converted_invoice_id' => $invoice->id,
            ]);

            return $invoice;
        });
    }

    private function calculateTotals(array $lines): array
    {
        $taxable = $cgst = $sgst = $igst = $cess = $discount = 0.0;

        foreach ($lines as $line) {
            $taxable  += $line['taxable_amount']  ?? 0;
            $cgst     += $line['cgst_amount']     ?? 0;
            $sgst     += $line['sgst_amount']     ?? 0;
            $igst     += $line['igst_amount']     ?? 0;
            $cess     += $line['cess_amount']      ?? 0;
            $discount += $line['discount_amount'] ?? 0;
        }

        return [
            'taxable_amount'  => round($taxable, 2),
            'cgst_amount'     => round($cgst, 2),
            'sgst_amount'     => round($sgst, 2),
            'igst_amount'     => round($igst, 2),
            'cess_amount'     => round($cess, 2),
            'discount_amount' => round($discount, 2),
            'total_amount'    => round($taxable + $cgst + $sgst + $igst + $cess, 2),
        ];
    }

    private function saveLines(Quotation $quotation, array $lines): void
    {
        foreach ($lines as $i => $line) {
            $line['quotation_id'] = $quotation->id;
            $line['sort_order']   = $line['sort_order'] ?? ($i + 1);
            QuotationLine::create($line);
        }
    }
}
