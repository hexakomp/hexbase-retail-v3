<?php

namespace App\Services;

use Illuminate\Support\Facades\DB;

/**
 * FinancialReportService — Trial balance, P&L, balance sheet, day book, cash book, registers.
 */
class FinancialReportService
{
    // ── Trial Balance ────────────────────────────────────────────────────────

    public function trialBalance(string $asOfDate): array
    {
        $accounts = DB::connection('tenant')
            ->table('chart_of_accounts as coa')
            ->leftJoinSub(
                DB::connection('tenant')
                    ->table('ledger_entries')
                    ->where('date', '<=', $asOfDate)
                    ->select('account_id', DB::raw('SUM(debit_amount) as total_debit'), DB::raw('SUM(credit_amount) as total_credit'))
                    ->groupBy('account_id'),
                'le',
                'le.account_id',
                '=',
                'coa.id'
            )
            ->orderBy('coa.code')
            ->select([
                'coa.id',
                'coa.code',
                'coa.name',
                'coa.type',
                'coa.group',
                DB::raw('COALESCE(le.total_debit, 0) as debit'),
                DB::raw('COALESCE(le.total_credit, 0) as credit'),
            ])
            ->get();

        $totalDebit  = $accounts->sum('debit');
        $totalCredit = $accounts->sum('credit');

        return [
            'as_of_date'   => $asOfDate,
            'total_debit'  => number_format($totalDebit, 2, '.', ''),
            'total_credit' => number_format($totalCredit, 2, '.', ''),
            'balanced'     => abs($totalDebit - $totalCredit) < 0.01,
            'accounts'     => $accounts->map(fn ($a) => [
                'id'     => $a->id,
                'code'   => $a->code,
                'name'   => $a->name,
                'type'   => $a->type,
                'group'  => $a->group,
                'debit'  => number_format($a->debit, 2, '.', ''),
                'credit' => number_format($a->credit, 2, '.', ''),
            ])->values()->toArray(),
        ];
    }

    // ── Profit & Loss ────────────────────────────────────────────────────────

    public function profitLoss(string $fromDate, string $toDate): array
    {
        $rows = DB::connection('tenant')
            ->table('chart_of_accounts as coa')
            ->join('ledger_entries as le', 'le.account_id', '=', 'coa.id')
            ->whereIn('coa.type', ['income', 'expense'])
            ->whereBetween('le.date', [$fromDate, $toDate])
            ->select([
                'coa.id',
                'coa.code',
                'coa.name',
                'coa.type',
                DB::raw('SUM(le.debit_amount) as debit'),
                DB::raw('SUM(le.credit_amount) as credit'),
            ])
            ->groupBy('coa.id', 'coa.code', 'coa.name', 'coa.type')
            ->orderBy('coa.type')
            ->orderBy('coa.code')
            ->get();

        $income  = $rows->where('type', 'income');
        $expense = $rows->where('type', 'expense');

        // For income accounts: net = credit - debit
        $totalIncome  = $income->sum(fn ($r) => $r->credit - $r->debit);
        // For expense accounts: net = debit - credit
        $totalExpense = $expense->sum(fn ($r) => $r->debit - $r->credit);
        $netProfit    = $totalIncome - $totalExpense;

        return [
            'period'         => "{$fromDate} to {$toDate}",
            'total_income'   => number_format($totalIncome, 2, '.', ''),
            'total_expense'  => number_format($totalExpense, 2, '.', ''),
            'net_profit'     => number_format($netProfit, 2, '.', ''),
            'is_profit'      => $netProfit >= 0,
            'income'         => $income->map(fn ($r) => [
                'id'     => $r->id,
                'code'   => $r->code,
                'name'   => $r->name,
                'amount' => number_format($r->credit - $r->debit, 2, '.', ''),
            ])->values()->toArray(),
            'expense'        => $expense->map(fn ($r) => [
                'id'     => $r->id,
                'code'   => $r->code,
                'name'   => $r->name,
                'amount' => number_format($r->debit - $r->credit, 2, '.', ''),
            ])->values()->toArray(),
        ];
    }

