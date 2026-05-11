<?php

namespace App\Services;

use App\Models\CreditNote;
use App\Models\CreditNoteLine;
use Illuminate\Support\Facades\DB;

/**
 * CreditNoteService — business logic for credit notes.
 */
class CreditNoteService
{
    public function __construct(
        protected GstCalculator            $gst,
        protected AccountingEngine         $accounting,
        protected NumberingSequenceService $numbering,
    ) {}

    public function create(array $data, int $userId): CreditNote
    {
        return DB::connection('tenant')->transaction(function () use ($data, $userId) {
            $number = $this->numbering->next('credit_note');

            $note = CreditNote::create([
                'credit_note_number' => $number,
                'credit_note_date'   => $data['credit_note_date'],
                'customer_id'        => $data['customer_id'],
                'sales_invoice_id'   => $data['sales_invoice_id'] ?? null,
                'reason'             => $data['reason'] ?? null,
                'status'             => 'draft',
                'created_by'         => $userId,
                'subtotal'           => 0,
                'cgst_amount'        => 0,
                'sgst_amount'        => 0,
                'igst_amount'        => 0,
                'tax_amount'         => 0,
                'total_amount'       => 0,
            ]);

            $totals = $this->saveLines($note, $data['lines'], $data['supply_type'] ?? 'intra', $data['place_of_supply'] ?? null);
            $note->update($totals);

            return $note->load(['customer', 'lines.product', 'salesInvoice']);
        });
    }

    public function update(CreditNote $note, array $data): CreditNote
    {
        if ($note->status !== 'draft') {
            throw new \RuntimeException('Only draft credit notes can be edited.');
        }

        return DB::connection('tenant')->transaction(function () use ($note, $data) {
            $note->lines()->delete();
            $note->update([
                'credit_note_date' => $data['credit_note_date'] ?? $note->credit_note_date,
                'reason'           => $data['reason'] ?? $note->reason,
            ]);

            $totals = $this->saveLines(
                $note,
                $data['lines'],
                $data['supply_type'] ?? 'intra',
                $data['place_of_supply'] ?? null
            );
            $note->update($totals);

            return $note->fresh(['customer', 'lines.product']);
        });
    }

    public function post(CreditNote $note, int $userId): CreditNote
    {
        if ($note->status !== 'draft') {
            throw new \RuntimeException('Credit note is already posted or cancelled.');
        }

        return DB::connection('tenant')->transaction(function () use ($note, $userId) {
            $note->update(['status' => 'confirmed']);

            // Double-entry: debit sales account, credit receivable (reduction)
            $entries = [
                ['account_code' => 'SALES',      'debit' => $note->subtotal,   'credit' => 0,              'narration' => "CN {$note->credit_note_number}"],
                ['account_code' => 'CGST_PAYABLE','debit' => $note->cgst_amount,'credit' => 0,             'narration' => "CN {$note->credit_note_number}"],
                ['account_code' => 'SGST_PAYABLE','debit' => $note->sgst_amount,'credit' => 0,             'narration' => "CN {$note->credit_note_number}"],
                ['account_code' => 'IGST_PAYABLE','debit' => $note->igst_amount,'credit' => 0,             'narration' => "CN {$note->credit_note_number}"],
                ['account_code' => 'RECEIVABLE',  'debit' => 0,                 'credit' => $note->total_amount, 'narration' => "CN {$note->credit_note_number}"],
            ];
            $this->accounting->post(
                array_filter($entries, fn ($e) => ($e['debit'] + $e['credit']) > 0),
                $note->credit_note_number,
                $note->credit_note_date->format('Y-m-d'),
                $note,
                $userId
            );

            return $note->fresh();
        });
    }

    public function cancel(CreditNote $note, int $userId): CreditNote
    {
        if ($note->status === 'adjusted') {
            throw new \RuntimeException('Adjusted credit notes cannot be cancelled.');
        }

        return DB::connection('tenant')->transaction(function () use ($note, $userId) {
            if ($note->status === 'confirmed') {
                $this->accounting->reverse(
                    $note,
                    now()->toDateString(),
                    'REV-' . $note->credit_note_number,
                    $userId
                );
            }
            $note->update(['status' => 'draft']);
            return $note->fresh();
        });
    }

    // ── Private ──────────────────────────────────────────────────────────────

    private function saveLines(CreditNote $note, array $lines, string $supplyType, ?string $placeOfSupply): array
    {
        $subtotal    = 0;
        $cgstTotal   = 0;
        $sgstTotal   = 0;
        $igstTotal   = 0;

        foreach ($lines as $i => $line) {
            $taxable      = round($line['quantity'] * $line['unit_price'] * (1 - ($line['discount_pct'] ?? 0) / 100), 2);
            $gstRate      = (int) ($line['gst_rate'] ?? 0);
            $isIntra      = strtolower($supplyType) === 'intra';
            $cgstRate     = $isIntra ? $gstRate / 2 : 0;
            $sgstRate     = $isIntra ? $gstRate / 2 : 0;
            $igstRate     = $isIntra ? 0 : $gstRate;
            $cgstAmt      = round($taxable * $cgstRate / 100, 2);
            $sgstAmt      = round($taxable * $sgstRate / 100, 2);
            $igstAmt      = round($taxable * $igstRate / 100, 2);
            $taxAmt       = $cgstAmt + $sgstAmt + $igstAmt;
            $lineTotal    = $taxable + $taxAmt;
            $discAmt      = round($line['quantity'] * $line['unit_price'] * ($line['discount_pct'] ?? 0) / 100, 2);

            CreditNoteLine::create([
                'credit_note_id'  => $note->id,
                'product_id'      => $line['product_id'],
                'description'     => $line['description'] ?? null,
                'hsn_sac'         => $line['hsn_sac'] ?? null,
                'quantity'        => $line['quantity'],
                'unit'            => $line['unit'] ?? 'PCS',
                'unit_price'      => $line['unit_price'],
                'discount_pct'    => $line['discount_pct'] ?? 0,
                'discount_amount' => $discAmt,
                'taxable_amount'  => $taxable,
                'gst_rate'        => $gstRate,
                'cgst_rate'       => $cgstRate,
                'cgst_amount'     => $cgstAmt,
                'sgst_rate'       => $sgstRate,
                'sgst_amount'     => $sgstAmt,
                'igst_rate'       => $igstRate,
                'igst_amount'     => $igstAmt,
                'tax_amount'      => $taxAmt,
                'line_total'      => $lineTotal,
                'sort_order'      => $i,
            ]);

            $subtotal  += $taxable;
            $cgstTotal += $cgstAmt;
            $sgstTotal += $sgstAmt;
            $igstTotal += $igstAmt;
        }

        $taxTotal = $cgstTotal + $sgstTotal + $igstTotal;

        return [
            'subtotal'    => $subtotal,
            'cgst_amount' => $cgstTotal,
            'sgst_amount' => $sgstTotal,
            'igst_amount' => $igstTotal,
            'tax_amount'  => $taxTotal,
            'total_amount'=> $subtotal + $taxTotal,
        ];
    }
}
