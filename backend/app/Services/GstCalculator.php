<?php

namespace App\Services;

use Illuminate\Support\Facades\DB;

/**
 * GstCalculator — Computes GST breakdowns per line and document total.
 */
class GstCalculator
{
    /**
     * Determine supply type from buyer/seller state codes.
     */
    public function supplyType(string $sellerState, string $buyerState): string
    {
        return strtoupper($sellerState) === strtoupper($buyerState) ? 'intra' : 'inter';
    }

    /**
     * Calculate tax for a single line item.
     *
     * @param  float  $taxableAmount
     * @param  float  $gstRate       e.g. 18.0
     * @param  string $supplyType    'intra' or 'inter'
     * @param  float  $cessRate
     * @return array{cgst_rate: float, cgst_amount: float, sgst_rate: float, sgst_amount: float, igst_rate: float, igst_amount: float, cess_rate: float, cess_amount: float, total_tax: float}
     */
    public function calcLine(
        float $taxableAmount,
        float $gstRate,
        string $supplyType = 'intra',
        float $cessRate = 0.0
    ): array {
        if ($supplyType === 'intra') {
            $halfRate = round($gstRate / 2, 4);
            $cgstAmount = round($taxableAmount * $halfRate / 100, 2);
            $sgstAmount = round($taxableAmount * $halfRate / 100, 2);

            return [
                'cgst_rate'   => $halfRate,
                'cgst_amount' => $cgstAmount,
                'sgst_rate'   => $halfRate,
                'sgst_amount' => $sgstAmount,
                'igst_rate'   => 0.0,
                'igst_amount' => 0.0,
                'cess_rate'   => $cessRate,
                'cess_amount' => round($taxableAmount * $cessRate / 100, 2),
                'total_tax'   => $cgstAmount + $sgstAmount + round($taxableAmount * $cessRate / 100, 2),
            ];
        }

        // Inter-state: IGST only
        $igstAmount = round($taxableAmount * $gstRate / 100, 2);

        return [
            'cgst_rate'   => 0.0,
            'cgst_amount' => 0.0,
            'sgst_rate'   => 0.0,
            'sgst_amount' => 0.0,
            'igst_rate'   => $gstRate,
            'igst_amount' => $igstAmount,
            'cess_rate'   => $cessRate,
            'cess_amount' => round($taxableAmount * $cessRate / 100, 2),
            'total_tax'   => $igstAmount + round($taxableAmount * $cessRate / 100, 2),
        ];
    }

    /**
     * Aggregate GST across all lines.
     *
     * @param  array<array{taxable_amount: float, cgst_amount: float, sgst_amount: float, igst_amount: float, cess_amount: float}> $lines
     */
    public function aggregateTotals(array $lines): array
    {
        $totals = [
            'subtotal'       => 0.0,
            'taxable_amount' => 0.0,
            'cgst_amount'    => 0.0,
            'sgst_amount'    => 0.0,
            'igst_amount'    => 0.0,
            'cess_amount'    => 0.0,
            'tax_total'      => 0.0,
            'grand_total'    => 0.0,
        ];

        foreach ($lines as $line) {
            $totals['taxable_amount'] += $line['taxable_amount'] ?? 0;
            $totals['cgst_amount']    += $line['cgst_amount']    ?? 0;
            $totals['sgst_amount']    += $line['sgst_amount']    ?? 0;
            $totals['igst_amount']    += $line['igst_amount']    ?? 0;
            $totals['cess_amount']    += $line['cess_amount']    ?? 0;
        }

        $totals['tax_total']   = $totals['cgst_amount'] + $totals['sgst_amount']
                                + $totals['igst_amount'] + $totals['cess_amount'];
        $totals['grand_total'] = $totals['taxable_amount'] + $totals['tax_total'];

        // Round off to nearest rupee
        $rounded           = round($totals['grand_total']);
        $totals['round_off'] = $rounded - $totals['grand_total'];
        $totals['grand_total'] = $rounded;

        return array_map(fn ($v) => round((float) $v, 2), $totals);
    }
}
