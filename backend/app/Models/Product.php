<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\SoftDeletes;

class Product extends TenantModel
{
    use HasFactory, SoftDeletes;

    protected $fillable = [
        'name', 'description', 'code', 'sku', 'hsn_sac', 'type', 'unit',
        'sale_price', 'purchase_price', 'mrp',
        'gst_rate', 'cess_rate',
        'track_inventory', 'opening_stock', 'reorder_level',
        'is_active', 'custom_fields',
    ];

    protected $casts = [
        'sale_price'      => 'decimal:2',
        'purchase_price'  => 'decimal:2',
        'mrp'             => 'decimal:2',
        'gst_rate'        => 'integer',
        'cess_rate'       => 'integer',
        'track_inventory' => 'boolean',
        'opening_stock'   => 'decimal:3',
        'reorder_level'   => 'decimal:3',
        'is_active'       => 'boolean',
        'custom_fields'   => 'array',
    ];
}
