<?php

namespace App\Services;

use Illuminate\Support\Facades\DB;

/**
 * GstReportService — Generates all GST compliance reports.
 *
 * Covers: GSTR-1 (B2B, B2C, document summary, tax liability, HSN summary, amendments),
 *         GSTR-3B support, ITC register, sales tax register, purchase tax register.
 */
class GstReportService
{
    // ── GSTR-1: B2B Section ─────────────────────────────────────────────────

    public function gstr1B2b(string $fromDate, string $toDate): array
    {
        $rows = DB::connection('tenant')
            ->table('sales_invoices as si')
            ->join('customers as c', 'c.id', '=', 'si.customer_id')
            ->whereIn('si.status', ['confirmed', 'partially_paid', 'paid'])
            ->where('si.invoice_type', 'b2b')
            ->whereBetween('si.invoice_date', [$fromDate, $toDate])
            ->whereNull('si.deleted_at')
            ->select([
                'c.gstin',
                'c.name as customer_name',
                'si.invoice_number',
                'si.invoice_date',
                'si.invoice_type',
                'si.place_of_supply',
                'si.taxable_amount as taxable_value',
                'si.cgst_amount as cgst',
                'si.sgst_amount as sgst',
                'si.igst_amount as igst',
                'si.cess_amount as cess',
                'si.total_amount',
            ])
            ->orderBy('si.invoice_date')
            ->get();

        $totalTaxable = $rows->sum('taxable_value');
        $totalTax     = $rows->sum(fn ($r) => $r->cgst + $r->sgst + $r->igst + $r->cess);

        return [
            'period'  => "{$fromDate} to {$toDate}",
            'summary' => [
                'total_invoices' => $rows->count(),
                'total_taxable'  => number_format($totalTaxable, 2, '.', ''),
                'total_tax'      => number_format($totalTax, 2, '.', ''),
            ],
            'records' => $rows->map(fn ($r) => [
                'gstin'          => $r->gstin,
                'customer_name'  => $r->customer_name,
                'invoice_number' => $r->invoice_number,
                'invoice_date'   => $r->invoice_date,
                'invoice_type'   => $r->invoice_type,
                'place_of_supply' => $r->place_of_supply,
                'taxable_value'  => number_format($r->taxable_value, 2, '.', ''),
                'cgst'           => number_format($r->cgst, 2, '.', ''),
                'sgst'           => number_format($r->sgst, 2, '.', ''),
                'igst'           => number_format($r->igst, 2, '.', ''),
                'cess'           => number_format($r->cess, 2, '.', ''),
            ])->values()->toArray(),
        ];
    }

    // ── GSTR-1: B2C Aggregate ───────────────────────────────────────────────

    public function gstr1B2c(string $fromDate, string $toDate): array
    {
        $rows = DB::connection('tenant')
            ->table('sales_invoices as si')
            ->whereIn('si.status', ['confirmed', 'partially_paid', 'paid'])
            ->where('si.invoice_type', 'b2c')
            ->whereBetween('si.invoice_date', [$fromDate, $toDate])
            ->whereNull('si.deleted_at')
            ->select([
                'si.place_of_supply',
                DB::raw('SUM(si.taxable_amount) as taxable_value'),
                DB::raw('SUM(si.cgst_amount) as cgst'),
                DB::raw('SUM(si.sgst_amount) as sgst'),
                DB::raw('SUM(si.igst_amount) as igst'),
                DB::raw('SUM(si.cess_amount) as cess'),
                DB::raw('COUNT(*) as invoice_count'),
            ])
            ->groupBy('si.place_of_supply')
            ->orderBy('si.place_of_supply')
            ->get();

        return [
            'period'  => "{$fromDate} to {$toDate}",
            'summary' => [
                'total_invoices' => $rows->sum('invoice_count'),
                'total_taxable'  => number_format($rows->sum('taxable_value'), 2, '.', ''),
                'total_tax'      => number_format($rows->sum(fn ($r) => $r->cgst + $r->sgst + $r->igst + $r->cess), 2, '.', ''),
            ],
            'records' => $rows->map(fn ($r) => [
                'place_of_supply' => $r->place_of_supply,
                'invoice_count'   => $r->invoice_count,
                'taxable_value'   => number_format($r->taxable_value, 2, '.', ''),
                'cgst'            => number_format($r->cgst, 2, '.', ''),
                'sgst'            => number_format($r->sgst, 2, '.', ''),
                'igst'            => number_format($r->igst, 2, '.', ''),
                'cess'            => number_format($r->cess, 2, '.', ''),
            ])->values()->toArray(),
        ];
    }