    // ── Balance Sheet ────────────────────────────────────────────────────────

    public function balanceSheet(string $asOfDate): array
    {
        $rows = DB::connection('tenant')
            ->table('chart_of_accounts as coa')
            ->leftJoinSub(
                DB::connection('tenant')
                    ->table('ledger_entries')
                    ->where('date', '<=', $asOfDate)
                    ->select('account_id', DB::raw('SUM(debit_amount) as total_debit'), DB::raw('SUM(credit_amount) as total_credit'))
                    ->groupBy('account_id'),
                'le',
                'le.account_id',
                '=',
                'coa.id'
            )
            ->whereIn('coa.type', ['asset', 'liability', 'equity'])
            ->select([
                'coa.id',
                'coa.code',
                'coa.name',
                'coa.type',
                DB::raw('COALESCE(le.total_debit, 0) as debit'),
                DB::raw('COALESCE(le.total_credit, 0) as credit'),
            ])
            ->orderBy('coa.type')
            ->orderBy('coa.code')
            ->get();

        $assets      = $rows->where('type', 'asset');
        $liabilities = $rows->where('type', 'liability');
        $equity      = $rows->where('type', 'equity');

        $totalAssets      = $assets->sum(fn ($r) => $r->debit - $r->credit);
        $totalLiabilities = $liabilities->sum(fn ($r) => $r->credit - $r->debit);
        $totalEquity      = $equity->sum(fn ($r) => $r->credit - $r->debit);

        $format = fn ($r, $netFn) => [
            'id'     => $r->id,
            'code'   => $r->code,
            'name'   => $r->name,
            'amount' => number_format($netFn($r), 2, '.', ''),
        ];

        return [
            'as_of_date'         => $asOfDate,
            'total_assets'       => number_format($totalAssets, 2, '.', ''),
            'total_liabilities'  => number_format($totalLiabilities, 2, '.', ''),
            'total_equity'       => number_format($totalEquity, 2, '.', ''),
            'balanced'           => abs($totalAssets - ($totalLiabilities + $totalEquity)) < 0.01,
            'assets'             => $assets->map(fn ($r) => $format($r, fn ($x) => $x->debit - $x->credit))->values()->toArray(),
            'liabilities'        => $liabilities->map(fn ($r) => $format($r, fn ($x) => $x->credit - $x->debit))->values()->toArray(),
            'equity'             => $equity->map(fn ($r) => $format($r, fn ($x) => $x->credit - $x->debit))->values()->toArray(),
        ];
    }

    // ── Day Book ─────────────────────────────────────────────────────────────

