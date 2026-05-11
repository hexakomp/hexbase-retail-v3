<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\SoftDeletes;

class Expense extends TenantModel
{
    use SoftDeletes;

    protected $table = 'expenses';

    protected $fillable = [
        'expense_number',
        'expense_date',
        'category',
        'description',
        'vendor_id',
        'bank_account_id',
        'payment_mode',
        'amount',
        'gst_amount',
        'total_amount',
        'is_billable',
        'customer_id',
        'reference',
        'status',
        'created_by',
    ];

    protected $casts = [
        'expense_date' => 'date',
        'amount'       => 'float',
        'gst_amount'   => 'float',
        'total_amount' => 'float',
        'is_billable'  => 'boolean',
    ];

    public function vendor(): BelongsTo
    {
        return $this->belongsTo(Vendor::class);
    }

    public function customer(): BelongsTo
    {
        return $this->belongsTo(Customer::class);
    }

    public function bankAccount(): BelongsTo
    {
        return $this->belongsTo(BankAccount::class);
    }

    public function createdBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    public function scopeSearch($query, ?string $term)
    {
        return $term
            ? $query->where(function ($q) use ($term) {
                $q->where('expense_number', 'like', "%{$term}%")
                  ->orWhere('description', 'like', "%{$term}%");
            })
            : $query;
    }

    public function scopeByStatus($query, ?string $status)
    {
        return $status ? $query->where('status', $status) : $query;
    }
}
