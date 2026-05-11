<?php

namespace App\Services;

use App\Models\DebitNote;
use App\Models\DebitNoteLine;
use Illuminate\Support\Facades\DB;

/**
 * DebitNoteService — business logic for debit notes.
 */
class DebitNoteService
{
    public function __construct(
        protected AccountingEngine         $accounting,
        protected NumberingSequenceService $numbering,
    ) {}

    public function create(array $data, int $userId): DebitNote
    {
        return DB::connection('tenant')->transaction(function () use ($data, $userId) {
            $number = $this->numbering->next('debit_note');

            $note = DebitNote::create([
                'debit_note_number'   => $number,
                'debit_note_date'     => $data['debit_note_date'],
                'vendor_id'           => $data['vendor_id'],
                'purchase_invoice_id' => $data['purchase_invoice_id'] ?? null,
                'reason'              => $data['reason'] ?? null,
                'status'              => 'draft',
                'created_by'          => $userId,
                'subtotal'            => 0,
                'cgst_amount'         => 0,
                'sgst_amount'         => 0,
                'igst_amount'         => 0,
                'tax_amount'          => 0,
                'total_amount'        => 0,
            ]);

            $totals = $this->saveLines($note, $data['lines'], $data['supply_type'] ?? 'intra');
            $note->update($totals);

            return $note->load(['vendor', 'lines.product', 'purchaseInvoice']);
        });
    }

    public function update(DebitNote $note, array $data): DebitNote
    {
        if ($note->status !== 'draft') {
            throw new \RuntimeException('Only draft debit notes can be edited.');
        }

        return DB::connection('tenant')->transaction(function () use ($note, $data) {
            $note->lines()->delete();
            $note->update([
                'debit_note_date' => $data['debit_note_date'] ?? $note->debit_note_date,
                'reason'          => $data['reason'] ?? $note->reason,
            ]);

            $totals = $this->saveLines($note, $data['lines'], $data['supply_type'] ?? 'intra');
            $note->update($totals);

            return $note->fresh(['vendor', 'lines.product']);
        });
    }

    public function post(DebitNote $note, int $userId): DebitNote
    {
        if ($note->status !== 'draft') {
            throw new \RuntimeException('Debit note already posted or cancelled.');
        }

        return DB::connection('tenant')->transaction(function () use ($note, $userId) {
            $note->update(['status' => 'confirmed']);

            // Double-entry: debit payable (reduction), credit purchase return
            $entries = [
                ['account_code' => 'PAYABLE',     'debit' => $note->total_amount, 'credit' => 0,               'narration' => "DN {$note->debit_note_number}"],
                ['account_code' => 'PURCHASE',     'debit' => 0,                  'credit' => $note->subtotal,  'narration' => "DN {$note->debit_note_number}"],
                ['account_code' => 'CGST_PAYABLE', 'debit' => 0,                  'credit' => $note->cgst_amount,'narration' => "DN {$note->debit_note_number}"],
                ['account_code' => 'SGST_PAYABLE', 'debit' => 0,                  'credit' => $note->sgst_amount,'narration' => "DN {$note->debit_note_number}"],
                ['account_code' => 'IGST_PAYABLE', 'debit' => 0,                  'credit' => $note->igst_amount,'narration' => "DN {$note->debit_note_number}"],
            ];
            $this->accounting->post(
                array_filter($entries, fn ($e) => ($e['debit'] + $e['credit']) > 0),
                $note->debit_note_number,
                $note->debit_note_date->format('Y-m-d'),
                $note,
                $userId
            );

            return $note->fresh();
        });
    }

    public function cancel(DebitNote $note, int $userId): DebitNote
    {
        if ($note->status === 'adjusted') {
            throw new \RuntimeException('Adjusted debit notes cannot be cancelled.');
        }

        return DB::connection('tenant')->transaction(function () use ($note, $userId) {
            if ($note->status === 'confirmed') {
                $this->accounting->reverse(
                    $note,
                    now()->toDateString(),
                    'REV-' . $note->debit_note_number,
                    $userId
                );
            }
            $note->update(['status' => 'draft']);
            return $note->fresh();
        });
    }

    // ── Private ──────────────────────────────────────────────────────────────

    private function saveLines(DebitNote $note, array $lines, string $supplyType): array
    {
        $subtotal  = 0;
        $cgstTotal = 0;
        $sgstTotal = 0;
        $igstTotal = 0;

        foreach ($lines as $i => $line) {
            $taxable   = round($line['quantity'] * $line['unit_price'] * (1 - ($line['discount_pct'] ?? 0) / 100), 2);
            $gstRate   = (int) ($line['gst_rate'] ?? 0);
            $isIntra   = strtolower($supplyType) === 'intra';
            $cgstRate  = $isIntra ? $gstRate / 2 : 0;
            $sgstRate  = $isIntra ? $gstRate / 2 : 0;
            $igstRate  = $isIntra ? 0 : $gstRate;
            $cgstAmt   = round($taxable * $cgstRate / 100, 2);
            $sgstAmt   = round($taxable * $sgstRate / 100, 2);
            $igstAmt   = round($taxable * $igstRate / 100, 2);
            $taxAmt    = $cgstAmt + $sgstAmt + $igstAmt;
            $discAmt   = round($line['quantity'] * $line['unit_price'] * ($line['discount_pct'] ?? 0) / 100, 2);

            DebitNoteLine::create([
                'debit_note_id'   => $note->id,
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
                'line_total'      => $taxable + $taxAmt,
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
