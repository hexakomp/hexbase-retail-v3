<?php

namespace App\Models;

class BankAccount extends TenantModel
{
    protected $fillable = [
        'name',
        'account_number',
        'ifsc',
        'bank_name',
        'branch',
        'is_default',
        'is_active',
    ];

    protected $casts = [
        'is_default' => 'boolean',
        'is_active'  => 'boolean',
    ];
}