    // ── GSTR-1: HSN Summary ─────────────────────────────────────────────────

    public function gstr1HsnSummary(string $fromDate, string $toDate): array
    {
        $rows = DB::connection('tenant')
            ->table('sales_invoice_lines as sil')
            ->join('sales_invoices as si', 'si.id', '=', 'sil.sales_invoice_id')
            ->whereIn('si.status', ['confirmed', 'partially_paid', 'paid'])
            ->whereBetween('si.invoice_date', [$fromDate, $toDate])
            ->whereNull('si.deleted_at')
            ->whereNotNull('sil.hsn_sac')
            ->select([
                'sil.hsn_sac',
                'sil.unit',
                DB::raw('SUM(sil.quantity) as total_quantity'),
                DB::raw('SUM(sil.taxable_amount) as taxable_value'),
                DB::raw('SUM(sil.cgst_amount) as cgst'),
                DB::raw('SUM(sil.sgst_amount) as sgst'),
                DB::raw('SUM(sil.igst_amount) as igst'),
                DB::raw('SUM(sil.cess_amount) as cess'),
            ])
            ->groupBy('sil.hsn_sac', 'sil.unit')
            ->orderBy('sil.hsn_sac')
            ->get();

        return [
            'period'  => "{$fromDate} to {$toDate}",
            'records' => $rows->map(fn ($r) => [
                'hsn_sac'       => $r->hsn_sac,
                'uom'           => $r->unit,
                'total_quantity' => (float) $r->total_quantity,
                'taxable_value' => number_format($r->taxable_value, 2, '.', ''),
                'cgst'          => number_format($r->cgst, 2, '.', ''),
                'sgst'          => number_format($r->sgst, 2, '.', ''),
                'igst'          => number_format($r->igst, 2, '.', ''),
                'cess'          => number_format($r->cess, 2, '.', ''),
            ])->values()->toArray(),
        ];
    }

    // ── GSTR-1: Document Summary ────────────────────────────────────────────

    public function gstr1DocumentSummary(string $fromDate, string $toDate): array
    {
        $tables = [
            ['table' => 'sales_invoices', 'type' => 'Invoice', 'status_col' => 'status'],
            ['table' => 'credit_notes',   'type' => 'Credit Note', 'status_col' => 'status'],
            ['table' => 'debit_notes',    'type' => 'Debit Note', 'status_col' => 'status'],
        ];

        $results = [];

        foreach ($tables as $cfg) {
            if (!$this->tableExists($cfg['table'])) {
                continue;
            }

            $row = DB::connection('tenant')
                ->table($cfg['table'])
                ->whereBetween('invoice_date', [$fromDate, $toDate])
                ->whereNotIn($cfg['status_col'], ['draft', 'cancelled'])
                ->whereNull('deleted_at')
                ->selectRaw('COUNT(*) as count, SUM(taxable_amount) as taxable_value, SUM(cgst_amount + sgst_amount + igst_amount) as tax_amount')
                ->first();

            $results[] = [
                'document_type' => $cfg['type'],
                'count'         => (int) ($row->count ?? 0),
                'taxable_value' => number_format($row->taxable_value ?? 0, 2, '.', ''),
                'tax_amount'    => number_format($row->tax_amount ?? 0, 2, '.', ''),
            ];
        }

        return ['period' => "{$fromDate} to {$toDate}", 'records' => $results];
    }

    // ── GSTR-1: Tax Liability Summary ───────────────────────────────────────

