<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Relations\BelongsTo;

/**
 * InventoryMovement — Records each stock movement for a product.
 *
 * @property int    $id
 * @property int    $product_id
 * @property string $movement_type  purchase|sale|adjustment|opening
 * @property float  $quantity       positive for in, negative for out
 * @property float  $unit_cost
 * @property string $reference      invoice number or reference
 * @property string|null $narration
 * @property int|null $source_id     FK to the source document
 * @property string|null $source_type  polymorphic type
 * @property string $movement_date
 * @property int|null $created_by
 */
class InventoryMovement extends TenantModel
{
    public $timestamps = false;

    protected $table = 'inventory_movements';

    protected $fillable = [
        'product_id',
        'movement_type',
        'quantity',
        'unit_cost',
        'reference',
        'narration',
        'source_id',
        'source_type',
        'movement_date',
        'created_by',
    ];

    protected $casts = [
        'quantity'      => 'float',
        'unit_cost'     => 'float',
        'movement_date' => 'date',
    ];

    public function product(): BelongsTo
    {
        return $this->belongsTo(Product::class);
    }
}
