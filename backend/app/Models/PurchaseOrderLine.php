<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Relations\BelongsTo;

class PurchaseOrderLine extends TenantModel
{
    public $timestamps = false;

    protected $table = 'purchase_order_lines';

    protected $fillable = [
        'purchase_order_id',
        'product_id',
        'description',
        'hsn_sac',
        'quantity',
        'unit',
        'unit_price',
        'discount_pct',
        'discount_amount',
        'taxable_amount',
        'gst_rate',
        'cgst_rate',
        'cgst_amount',
        'sgst_rate',
        'sgst_amount',
        'igst_rate',
        'igst_amount',
        'tax_amount',
        'line_total',
        'sort_order',
    ];

    protected $casts = [
        'quantity'       => 'float',
        'unit_price'     => 'float',
        'taxable_amount' => 'float',
        'line_total'     => 'float',
    ];

    public function product(): BelongsTo
    {
        return $this->belongsTo(Product::class);
    }

    public function purchaseOrder(): BelongsTo
    {
        return $this->belongsTo(PurchaseOrder::class);
    }
}
