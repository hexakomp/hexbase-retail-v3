<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Relations\BelongsTo;

/**
 * QuotationLine — line item on a quotation.
 *
 * @property int    $id
 * @property int    $quotation_id
 * @property int|null $product_id
 * @property string $description
 * @property float  $quantity
 * @property string $unit
 * @property float  $unit_price
 * @property float  $discount_percent
 * @property float  $discount_amount
 * @property float  $taxable_amount
 * @property int    $gst_rate
 * @property float  $cgst_rate
 * @property float  $sgst_rate
 * @property float  $igst_rate
 * @property float  $cgst_amount
 * @property float  $sgst_amount
 * @property float  $igst_amount
 * @property float  $total_amount
 * @property int    $sort_order
 */
class QuotationLine extends TenantModel
{
    public $timestamps = false;

    protected $table = 'quotation_lines';

    protected $fillable = [
        'quotation_id',
        'product_id',
        'description',
        'hsn_sac',
        'quantity',
        'unit',
        'unit_price',
        'discount_percent',
        'discount_amount',
        'taxable_amount',
        'gst_rate',
        'cgst_rate',
        'sgst_rate',
        'igst_rate',
        'cgst_amount',
        'sgst_amount',
        'igst_amount',
        'cess_rate',
        'cess_amount',
        'total_amount',
        'sort_order',
    ];

    protected $casts = [
        'quantity'        => 'float',
        'unit_price'      => 'float',
        'discount_percent' => 'float',
        'discount_amount' => 'float',
        'taxable_amount'  => 'float',
        'gst_rate'        => 'integer',
        'cgst_rate'       => 'float',
        'sgst_rate'       => 'float',
        'igst_rate'       => 'float',
        'cgst_amount'     => 'float',
        'sgst_amount'     => 'float',
        'igst_amount'     => 'float',
        'cess_rate'       => 'float',
        'cess_amount'     => 'float',
        'total_amount'    => 'float',
        'sort_order'      => 'integer',
    ];

    public function quotation(): BelongsTo
    {
        return $this->belongsTo(Quotation::class);
    }

    public function product(): BelongsTo
    {
        return $this->belongsTo(Product::class);
    }
}