    public function gstr1TaxLiability(string $fromDate, string $toDate): array
    {
        $rows = DB::connection('tenant')
            ->table('sales_invoice_lines as sil')
            ->join('sales_invoices as si', 'si.id', '=', 'sil.sales_invoice_id')
            ->whereIn('si.status', ['confirmed', 'partially_paid', 'paid'])
            ->whereBetween('si.invoice_date', [$fromDate, $toDate])
            ->whereNull('si.deleted_at')
            ->select([
                'sil.gst_rate',
                DB::raw('SUM(sil.taxable_amount) as taxable_value'),
                DB::raw('SUM(sil.cgst_amount) as cgst'),
                DB::raw('SUM(sil.sgst_amount) as sgst'),
                DB::raw('SUM(sil.igst_amount) as igst'),
                DB::raw('SUM(sil.cess_amount) as cess'),
            ])
            ->groupBy('sil.gst_rate')
            ->orderBy('sil.gst_rate')
            ->get();

        return [
            'period'  => "{$fromDate} to {$toDate}",
            'records' => $rows->map(fn ($r) => [
                'gst_rate'      => (int) $r->gst_rate,
                'taxable_value' => number_format($r->taxable_value, 2, '.', ''),
                'cgst'          => number_format($r->cgst, 2, '.', ''),
                'sgst'          => number_format($r->sgst, 2, '.', ''),
                'igst'          => number_format($r->igst, 2, '.', ''),
                'cess'          => number_format($r->cess, 2, '.', ''),
                'total_tax'     => number_format($r->cgst + $r->sgst + $r->igst + $r->cess, 2, '.', ''),
            ])->values()->toArray(),
        ];
    }

    // ── GSTR-3B Support ─────────────────────────────────────────────────────

    public function gstr3bSupport(string $fromDate, string $toDate): array
    {
        $outward = DB::connection('tenant')
            ->table('sales_invoices')
            ->whereIn('status', ['confirmed', 'partially_paid', 'paid'])
            ->whereBetween('invoice_date', [$fromDate, $toDate])
            ->whereNull('deleted_at')
            ->selectRaw('SUM(taxable_amount) as taxable, SUM(cgst_amount) as cgst, SUM(sgst_amount) as sgst, SUM(igst_amount) as igst, SUM(cess_amount) as cess')
            ->first();

        $itcEligible = DB::connection('tenant')
            ->table('purchase_invoice_lines as pil')
            ->join('purchase_invoices as pi', 'pi.id', '=', 'pil.purchase_invoice_id')
            ->where('pi.status', 'posted')
            ->where('pil.itc_eligible', true)
            ->whereBetween('pi.invoice_date', [$fromDate, $toDate])
            ->whereNull('pi.deleted_at')
            ->selectRaw('SUM(pil.cgst_amount) as cgst, SUM(pil.sgst_amount) as sgst, SUM(pil.igst_amount) as igst, SUM(pil.cess_amount) as cess')
            ->first();

        $outwardTax = ($outward->cgst ?? 0) + ($outward->sgst ?? 0) + ($outward->igst ?? 0) + ($outward->cess ?? 0);
        $itcTotal   = ($itcEligible->cgst ?? 0) + ($itcEligible->sgst ?? 0) + ($itcEligible->igst ?? 0) + ($itcEligible->cess ?? 0);

        return [
            'period' => "{$fromDate} to {$toDate}",
            'outward_supplies' => [
                'taxable_value' => number_format($outward->taxable ?? 0, 2, '.', ''),
                'cgst'          => number_format($outward->cgst ?? 0, 2, '.', ''),
                'sgst'          => number_format($outward->sgst ?? 0, 2, '.', ''),
                'igst'          => number_format($outward->igst ?? 0, 2, '.', ''),
                'cess'          => number_format($outward->cess ?? 0, 2, '.', ''),
                'total_tax'     => number_format($outwardTax, 2, '.', ''),
            ],
            'eligible_itc' => [
                'cgst'      => number_format($itcEligible->cgst ?? 0, 2, '.', ''),
                'sgst'      => number_format($itcEligible->sgst ?? 0, 2, '.', ''),
                'igst'      => number_format($itcEligible->igst ?? 0, 2, '.', ''),
                'cess'      => number_format($itcEligible->cess ?? 0, 2, '.', ''),
                'total_itc' => number_format($itcTotal, 2, '.', ''),
            ],
            'net_tax_payable' => number_format(max(0, $outwardTax - $itcTotal), 2, '.', ''),
        ];
    }

    // ── ITC Register ────────────────────────────────────────────────────────

