<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

class Payment extends TenantModel
{
    use SoftDeletes;

    protected $table = 'payments';

    protected $fillable = [
        'payment_number',
        'payment_date',
        'vendor_id',
        'bank_account_id',
        'payment_mode',
        'reference_number',
        'amount',
        'tds_amount',
        'advance_amount',
        'narration',
        'notes',
        'custom_fields',
        'status',
        'created_by',
    ];

    protected function casts(): array
    {
        return [
            'payment_date'  => 'date',
            'amount'        => 'float',
            'tds_amount'    => 'float',
            'advance_amount'=> 'float',
            'custom_fields' => 'array',
        ];
    }

    // ── Relationships ────────────────────────────────────────────────────────

    public function vendor(): BelongsTo
    {
        return $this->belongsTo(Vendor::class);
    }

    public function createdBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    public function allocations(): HasMany
    {
        return $this->hasMany(PaymentAllocation::class);
    }

    // ── Scopes ───────────────────────────────────────────────────────────────

    public function scopeSearch($query, ?string $search)
    {
        if (!$search) {
            return $query;
        }

        return $query->where(function ($q) use ($search) {
            $q->where('payment_number', 'like', "%{$search}%")
              ->orWhereHas('vendor', fn ($v) => $v->where('name', 'like', "%{$search}%"));
        });
    }

    public function scopeByStatus($query, ?string $status)
    {
        return $status ? $query->where('status', $status) : $query;
    }

    public function scopeByPaymentMode($query, ?string $mode)
    {
        return $mode ? $query->where('payment_mode', $mode) : $query;
    }
}
