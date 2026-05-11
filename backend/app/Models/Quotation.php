<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

/**
 * Quotation — pre-sales quotation header.
 *
 * @property int    $id
 * @property int    $customer_id
 * @property string $quotation_number
 * @property string $quotation_date
 * @property string $validity_date
 * @property string $status  draft|sent|accepted|rejected|converted|expired
 * @property float  $taxable_amount
 * @property float  $cgst_amount
 * @property float  $sgst_amount
 * @property float  $igst_amount
 * @property float  $total_amount
 * @property string|null $narration
 * @property string|null $terms_conditions
 * @property int|null $converted_invoice_id
 * @property array|null $custom_fields
 */
class Quotation extends TenantModel
{
    use SoftDeletes;

    protected $table = 'quotations';

    protected $fillable = [
        'customer_id',
        'quotation_number',
        'quotation_date',
        'validity_date',
        'status',
        'place_of_supply',
        'taxable_amount',
        'cgst_amount',
        'sgst_amount',
        'igst_amount',
        'cess_amount',
        'discount_amount',
        'total_amount',
        'narration',
        'terms_conditions',
        'converted_invoice_id',
        'custom_fields',
    ];

    protected $casts = [
        'quotation_date'      => 'date',
        'validity_date'       => 'date',
        'taxable_amount'      => 'float',
        'cgst_amount'         => 'float',
        'sgst_amount'         => 'float',
        'igst_amount'         => 'float',
        'cess_amount'         => 'float',
        'discount_amount'     => 'float',
        'total_amount'        => 'float',
        'custom_fields'       => 'array',
    ];

    public function customer(): BelongsTo
    {
        return $this->belongsTo(Customer::class);
    }

    public function lines(): HasMany
    {
        return $this->hasMany(QuotationLine::class)->orderBy('sort_order');
    }

    public function convertedInvoice(): BelongsTo
    {
        return $this->belongsTo(SalesInvoice::class, 'converted_invoice_id');
    }

    public function isExpired(): bool
    {
        return $this->validity_date && $this->validity_date->isPast() && !in_array($this->status, ['converted', 'rejected']);
    }
}