    public function dayBook(string $fromDate, string $toDate, ?string $voucherType = null): array
    {
        $vouchers = collect();

        // Sales invoices
        if (!$voucherType || $voucherType === 'sales_invoice') {
            $rows = DB::connection('tenant')
                ->table('sales_invoices as si')
                ->join('customers as c', 'c.id', '=', 'si.customer_id')
                ->whereNotIn('si.status', ['draft', 'cancelled'])
                ->whereBetween('si.invoice_date', [$fromDate, $toDate])
                ->whereNull('si.deleted_at')
                ->select([
                    DB::raw("'sales_invoice' as voucher_type"),
                    'si.invoice_number as voucher_number',
                    'si.invoice_date as date',
                    'c.name as party_name',
                    'si.total_amount as amount',
                    'si.narration',
                    'si.status',
                ])
                ->get();
            $vouchers = $vouchers->merge($rows);
        }

        // Purchase invoices
        if (!$voucherType || $voucherType === 'purchase_invoice') {
            $rows = DB::connection('tenant')
                ->table('purchase_invoices as pi')
                ->join('vendors as v', 'v.id', '=', 'pi.vendor_id')
                ->whereNotIn('pi.status', ['draft', 'cancelled'])
                ->whereBetween('pi.invoice_date', [$fromDate, $toDate])
                ->whereNull('pi.deleted_at')
                ->select([
                    DB::raw("'purchase_invoice' as voucher_type"),
                    'pi.invoice_number as voucher_number',
                    'pi.invoice_date as date',
                    'v.name as party_name',
                    'pi.total_amount as amount',
                    'pi.narration',
                    'pi.status',
                ])
                ->get();
            $vouchers = $vouchers->merge($rows);
        }

        // Receipts
        if (!$voucherType || $voucherType === 'receipt') {
            $rows = DB::connection('tenant')
                ->table('receipts as r')
                ->join('customers as c', 'c.id', '=', 'r.customer_id')
                ->whereNotIn('r.status', ['draft', 'cancelled'])
                ->whereBetween('r.receipt_date', [$fromDate, $toDate])
                ->whereNull('r.deleted_at')
                ->select([
                    DB::raw("'receipt' as voucher_type"),
                    'r.receipt_number as voucher_number',
                    'r.receipt_date as date',
                    'c.name as party_name',
                    'r.amount',
                    'r.narration',
                    'r.status',
                ])
                ->get();
            $vouchers = $vouchers->merge($rows);
        }

        // Payments
        if (!$voucherType || $voucherType === 'payment') {
            $rows = DB::connection('tenant')
                ->table('payments as p')
                ->join('vendors as v', 'v.id', '=', 'p.vendor_id')
                ->whereNotIn('p.status', ['draft', 'cancelled'])
                ->whereBetween('p.payment_date', [$fromDate, $toDate])
                ->whereNull('p.deleted_at')
                ->select([
                    DB::raw("'payment' as voucher_type"),
                    'p.payment_number as voucher_number',
                    'p.payment_date as date',
                    'v.name as party_name',
                    'p.amount',
                    'p.narration',
                    'p.status',
                ])
                ->get();
            $vouchers = $vouchers->merge($rows);
        }

        $sorted = $vouchers->sortBy('date')->values();

        return [
            'period'  => "{$fromDate} to {$toDate}",
            'records' => $sorted->map(fn ($r) => [
                'voucher_type'   => $r->voucher_type,
                'voucher_number' => $r->voucher_number,
                'date'           => $r->date,
                'party_name'     => $r->party_name,
                'amount'         => number_format($r->amount, 2, '.', ''),
                'narration'      => $r->narration,
                'status'         => $r->status,
            ])->toArray(),
        ];
    }

    // ── Cash Book ────────────────────────────────────────────────────────────

    public function cashBook(string $fromDate, string $toDate): array
    {
        $cashAccount = DB::connection('tenant')
            ->table('chart_of_accounts')
            ->where('type', 'cash')
            ->first();

        if (!$cashAccount) {
            return ['period' => "{$fromDate} to {$toDate}", 'opening_balance' => '0.00', 'closing_balance' => '0.00', 'records' => []];
        }

        $openingDebit = DB::connection('tenant')
            ->table('ledger_entries')
            ->where('account_id', $cashAccount->id)
            ->where('date', '<', $fromDate)
            ->sum('debit_amount');

        $openingCredit = DB::connection('tenant')
            ->table('ledger_entries')
            ->where('account_id', $cashAccount->id)
            ->where('date', '<', $fromDate)
            ->sum('credit_amount');

        $openingBalance = $openingDebit - $openingCredit;

        $entries = DB::connection('tenant')
            ->table('ledger_entries as le')
            ->where('le.account_id', $cashAccount->id)
            ->whereBetween('le.date', [$fromDate, $toDate])
            ->orderBy('le.date')
            ->orderBy('le.id')
            ->get();

        return [
            'period'          => "{$fromDate} to {$toDate}",
            'account_name'    => $cashAccount->name,
            'opening_balance' => number_format($openingBalance, 2, '.', ''),
            'closing_balance' => number_format(
                $openingBalance + $entries->sum('debit_amount') - $entries->sum('credit_amount'),
                2, '.', ''
            ),
            'records' => $entries->map(fn ($e) => [
                'date'          => $e->date,
                'reference'     => $e->reference,
                'narration'     => $e->narration,
                'debit_amount'  => number_format($e->debit_amount, 2, '.', ''),
                'credit_amount' => number_format($e->credit_amount, 2, '.', ''),
            ])->toArray(),
        ];
    }

