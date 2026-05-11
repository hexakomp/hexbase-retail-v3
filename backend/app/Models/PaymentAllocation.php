<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Relations\BelongsTo;

class PaymentAllocation extends TenantModel
{
    public $timestamps = false;

    protected $table = 'payment_allocations';

    protected $fillable = [
        'payment_id',
        'purchase_invoice_id',
        'allocated_amount',
    ];

    protected function casts(): array
    {
        return [
            'allocated_amount' => 'float',
        ];
    }

    // ── Relationships ────────────────────────────────────────────────────────

    public function payment(): BelongsTo
    {
        return $this->belongsTo(Payment::class);
    }

    public function purchaseInvoice(): BelongsTo
    {
        return $this->belongsTo(PurchaseInvoice::class);
    }
}
