<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Relations\BelongsTo;

/**
 * SalesInvoiceLine — One line item on a sales invoice.
 *
 * @property int    $id
 * @property int    $sales_invoice_id
 * @property int    $product_id
 * @property string|null $description
 * @property string|null $hsn_sac
 * @property float  $quantity
 * @property string $unit
 * @property float  $unit_price
 * @property float  $discount_pct
 * @property float  $discount_amount
 * @property float  $taxable_amount
 * @property float  $gst_rate
 * @property float  $cgst_rate
 * @property float  $cgst_amount
 * @property float  $sgst_rate
 * @property float  $sgst_amount
 * @property float  $igst_rate
 * @property float  $igst_amount
 * @property float  $cess_rate
 * @property float  $cess_amount
 * @property float  $line_total
 * @property int    $sort_order
 * @property array|null $custom_columns
 */
class SalesInvoiceLine extends TenantModel
{
    public $timestamps = false;

    protected $table = 'sales_invoice_lines';

    protected $fillable = [
        'sales_invoice_id',
        'product_id',
        'description',
        'hsn_sac',
        'quantity',
        'unit',
        'unit_price',
        'discount_pct',
        'discount_amount',
        'taxable_amount',
        'gst_rate',
        'cgst_rate',
        'cgst_amount',
        'sgst_rate',
        'sgst_amount',
        'igst_rate',
        'igst_amount',
        'cess_rate',
        'cess_amount',
        'line_total',
        'sort_order',
        'custom_columns',
    ];

    protected $casts = [
        'quantity'        => 'float',
        'unit_price'      => 'float',
        'discount_pct'    => 'float',
        'discount_amount' => 'float',
        'taxable_amount'  => 'float',
        'gst_rate'        => 'float',
        'cgst_rate'       => 'float',
        'cgst_amount'     => 'float',
        'sgst_rate'       => 'float',
        'sgst_amount'     => 'float',
        'igst_rate'       => 'float',
        'igst_amount'     => 'float',
        'cess_rate'       => 'float',
        'cess_amount'     => 'float',
        'line_total'      => 'float',
        'custom_columns'  => 'array',
    ];

    // ── Relationships ──────────────────────────────────────────────────────

    public function salesInvoice(): BelongsTo
    {
        return $this->belongsTo(SalesInvoice::class);
    }

    public function product(): BelongsTo
    {
        return $this->belongsTo(Product::class);
    }
}
