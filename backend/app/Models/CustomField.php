<?php

namespace App\Models;

use Illuminate\Database\Eloquent\SoftDeletes;

class CustomField extends TenantModel
{
    use SoftDeletes;

    protected $table = 'custom_fields';

    protected $fillable = [
        'entity_type',
        'field_name',
        'field_label',
        'field_type',
        'options',
        'is_required',
        'sort_order',
    ];

    protected $casts = [
        'options'     => 'array',
        'is_required' => 'boolean',
        'sort_order'  => 'integer',
    ];
}