    public function itcRegister(string $fromDate, string $toDate, ?int $vendorId = null): array
    {
        $query = DB::connection('tenant')
            ->table('purchase_invoice_lines as pil')
            ->join('purchase_invoices as pi', 'pi.id', '=', 'pil.purchase_invoice_id')
            ->join('vendors as v', 'v.id', '=', 'pi.vendor_id')
            ->where('pi.status', 'posted')
            ->where('pil.itc_eligible', true)
            ->whereBetween('pi.invoice_date', [$fromDate, $toDate])
            ->whereNull('pi.deleted_at')
            ->select([
                'pi.invoice_number as purchase_invoice_number',
                'pi.invoice_date',
                'pi.vendor_invoice_number',
                'v.name as vendor_name',
                'v.gstin as vendor_gstin',
                'pil.description',
                'pil.hsn_sac',
                'pil.gst_rate',
                'pil.taxable_amount',
                'pil.cgst_amount',
                'pil.sgst_amount',
                'pil.igst_amount',
                'pil.cess_amount',
            ])
            ->orderBy('pi.invoice_date');

        if ($vendorId) {
            $query->where('pi.vendor_id', $vendorId);
        }

        $rows = $query->get();

        return [
            'period'  => "{$fromDate} to {$toDate}",
            'summary' => [
                'total_cgst' => number_format($rows->sum('cgst_amount'), 2, '.', ''),
                'total_sgst' => number_format($rows->sum('sgst_amount'), 2, '.', ''),
                'total_igst' => number_format($rows->sum('igst_amount'), 2, '.', ''),
                'total_cess' => number_format($rows->sum('cess_amount'), 2, '.', ''),
                'total_itc'  => number_format($rows->sum(fn ($r) => $r->cgst_amount + $r->sgst_amount + $r->igst_amount + $r->cess_amount), 2, '.', ''),
            ],
            'records' => $rows->map(fn ($r) => [
                'purchase_invoice_number' => $r->purchase_invoice_number,
                'vendor_invoice_number'   => $r->vendor_invoice_number,
                'invoice_date'            => $r->invoice_date,
                'vendor_name'             => $r->vendor_name,
                'vendor_gstin'            => $r->vendor_gstin,
                'description'             => $r->description,
                'hsn_sac'                 => $r->hsn_sac,
                'gst_rate'                => (int) $r->gst_rate,
                'taxable_amount'          => number_format($r->taxable_amount, 2, '.', ''),
                'cgst'                    => number_format($r->cgst_amount, 2, '.', ''),
                'sgst'                    => number_format($r->sgst_amount, 2, '.', ''),
                'igst'                    => number_format($r->igst_amount, 2, '.', ''),
                'cess'                    => number_format($r->cess_amount, 2, '.', ''),
            ])->values()->toArray(),
        ];
    }

    // ── Sales Tax Register ──────────────────────────────────────────────────

    public function salesTaxRegister(string $fromDate, string $toDate): array
    {
        $rows = DB::connection('tenant')
            ->table('sales_invoices as si')
            ->join('customers as c', 'c.id', '=', 'si.customer_id')
            ->whereIn('si.status', ['confirmed', 'partially_paid', 'paid', 'cancelled'])
            ->whereBetween('si.invoice_date', [$fromDate, $toDate])
            ->whereNull('si.deleted_at')
            ->select([
                'si.invoice_number',
                'si.invoice_date',
                'si.invoice_type',
                'si.place_of_supply',
                'si.status',
                'c.name as customer_name',
                'c.gstin as customer_gstin',
                'si.taxable_amount',
                'si.cgst_amount',
                'si.sgst_amount',
                'si.igst_amount',
                'si.cess_amount',
                'si.round_off',
                'si.total_amount',
            ])
            ->orderBy('si.invoice_date')
            ->get();

        return [
            'period'  => "{$fromDate} to {$toDate}",
            'summary' => [
                'total_taxable' => number_format($rows->where('status', '!=', 'cancelled')->sum('taxable_amount'), 2, '.', ''),
                'total_cgst'    => number_format($rows->where('status', '!=', 'cancelled')->sum('cgst_amount'), 2, '.', ''),
                'total_sgst'    => number_format($rows->where('status', '!=', 'cancelled')->sum('sgst_amount'), 2, '.', ''),
                'total_igst'    => number_format($rows->where('status', '!=', 'cancelled')->sum('igst_amount'), 2, '.', ''),
                'total_amount'  => number_format($rows->where('status', '!=', 'cancelled')->sum('total_amount'), 2, '.', ''),
            ],
            'records' => $rows->map(fn ($r) => [
                'invoice_number'  => $r->invoice_number,
                'invoice_date'    => $r->invoice_date,
                'invoice_type'    => $r->invoice_type,
                'place_of_supply' => $r->place_of_supply,
                'status'          => $r->status,
                'customer_name'   => $r->customer_name,
                'customer_gstin'  => $r->customer_gstin,
                'taxable_amount'  => number_format($r->taxable_amount, 2, '.', ''),
                'cgst'            => number_format($r->cgst_amount, 2, '.', ''),
                'sgst'            => number_format($r->sgst_amount, 2, '.', ''),
                'igst'            => number_format($r->igst_amount, 2, '.', ''),
                'cess'            => number_format($r->cess_amount, 2, '.', ''),
                'total_amount'    => number_format($r->total_amount, 2, '.', ''),
            ])->values()->toArray(),
        ];
    }

