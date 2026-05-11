<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

/**
 * SalesInvoice — GST-compliant sales invoice (one-per-tenant DB).
 *
 * @property int    $id
 * @property string $invoice_number
 * @property string $invoice_date
 * @property string|null $due_date
 * @property int    $customer_id
 * @property string|null $customer_gstin
 * @property string $supply_type        intra|inter|export
 * @property string $invoice_type       b2b|b2c|export
 * @property string|null $place_of_supply  2-char state code
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
 * @property string $status             draft|confirmed|partially_paid|paid|cancelled
 * @property string|null $narration
 * @property string|null $notes
 * @property string|null $terms_conditions
 * @property string|null $payment_terms
 * @property string|null $pdf_path
 * @property array|null  $custom_fields
 * @property int|null    $created_by
 */
class SalesInvoice extends TenantModel
{
    use SoftDeletes;

    protected $table = 'sales_invoices';

    protected $fillable = [
        'invoice_number',
        'invoice_date',
        'due_date',
        'customer_id',
        'customer_gstin',
        'supply_type',
        'invoice_type',
        'place_of_supply',
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
        'terms_conditions',
        'payment_terms',
        'pdf_path',
        'custom_fields',
        'created_by',
    ];

    protected $casts = [
        'invoice_date'    => 'date',
        'due_date'        => 'date',
        'subtotal'        => 'float',
        'discount_amount' => 'float',
        'taxable_amount'  => 'float',
        'cgst_amount'     => 'float',
        'sgst_amount'     => 'float',
        'igst_amount'     => 'float',
        'cess_amount'     => 'float',
        'round_off'       => 'float',
        'total_amount'    => 'float',
        'paid_amount'     => 'float',
        'balance_amount'  => 'float',
        'custom_fields'   => 'array',
    ];

    // ── Relationships ──────────────────────────────────────────────────────

    public function customer(): BelongsTo
    {
        return $this->belongsTo(Customer::class);
    }

    public function lines(): HasMany
    {
        return $this->hasMany(SalesInvoiceLine::class)->orderBy('sort_order');
    }

    public function createdBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    // ── Scopes ────────────────────────────────────────────────────────────

    public function scopeSearch($query, ?string $term)
    {
        if (! $term) {
            return $query;
        }
        return $query->where(function ($q) use ($term) {
            $q->where('invoice_number', 'like', "%{$term}%")
              ->orWhereHas('customer', fn ($cq) => $cq->where('name', 'like', "%{$term}%"));
        });
    }

    public function scopeByStatus($query, ?string $status)
    {
        return $status ? $query->where('status', $status) : $query;
    }
}
