<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

/**
 * PurchaseInvoice — Vendor purchase invoice with ITC tracking.
 *
 * @property int    $id
 * @property string $invoice_number
 * @property string|null $vendor_invoice_number
 * @property string|null $vendor_invoice_date
 * @property string $invoice_date
 * @property string|null $due_date
 * @property int    $vendor_id
 * @property string|null $vendor_gstin
 * @property string $supply_type          intra|inter|import
 * @property bool   $reverse_charge
 * @property int|null $purchase_order_id
 * @property float  $subtotal
 * @property float  $discount_amount
 * @property float  $taxable_amount
 * @property float  $cgst_amount
 * @property float  $sgst_amount
 * @property float  $igst_amount
 * @property float  $cess_amount
 * @property float  $round_off
 * @property float  $total_amount
 * @property float  $paid_amount
 * @property float  $balance_amount
 * @property string $status               draft|confirmed|partially_paid|paid|cancelled
 * @property string|null $narration
 * @property string|null $notes
 * @property string|null $attachment_path
 * @property array|null  $custom_fields
 * @property int|null    $created_by
 */
class PurchaseInvoice extends TenantModel
{
    use SoftDeletes;

    protected $table = 'purchase_invoices';

    protected $fillable = [
        'invoice_number',
        'vendor_invoice_number',
        'vendor_invoice_date',
        'entry_date',
        'invoice_date',
        'due_date',
        'vendor_id',
        'vendor_gstin',
        'supply_type',
        'reverse_charge',
        'purchase_order_id',
        'subtotal',
        'discount_amount',
        'taxable_amount',
        'cgst_amount',
        'sgst_amount',
        'igst_amount',
        'cess_amount',
        'round_off',
        'total_amount',
        'paid_amount',
        'balance_amount',
        'status',
        'narration',
        'notes',
        'attachment_path',
        'custom_fields',
        'created_by',
    ];

    protected $casts = [
        'invoice_date'        => 'date',
        'vendor_invoice_date' => 'date',
        'entry_date'          => 'date',
        'due_date'            => 'date',
        'reverse_charge'      => 'boolean',
        'subtotal'            => 'float',
        'discount_amount'     => 'float',
        'taxable_amount'      => 'float',
        'cgst_amount'         => 'float',
        'sgst_amount'         => 'float',
        'igst_amount'         => 'float',
        'cess_amount'         => 'float',
        'round_off'           => 'float',
        'total_amount'        => 'float',
        'paid_amount'         => 'float',
        'balance_amount'      => 'float',
        'custom_fields'       => 'array',
    ];

    // ── Relationships ──────────────────────────────────────────────────────

    public function vendor(): BelongsTo
    {
        return $this->belongsTo(Vendor::class);
    }

    public function lines(): HasMany
    {
        return $this->hasMany(PurchaseInvoiceLine::class)->orderBy('sort_order');
    }

    public function createdBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    // ── Scopes ─────────────────────────────────────────────────────────────

    public function scopeSearch($query, ?string $term)
    {
        if (! $term) {
            return $query;
        }

        return $query->where(function ($q) use ($term) {
            $q->where('invoice_number', 'like', "%{$term}%")
              ->orWhere('vendor_invoice_number', 'like', "%{$term}%")
              ->orWhereHas('vendor', fn ($vq) => $vq->where('name', 'like', "%{$term}%"));
        });
    }

    public function scopeByStatus($query, ?string $status)
    {
        if (! $status) {
            return $query;
        }

        return $query->where('status', $status);
    }
}