    // ── Purchase Tax Register ───────────────────────────────────────────────

    public function purchaseTaxRegister(string $fromDate, string $toDate): array
    {
        $rows = DB::connection('tenant')
            ->table('purchase_invoices as pi')
            ->join('vendors as v', 'v.id', '=', 'pi.vendor_id')
            ->whereIn('pi.status', ['posted', 'partially_paid', 'paid', 'cancelled'])
            ->whereBetween('pi.invoice_date', [$fromDate, $toDate])
            ->whereNull('pi.deleted_at')
            ->select([
                'pi.invoice_number',
                'pi.invoice_date',
                'pi.vendor_invoice_number',
                'pi.status',
                'v.name as vendor_name',
                'v.gstin as vendor_gstin',
                'pi.taxable_amount',
                'pi.cgst_amount',
                'pi.sgst_amount',
                'pi.igst_amount',
                'pi.cess_amount',
                'pi.total_amount',
            ])
            ->orderBy('pi.invoice_date')
            ->get();

        return [
            'period'  => "{$fromDate} to {$toDate}",
            'summary' => [
                'total_taxable' => number_format($rows->where('status', '!=', 'cancelled')->sum('taxable_amount'), 2, '.', ''),
                'total_cgst'    => number_format($rows->where('status', '!=', 'cancelled')->sum('cgst_amount'), 2, '.', ''),
                'total_sgst'    => number_format($rows->where('status', '!=', 'cancelled')->sum('sgst_amount'), 2, '.', ''),
                'total_igst'    => number_format($rows->where('status', '!=', 'cancelled')->sum('igst_amount'), 2, '.', ''),
                'total_amount'  => number_format($rows->where('status', '!=', 'cancelled')->sum('total_amount'), 2, '.', ''),
            ],
            'records' => $rows->map(fn ($r) => [
                'invoice_number'        => $r->invoice_number,
                'vendor_invoice_number' => $r->vendor_invoice_number,
                'invoice_date'          => $r->invoice_date,
                'status'                => $r->status,
                'vendor_name'           => $r->vendor_name,
                'vendor_gstin'          => $r->vendor_gstin,
                'taxable_amount'        => number_format($r->taxable_amount, 2, '.', ''),
                'cgst'                  => number_format($r->cgst_amount, 2, '.', ''),
                'sgst'                  => number_format($r->sgst_amount, 2, '.', ''),
                'igst'                  => number_format($r->igst_amount, 2, '.', ''),
                'cess'                  => number_format($r->cess_amount, 2, '.', ''),
                'total_amount'          => number_format($r->total_amount, 2, '.', ''),
            ])->values()->toArray(),
        ];
    }

    // ── Helpers ─────────────────────────────────────────────────────────────

    private function tableExists(string $table): bool
    {
        try {
            return DB::connection('tenant')->getSchemaBuilder()->hasTable($table);
        } catch (\Throwable) {
            return false;
        }
    }
}