    // ── Sales Register ───────────────────────────────────────────────────────

    public function salesRegister(string $fromDate, string $toDate, ?int $customerId = null): array
    {
        $query = DB::connection('tenant')
            ->table('sales_invoices as si')
            ->join('customers as c', 'c.id', '=', 'si.customer_id')
            ->whereNotIn('si.status', ['draft'])
            ->whereBetween('si.invoice_date', [$fromDate, $toDate])
            ->whereNull('si.deleted_at')
            ->select([
                'si.invoice_number',
                'si.invoice_date',
                'si.invoice_type',
                'si.status',
                'c.name as customer_name',
                'c.gstin as customer_gstin',
                'si.taxable_amount',
                'si.cgst_amount',
                'si.sgst_amount',
                'si.igst_amount',
                'si.total_amount',
                'si.paid_amount',
                'si.balance_amount as outstanding_amount',
            ])
            ->orderBy('si.invoice_date');

        if ($customerId) {
            $query->where('si.customer_id', $customerId);
        }

        $rows = $query->get();

        return [
            'period'         => "{$fromDate} to {$toDate}",
            'total_taxable'  => number_format($rows->sum('taxable_amount'), 2, '.', ''),
            'total_tax'      => number_format($rows->sum(fn ($r) => $r->cgst_amount + $r->sgst_amount + $r->igst_amount), 2, '.', ''),
            'total_amount'   => number_format($rows->sum('total_amount'), 2, '.', ''),
            'total_outstanding' => number_format($rows->sum('outstanding_amount'), 2, '.', ''),
            'records'        => $rows->map(fn ($r) => [
                'invoice_number'   => $r->invoice_number,
                'invoice_date'     => $r->invoice_date,
                'invoice_type'     => $r->invoice_type,
                'status'           => $r->status,
                'customer_name'    => $r->customer_name,
                'customer_gstin'   => $r->customer_gstin,
                'taxable_amount'   => number_format($r->taxable_amount, 2, '.', ''),
                'cgst'             => number_format($r->cgst_amount, 2, '.', ''),
                'sgst'             => number_format($r->sgst_amount, 2, '.', ''),
                'igst'             => number_format($r->igst_amount, 2, '.', ''),
                'total_amount'     => number_format($r->total_amount, 2, '.', ''),
                'paid_amount'      => number_format($r->paid_amount, 2, '.', ''),
                'outstanding'      => number_format($r->outstanding_amount, 2, '.', ''),
            ])->values()->toArray(),
        ];
    }

    // ── Purchase Register ────────────────────────────────────────────────────

    public function purchaseRegister(string $fromDate, string $toDate, ?int $vendorId = null): array
    {
        $query = DB::connection('tenant')
            ->table('purchase_invoices as pi')
            ->join('vendors as v', 'v.id', '=', 'pi.vendor_id')
            ->whereNotIn('pi.status', ['draft'])
            ->whereBetween('pi.invoice_date', [$fromDate, $toDate])
            ->whereNull('pi.deleted_at')
            ->select([
                'pi.invoice_number',
                'pi.vendor_invoice_number',
                'pi.invoice_date',
                'pi.status',
                'v.name as vendor_name',
                'v.gstin as vendor_gstin',
                'pi.taxable_amount',
                'pi.cgst_amount',
                'pi.sgst_amount',
                'pi.igst_amount',
                'pi.total_amount',
                'pi.outstanding_amount',
            ])
            ->orderBy('pi.invoice_date');

        if ($vendorId) {
            $query->where('pi.vendor_id', $vendorId);
        }

        $rows = $query->get();

        return [
            'period'            => "{$fromDate} to {$toDate}",
            'total_taxable'     => number_format($rows->sum('taxable_amount'), 2, '.', ''),
            'total_tax'         => number_format($rows->sum(fn ($r) => $r->cgst_amount + $r->sgst_amount + $r->igst_amount), 2, '.', ''),
            'total_amount'      => number_format($rows->sum('total_amount'), 2, '.', ''),
            'total_outstanding' => number_format($rows->sum('outstanding_amount'), 2, '.', ''),
            'records'           => $rows->map(fn ($r) => [
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
                'total_amount'          => number_format($r->total_amount, 2, '.', ''),
                'outstanding'           => number_format($r->outstanding_amount, 2, '.', ''),
            ])->values()->toArray(),
        ];
    }

