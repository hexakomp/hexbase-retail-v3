<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

/**
 * CreditNote — issued to customer against a sales invoice.
 */
class CreditNote extends TenantModel
{
    use SoftDeletes;

    protected $table = 'credit_notes';

    protected $fillable = [
        'credit_note_number',
        'credit_note_date',
        'customer_id',
        'sales_invoice_id',
        'reason',
        'subtotal',
        'cgst_amount',
        'sgst_amount',
        'igst_amount',
        'tax_amount',
        'total_amount',
        'status',
        'created_by',
    ];

    protected $casts = [
        'credit_note_date' => 'date',
        'subtotal'         => 'float',
        'cgst_amount'      => 'float',
        'sgst_amount'      => 'float',
        'igst_amount'      => 'float',
        'tax_amount'       => 'float',
        'total_amount'     => 'float',
    ];

    // ── Relationships ─────────────────────────────────────────────────────

    public function customer(): BelongsTo
    {
        return $this->belongsTo(Customer::class);
    }

    public function salesInvoice(): BelongsTo
    {
        return $this->belongsTo(SalesInvoice::class);
    }

    public function lines(): HasMany
    {
        return $this->hasMany(CreditNoteLine::class)->orderBy('sort_order');
    }

    public function createdBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    // ── Scopes ───────────────────────────────────────────────────────────

    public function scopeSearch($query, ?string $term)
    {
        if (! $term) {
            return $query;
        }
        return $query->where(function ($q) use ($term) {
            $q->where('credit_note_number', 'like', "%{$term}%");
        });
    }

    public function scopeByStatus($query, ?string $status)
    {
        return $status ? $query->where('status', $status) : $query;
    }
}
