<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

class DeliveryChallan extends TenantModel
{
    use SoftDeletes;

    protected $table = 'delivery_challans';

    protected $fillable = [
        'dc_number',
        'dc_date',
        'customer_id',
        'sales_invoice_id',
        'vehicle_number',
        'transporter_name',
        'dispatch_through',
        'destination',
        'notes',
        'subtotal',
        'total_amount',
        'status',
        'created_by',
    ];

    protected $casts = [
        'dc_date'  => 'date',
        'subtotal' => 'float',
        'total_amount' => 'float',
    ];

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
        return $this->hasMany(DeliveryChallanLine::class)->orderBy('sort_order');
    }

    public function createdBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    public function scopeSearch($query, ?string $term)
    {
        return $term ? $query->where('dc_number', 'like', "%{$term}%") : $query;
    }

    public function scopeByStatus($query, ?string $status)
    {
        return $status ? $query->where('status', $status) : $query;
    }
}
