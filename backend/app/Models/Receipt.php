<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

class Receipt extends TenantModel
{
    use SoftDeletes;

    protected $fillable = [
        'receipt_number',
        'receipt_date',
        'customer_id',
        'bank_account_id',
        'payment_mode',
        'reference_number',
        'amount',
        'advance_amount',
        'narration',
        'notes',
        'custom_fields',
        'status',
        'created_by',
    ];

    protected $casts = [
        'receipt_date'   => 'date',
        'amount'         => 'float',
        'advance_amount' => 'float',
        'custom_fields'  => 'array',
    ];

    // ── Relationships ────────────────────────────────────────────────────────

    public function customer(): BelongsTo
    {
        return $this->belongsTo(Customer::class);
    }

    public function createdBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    public function allocations(): HasMany
    {
        return $this->hasMany(ReceiptAllocation::class);
    }

    // ── Scopes ───────────────────────────────────────────────────────────────

    public function scopeSearch($query, ?string $term)
    {
        if (! $term) {
            return $query;
        }

        return $query->where(function ($q) use ($term) {
            $q->where('receipt_number', 'like', "%{$term}%")
              ->orWhereHas('customer', fn ($cq) => $cq->where('name', 'like', "%{$term}%"));
        });
    }

    public function scopeByStatus($query, ?string $status)
    {
        if (! $status) {
            return $query;
        }

        return $query->where('status', $status);
    }

    public function scopeByPaymentMode($query, ?string $mode)
    {
        if (! $mode) {
            return $query;
        }

        return $query->where('payment_mode', $mode);
    }
}