    // ── Cash Flow ────────────────────────────────────────────────────────────

    public function cashFlow(string $fromDate, string $toDate): array
    {
        $receipts = DB::connection('tenant')
            ->table('receipts')
            ->whereNotIn('status', ['draft', 'cancelled'])
            ->whereBetween('receipt_date', [$fromDate, $toDate])
            ->whereNull('deleted_at')
            ->sum('amount');

        $payments = DB::connection('tenant')
            ->table('payments')
            ->whereNotIn('status', ['draft', 'cancelled'])
            ->whereBetween('payment_date', [$fromDate, $toDate])
            ->whereNull('deleted_at')
            ->sum('amount');

        return [
            'period'        => "{$fromDate} to {$toDate}",
            'cash_inflow'   => number_format($receipts, 2, '.', ''),
            'cash_outflow'  => number_format($payments, 2, '.', ''),
            'net_cash_flow' => number_format($receipts - $payments, 2, '.', ''),
        ];
    }

    // ── Ledger Drill-Down ────────────────────────────────────────────────────

    public function ledger(int $accountId, string $fromDate, string $toDate): array
    {
        $account = DB::connection('tenant')
            ->table('chart_of_accounts')
            ->where('id', $accountId)
            ->firstOrFail();

        $openingDebit = DB::connection('tenant')
            ->table('ledger_entries')
            ->where('account_id', $accountId)
            ->where('date', '<', $fromDate)
            ->sum('debit_amount');

        $openingCredit = DB::connection('tenant')
            ->table('ledger_entries')
            ->where('account_id', $accountId)
            ->where('date', '<', $fromDate)
            ->sum('credit_amount');

        $openingBalance = $openingDebit - $openingCredit;

        $entries = DB::connection('tenant')
            ->table('ledger_entries')
            ->where('account_id', $accountId)
            ->whereBetween('date', [$fromDate, $toDate])
            ->orderBy('date')
            ->orderBy('id')
            ->get();

        $runningBalance = $openingBalance;
        $records = $entries->map(function ($e) use (&$runningBalance) {
            $runningBalance += $e->debit_amount - $e->credit_amount;
            return [
                'date'           => $e->date,
                'reference'      => $e->reference,
                'narration'      => $e->narration,
                'debit_amount'   => number_format($e->debit_amount, 2, '.', ''),
                'credit_amount'  => number_format($e->credit_amount, 2, '.', ''),
                'running_balance' => number_format($runningBalance, 2, '.', ''),
            ];
        });

        return [
            'account'         => ['id' => $account->id, 'code' => $account->code, 'name' => $account->name, 'type' => $account->type],
            'period'          => "{$fromDate} to {$toDate}",
            'opening_balance' => number_format($openingBalance, 2, '.', ''),
            'closing_balance' => number_format($runningBalance, 2, '.', ''),
            'records'         => $records->toArray(),
        ];
    }

    // ── Receivables Ageing ───────────────────────────────────────────────────

