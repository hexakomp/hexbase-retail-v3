<?php

namespace App\Services;

use App\Models\PurchaseInvoice;
use App\Models\SalesInvoice;
use Carbon\Carbon;
use Illuminate\Support\Collection;

class AgingReportService
{
    /**
     * Receivables ageing — outstanding sales invoices grouped by customer.
     */
    public function receivablesAgeing(): Collection
    {
        $today = Carbon::today();

        $invoices = SalesInvoice::with('customer:id,name')
            ->whereIn('status', ['confirmed', 'partial'])
            ->where('balance_due', '>', 0)
            ->get();

        return $invoices
            ->groupBy('customer_id')
            ->map(function ($group) use ($today) {
                $customer = $group->first()->customer;

                $buckets = $this->bucketize($group, 'due_date', $today);
                $buckets['customer_id']   = $customer->id;
                $buckets['customer_name'] = $customer->name;

                return $buckets;
            })
            ->values();
    }

    /**
     * Payables ageing — outstanding purchase invoices grouped by vendor.
     */
    public function payablesAgeing(): Collection
    {
        $today = Carbon::today();

        $invoices = PurchaseInvoice::with('vendor:id,name')
            ->whereIn('status', ['confirmed', 'partial'])
            ->where('balance_due', '>', 0)
            ->get();

        return $invoices
            ->groupBy('vendor_id')
            ->map(function ($group) use ($today) {
                $vendor = $group->first()->vendor;

                $buckets = $this->bucketize($group, 'due_date', $today);
                $buckets['vendor_id']   = $vendor->id;
                $buckets['vendor_name'] = $vendor->name;

                return $buckets;
            })
            ->values();
    }

    private function bucketize(Collection $invoices, string $dateField, Carbon $today): array
    {
        $buckets = [
            'current'  => 0.0,   // 0-30 days
            'days_31_60' => 0.0,
            'days_61_90' => 0.0,
            'over_90'  => 0.0,
            'total'    => 0.0,
        ];

        foreach ($invoices as $inv) {
            $due  = Carbon::parse($inv->{$dateField});
            $days = $due->diffInDays($today, false); // positive = overdue
            $amt  = (float) ($inv->balance_due ?? $inv->total_amount ?? 0);

            if ($days <= 30) {
                $buckets['current'] += $amt;
            } elseif ($days <= 60) {
                $buckets['days_31_60'] += $amt;
            } elseif ($days <= 90) {
                $buckets['days_61_90'] += $amt;
            } else {
                $buckets['over_90'] += $amt;
            }

            $buckets['total'] += $amt;
        }

        return $buckets;
    }
}
