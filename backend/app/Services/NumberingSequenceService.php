<?php

namespace App\Services;

use Illuminate\Support\Facades\DB;

/**
 * NumberingSequenceService — Thread-safe auto-numbering for documents.
 */
class NumberingSequenceService
{
    /**
     * Generate the next number for a document type.
     * Uses a DB transaction to prevent race conditions.
     *
     * @param  string $type  e.g. 'sales_invoice', 'quotation'
     * @return string        e.g. 'INV-0042'
     */
    public function next(string $type): string
    {
        return DB::connection('tenant')->transaction(function () use ($type) {
            $seq = DB::connection('tenant')
                ->table('numbering_sequences')
                ->where('type', $type)
                ->lockForUpdate()
                ->first();

            if (! $seq) {
                // Bootstrap with sensible defaults
                $defaults = $this->defaults($type);
                DB::connection('tenant')->table('numbering_sequences')->insert(array_merge(
                    $defaults,
                    ['type' => $type, 'next_number' => 1, 'created_at' => now(), 'updated_at' => now()]
                ));
                $seq = (object) array_merge($defaults, ['next_number' => 1]);
            }

            $number = (int) $seq->next_number;
            $padded = str_pad((string) $number, (int) ($seq->pad_length ?? 4), '0', STR_PAD_LEFT);
            $formatted = ($seq->prefix ?? '') . $padded . ($seq->suffix ?? '');

            DB::connection('tenant')
                ->table('numbering_sequences')
                ->where('type', $type)
                ->update(['next_number' => $number + 1, 'updated_at' => now()]);

            return $formatted;
        });
    }

    /**
     * Preview the next number without consuming it.
     */
    public function preview(string $type): string
    {
        $seq = DB::connection('tenant')
            ->table('numbering_sequences')
            ->where('type', $type)
            ->first();

        if (! $seq) {
            $defaults = $this->defaults($type);
            $seq = (object) array_merge($defaults, ['next_number' => 1]);
        }

        $padded = str_pad((string) $seq->next_number, (int) ($seq->pad_length ?? 4), '0', STR_PAD_LEFT);

        return ($seq->prefix ?? '') . $padded . ($seq->suffix ?? '');
    }

    private function defaults(string $type): array
    {
        $prefixMap = [
            'sales_invoice'    => 'INV-',
            'purchase_invoice' => 'PINV-',
            'quotation'        => 'QT-',
            'delivery_challan' => 'DC-',
            'credit_note'      => 'CN-',
            'debit_note'       => 'DN-',
            'receipt'          => 'RCP-',
            'payment'          => 'PAY-',
            'expense'          => 'EXP-',
            'purchase_order'   => 'PO-',
        ];

        return [
            'prefix'     => $prefixMap[$type] ?? strtoupper($type[0]) . '-',
            'suffix'     => '',
            'pad_length' => 4,
        ];
    }
}