    public function receivablesAgeing(string $asOfDate): array
    {
        $invoices = DB::connection('tenant')
            ->table('sales_invoices as si')
            ->join('customers as c', 'c.id', '=', 'si.customer_id')
            ->whereIn('si.status', ['confirmed', 'partially_paid'])
            ->where('si.balance_amount', '>', 0)
            ->whereNull('si.deleted_at')
            ->select([
                'c.id as customer_id',
                'c.name as customer_name',
                'si.invoice_number',
                'si.invoice_date',
                'si.balance_amount as outstanding',
                DB::raw("DATEDIFF('{$asOfDate}', si.invoice_date) as days_overdue"),
            ])
            ->orderBy('c.name')
            ->orderBy('si.invoice_date')
            ->get();

        $bucket = fn ($days) => match (true) {
            $days <= 0  => 'current',
            $days <= 30 => '1_to_30',
            $days <= 60 => '31_to_60',
            $days <= 90 => '61_to_90',
            default     => 'above_90',
        };

        $grouped = $invoices->groupBy('customer_id')->map(function ($rows) use ($bucket) {
            $buckets = ['current' => 0, '1_to_30' => 0, '31_to_60' => 0, '61_to_90' => 0, 'above_90' => 0];
            foreach ($rows as $r) {
                $buckets[$bucket($r->days_overdue)] += $r->outstanding;
            }
            return [
                'customer_id'   => $rows->first()->customer_id,
                'customer_name' => $rows->first()->customer_name,
                'total'         => number_format($rows->sum('outstanding'), 2, '.', ''),
                'current'       => number_format($buckets['current'], 2, '.', ''),
                '1_to_30'       => number_format($buckets['1_to_30'], 2, '.', ''),
                '31_to_60'      => number_format($buckets['31_to_60'], 2, '.', ''),
                '61_to_90'      => number_format($buckets['61_to_90'], 2, '.', ''),
                'above_90'      => number_format($buckets['above_90'], 2, '.', ''),
            ];
        })->values();

        return ['as_of_date' => $asOfDate, 'records' => $grouped->toArray()];
    }

    // ── Payables Ageing ──────────────────────────────────────────────────────

    public function payablesAgeing(string $asOfDate): array
    {
        $invoices = DB::connection('tenant')
            ->table('purchase_invoices as pi')
            ->join('vendors as v', 'v.id', '=', 'pi.vendor_id')
            ->whereIn('pi.status', ['posted', 'partially_paid'])
            ->where('pi.outstanding_amount', '>', 0)
            ->whereNull('pi.deleted_at')
            ->select([
                'v.id as vendor_id',
                'v.name as vendor_name',
                'pi.invoice_number',
                'pi.invoice_date',
                'pi.outstanding_amount as outstanding',
                DB::raw("DATEDIFF('{$asOfDate}', pi.invoice_date) as days_overdue"),
            ])
            ->orderBy('v.name')
            ->orderBy('pi.invoice_date')
            ->get();

        $bucket = fn ($days) => match (true) {
            $days <= 0  => 'current',
            $days <= 30 => '1_to_30',
            $days <= 60 => '31_to_60',
            $days <= 90 => '61_to_90',
            default     => 'above_90',
        };

        $grouped = $invoices->groupBy('vendor_id')->map(function ($rows) use ($bucket) {
            $buckets = ['current' => 0, '1_to_30' => 0, '31_to_60' => 0, '61_to_90' => 0, 'above_90' => 0];
            foreach ($rows as $r) {
                $buckets[$bucket($r->days_overdue)] += $r->outstanding;
            }
            return [
                'vendor_id'   => $rows->first()->vendor_id,
                'vendor_name' => $rows->first()->vendor_name,
                'total'       => number_format($rows->sum('outstanding'), 2, '.', ''),
                'current'     => number_format($buckets['current'], 2, '.', ''),
                '1_to_30'     => number_format($buckets['1_to_30'], 2, '.', ''),
                '31_to_60'    => number_format($buckets['31_to_60'], 2, '.', ''),
                '61_to_90'    => number_format($buckets['61_to_90'], 2, '.', ''),
                'above_90'    => number_format($buckets['above_90'], 2, '.', ''),
            ];
        })->values();

        return ['as_of_date' => $asOfDate, 'records' => $grouped->toArray()];
    }
}
