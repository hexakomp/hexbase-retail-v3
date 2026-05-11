<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

/**
 * DebitNote — issued to vendor against a purchase invoice (return).
 */
class DebitNote extends TenantModel
{
    use SoftDeletes;

    protected $table = 'debit_notes';

    protected $fillable = [
        'debit_note_number',
        'debit_note_date',
        'vendor_id',
        'purchase_invoice_id',
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
        'debit_note_date' => 'date',
        'subtotal'        => 'float',
        'cgst_amount'     => 'float',
        'sgst_amount'     => 'float',
        'igst_amount'     => 'float',
        'tax_amount'      => 'float',
        'total_amount'    => 'float',
    ];

    public function vendor(): BelongsTo
    {
        return $this->belongsTo(Vendor::class);
    }

    public function purchaseInvoice(): BelongsTo
    {
        return $this->belongsTo(PurchaseInvoice::class);
    }

    public function lines(): HasMany
    {
        return $this->hasMany(DebitNoteLine::class)->orderBy('sort_order');
    }

    public function createdBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    public function scopeSearch($query, ?string $term)
    {
        if (! $term) {
            return $query;
        }
        return $query->where('debit_note_number', 'like', "%{$term}%");
    }

    public function scopeByStatus($query, ?string $status)
    {
        return $status ? $query->where('status', $status) : $query;
    }
}
