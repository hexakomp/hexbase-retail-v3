<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Relations\BelongsTo;

class DeliveryChallanLine extends TenantModel
{
    public $timestamps = false;

    protected $table = 'delivery_challan_lines';

    protected $fillable = [
        'delivery_challan_id',
        'product_id',
        'description',
        'quantity',
        'unit',
        'unit_price',
        'line_total',
        'sort_order',
    ];

    protected $casts = [
        'quantity'   => 'float',
        'unit_price' => 'float',
        'line_total' => 'float',
    ];

    public function product(): BelongsTo
    {
        return $this->belongsTo(Product::class);
    }

    public function deliveryChallan(): BelongsTo
    {
        return $this->belongsTo(DeliveryChallan::class);
    }
}
