<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\SoftDeletes;

class Customer extends TenantModel
{
    use HasFactory, SoftDeletes;

    protected $fillable = [
        'name', 'code', 'gstin', 'gst_type', 'pan',
        'billing_address', 'billing_city', 'billing_state', 'billing_pincode',
        'shipping_address', 'phone', 'email',
        'credit_limit', 'credit_days',
        'opening_balance', 'opening_balance_type',
        'is_active', 'custom_fields',
    ];

    protected $casts = [
        'credit_limit'          => 'decimal:2',
        'credit_days'           => 'integer',
        'opening_balance'       => 'decimal:2',
        'is_active'             => 'boolean',
        'custom_fields'         => 'array',
    ];
}
