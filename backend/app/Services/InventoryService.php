<?php

namespace App\Services;

use App\Models\InventoryMovement;
use App\Models\Product;
use Illuminate\Support\Facades\DB;

/**
 * InventoryService — WAC tracking, stock summary, adjustments, reorder alerts.
 */
class InventoryService
{
    /**
     * Stock summary for all products or a specific product.
     */
    public function stockSummary(?int $productId = null, ?string $warehouseId = null): array
    {
        $query = DB::connection('tenant')
            ->table('products as p')
            ->whereNull('p.deleted_at')
            ->select([
                'p.id',
                'p.name',
                'p.sku',
                'p.hsn_code',
                'p.unit',
                'p.current_stock',
                'p.reorder_level',
                'p.weighted_average_cost',
                DB::raw('ROUND(p.current_stock * p.weighted_average_cost, 2) as stock_value'),
                DB::raw('CASE WHEN p.current_stock <= p.reorder_level THEN 1 ELSE 0 END as reorder_alert'),
            ]);

        if ($productId) {
            $query->where('p.id', $productId);
        }

        $rows = $query->orderBy('p.name')->get();

        return [
            'records'                => $rows->map(fn ($r) => [
                'id'                   => $r->id,
                'name'                 => $r->name,
                'sku'                  => $r->sku,
                'hsn_code'             => $r->hsn_code,
                'unit'                 => $r->unit,
                'current_stock'        => number_format($r->current_stock, 3, '.', ''),
                'reorder_level'        => number_format($r->reorder_level, 3, '.', ''),
                'weighted_average_cost' => number_format($r->weighted_average_cost, 2, '.', ''),
                'stock_value'          => number_format($r->stock_value, 2, '.', ''),
                'reorder_alert'        => (bool) $r->reorder_alert,
            ])->values()->toArray(),
            'total_stock_value'      => number_format($rows->sum('stock_value'), 2, '.', ''),
            'reorder_alert_count'    => $rows->where('reorder_alert', 1)->count(),
        ];
    }

    /**
     * Get movements for a product with optional date range filter.
     */
    public function movements(int $productId, ?string $fromDate = null, ?string $toDate = null, int $page = 1, int $perPage = 50): array
    {
        $query = InventoryMovement::where('product_id', $productId)
            ->orderBy('movement_date', 'desc')
            ->orderBy('id', 'desc');

        if ($fromDate) {
            $query->where('movement_date', '>=', $fromDate);
        }
        if ($toDate) {
            $query->where('movement_date', '<=', $toDate);
        }

        $total  = $query->count();
        $offset = ($page - 1) * $perPage;
        $rows   = $query->skip($offset)->take($perPage)->get();

        return [
            'product_id' => $productId,
            'total'      => $total,
            'per_page'   => $perPage,
            'page'       => $page,
            'last_page'  => max(1, (int) ceil($total / $perPage)),
            'records'    => $rows->map(fn ($r) => [
                'id'            => $r->id,
                'movement_type' => $r->movement_type,
                'quantity'      => number_format($r->quantity, 3, '.', ''),
                'unit_cost'     => number_format($r->unit_cost, 2, '.', ''),
                'reference'     => $r->reference,
                'narration'     => $r->narration,
                'movement_date' => $r->movement_date?->toDateString(),
            ])->toArray(),
        ];
    }

    /**
     * Stock adjustment — update stock and recalculate WAC.
     *
     * @param  int    $productId
     * @param  float  $adjustedQty   New absolute quantity (physical count)
     * @param  float  $adjustedCost  Unit cost for WAC recalculation (optional, uses WAC if not provided)
     * @param  string $narration
     * @param  int    $createdBy
     */
    public function adjust(int $productId, float $adjustedQty, ?float $adjustedCost, string $narration, int $createdBy): Product
    {
        return DB::connection('tenant')->transaction(function () use ($productId, $adjustedQty, $adjustedCost, $narration, $createdBy) {
            /** @var Product $product */
            $product = Product::findOrFail($productId);

            $diff = $adjustedQty - $product->current_stock;

            $newWac = $adjustedCost ?? $product->weighted_average_cost;

            // Record the movement
            InventoryMovement::create([
                'product_id'    => $productId,
                'movement_type' => 'adjustment',
                'quantity'      => $diff,
                'unit_cost'     => $newWac,
                'reference'     => 'ADJ-' . date('YmdHis'),
                'narration'     => $narration,
                'movement_date' => now()->toDateString(),
                'created_by'    => $createdBy,
            ]);

            // Recalculate WAC using total value approach
            if ($adjustedQty > 0) {
                $existingValue = $product->current_stock * $product->weighted_average_cost;
                $addedValue    = max(0, $diff) * $newWac;
                $newWac        = ($existingValue + $addedValue) / $adjustedQty;
            }

            $product->update([
                'current_stock'        => $adjustedQty,
                'weighted_average_cost' => round($newWac, 6),
            ]);

            return $product->fresh();
        });
    }

    /**
     * Deduct stock on sale and update WAC.
     *
     * @param  int   $productId
     * @param  float $quantity
     * @param  string $reference
     * @param  int   $sourceId
     * @param  string $sourceType
     */
    public function deductStock(int $productId, float $quantity, string $reference, int $sourceId, string $sourceType): void
    {
        DB::connection('tenant')->transaction(function () use ($productId, $quantity, $reference, $sourceId, $sourceType) {
            /** @var Product $product */
            $product = Product::lockForUpdate()->findOrFail($productId);

            InventoryMovement::create([
                'product_id'    => $productId,
                'movement_type' => 'sale',
                'quantity'      => -abs($quantity),
                'unit_cost'     => $product->weighted_average_cost,
                'reference'     => $reference,
                'source_id'     => $sourceId,
                'source_type'   => $sourceType,
                'movement_date' => now()->toDateString(),
            ]);

            $product->decrement('current_stock', abs($quantity));
        });
    }

    /**
     * Add stock on purchase and recalculate WAC.
     *
     * @param  int    $productId
     * @param  float  $quantity
     * @param  float  $unitCost
     * @param  string $reference
     * @param  int    $sourceId
     * @param  string $sourceType
     */
    public function addStock(int $productId, float $quantity, float $unitCost, string $reference, int $sourceId, string $sourceType): void
    {
        DB::connection('tenant')->transaction(function () use ($productId, $quantity, $unitCost, $reference, $sourceId, $sourceType) {
            /** @var Product $product */
            $product = Product::lockForUpdate()->findOrFail($productId);

            InventoryMovement::create([
                'product_id'    => $productId,
                'movement_type' => 'purchase',
                'quantity'      => abs($quantity),
                'unit_cost'     => $unitCost,
                'reference'     => $reference,
                'source_id'     => $sourceId,
                'source_type'   => $sourceType,
                'movement_date' => now()->toDateString(),
            ]);

            // Weighted average cost recalculation
            $existingValue = $product->current_stock * $product->weighted_average_cost;
            $addedValue    = $quantity * $unitCost;
            $newQty        = $product->current_stock + $quantity;
            $newWac        = $newQty > 0 ? ($existingValue + $addedValue) / $newQty : $unitCost;

            $product->update([
                'current_stock'        => $newQty,
                'weighted_average_cost' => round($newWac, 6),
            ]);
        });
    }
}
