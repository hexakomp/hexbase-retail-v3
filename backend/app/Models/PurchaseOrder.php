<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

class PurchaseOrder extends TenantModel
{
    use SoftDeletes;

    protected $table = 'purchase_orders';

    protected $fillable = [
        'po_number',
        'po_date',
        'expected_delivery_date',
        'vendor_id',
        'subtotal',
        'cgst_amount',
        'sgst_amount',
        'igst_amount',
        'tax_amount',
        'total_amount',
        'status',
        'notes',
        'created_by',
    ];

    protected $casts = [
        'po_date'               => 'date',
        'expected_delivery_date'=> 'date',
        'subtotal'              => 'float',
        'cgst_amount'           => 'float',
        'sgst_amount'           => 'float',
        'igst_amount'           => 'float',
        'tax_amount'            => 'float',
        'total_amount'          => 'float',
    ];

    public function vendor(): BelongsTo
    {
        return $this->belongsTo(Vendor::class);
    }

    public function lines(): HasMany
    {
        return $this->hasMany(PurchaseOrderLine::class)->orderBy('sort_order');
    }

    public function createdBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    public function scopeSearch($query, ?string $term)
    {
        return $term ? $query->where('po_number', 'like', "%{$term}%") : $query;
    }

    public function scopeByStatus($query, ?string $status)
    {
        return $status ? $query->where('status', $status) : $query;
    }
}
