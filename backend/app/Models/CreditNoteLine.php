<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Relations\BelongsTo;

class CreditNoteLine extends TenantModel
{
    public $timestamps = false;

    protected $table = 'credit_note_lines';

    protected $fillable = [
        'credit_note_id',
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
        'tax_amount',
        'line_total',
        'sort_order',
    ];

    protected $casts = [
        'quantity'       => 'float',
        'unit_price'     => 'float',
        'discount_pct'   => 'float',
        'discount_amount'=> 'float',
        'taxable_amount' => 'float',
        'gst_rate'       => 'integer',
        'cgst_rate'      => 'float',
        'cgst_amount'    => 'float',
        'sgst_rate'      => 'float',
        'sgst_amount'    => 'float',
        'igst_rate'      => 'float',
        'igst_amount'    => 'float',
        'tax_amount'     => 'float',
        'line_total'     => 'float',
    ];

    public function product(): BelongsTo
    {
        return $this->belongsTo(Product::class);
    }

    public function creditNote(): BelongsTo
    {
        return $this->belongsTo(CreditNote::class);
    }
}
