<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ReceiptAllocation extends TenantModel
{
    protected $fillable = [
        'receipt_id',
        'sales_invoice_id',
        'allocated_amount',
    ];

    protected $casts = [
        'allocated_amount' => 'float',
    ];

    public function receipt(): BelongsTo
    {
        return $this->belongsTo(Receipt::class);
    }

    public function salesInvoice(): BelongsTo
    {
        return $this->belongsTo(SalesInvoice::class);
    }
}
