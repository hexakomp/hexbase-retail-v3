<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\SoftDeletes;

class PdfTemplate extends TenantModel
{
    use SoftDeletes;

    protected $table = 'pdf_templates';

    protected $fillable = [
        'name',
        'document_type',
        'template_html',
        'is_default',
        'created_by',
    ];

    protected $casts = [
        'is_default' => 'boolean',
    ];

    public function createdBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    public function scopeForType($query, string $documentType)
    {
        return $query->where('document_type', $documentType);
    }

    public function scopeDefault($query)
    {
        return $query->where('is_default', true);
    }
}
