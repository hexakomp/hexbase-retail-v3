<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Product;
use App\Services\InventoryService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class ProductController extends Controller
{
    public function __construct(private InventoryService $inventoryService) {}

    public function index(Request $request): JsonResponse
    {
        $query = Product::query()->where('is_active', true);

        if ($search = $request->string('search')->trim()->toString()) {
            $query->where(function ($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                  ->orWhere('code', 'like', "%{$search}%")
                  ->orWhere('sku', 'like', "%{$search}%")
                  ->orWhere('hsn_sac', 'like', "%{$search}%");
            });
        }

        if ($search = $request->string('type')->trim()->toString()) {
            $query->where('type', $request->type);
        }

        if ($request->boolean('all')) {
            $products = $query->orderBy('name')
                ->get(['id', 'name', 'code', 'sku', 'hsn_sac', 'type', 'unit', 'sale_price', 'gst_rate']);
            return response()->json(['data' => $products, 'meta' => [], 'message' => 'OK']);
        }

        $products = $query->orderBy('name')->paginate($request->integer('per_page', 20));

        return response()->json([
            'data'    => $products->items(),
            'meta'    => [
                'current_page' => $products->currentPage(),
                'last_page'    => $products->lastPage(),
                'total'        => $products->total(),
            ],
            'message' => 'OK',
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate($this->rules());
        $product   = Product::create($validated);

        return response()->json(['data' => $product, 'meta' => [], 'message' => 'Product created.'], 201);
    }

    public function show(Product $product): JsonResponse
    {
        return response()->json(['data' => $product, 'meta' => [], 'message' => 'OK']);
    }

    public function update(Request $request, Product $product): JsonResponse
    {
        $validated = $request->validate($this->rules($product->id));
        $product->update($validated);

        return response()->json(['data' => $product->fresh(), 'meta' => [], 'message' => 'Product updated.']);
    }

    public function destroy(Product $product): JsonResponse
    {
        $product->delete();

        return response()->json(['data' => null, 'meta' => [], 'message' => 'Product deleted.']);
    }

    private function rules(?int $id = null): array
    {
        return [
            'name'            => ['required', 'string', 'max:255'],
            'code'            => ['nullable', 'string', 'max:50', Rule::unique('tenant.products', 'code')->ignore($id)->whereNull('deleted_at')],
            'sku'             => ['nullable', 'string', 'max:50', Rule::unique('tenant.products', 'sku')->ignore($id)->whereNull('deleted_at')],
            'hsn_sac'         => ['nullable', 'string', 'max:10'],
            'type'            => ['nullable', Rule::in(['goods', 'service'])],
            'unit'            => ['nullable', 'string', 'max:20'],
            'sale_price'      => ['nullable', 'numeric', 'min:0'],
            'purchase_price'  => ['nullable', 'numeric', 'min:0'],
            'mrp'             => ['nullable', 'numeric', 'min:0'],
            'gst_rate'        => ['nullable', 'integer', Rule::in([0, 5, 12, 18, 28])],
            'cess_rate'       => ['nullable', 'integer', 'min:0', 'max:100'],
            'track_inventory' => ['nullable', 'boolean'],
            'opening_stock'   => ['nullable', 'numeric', 'min:0'],
            'reorder_level'   => ['nullable', 'numeric', 'min:0'],
            'is_active'       => ['nullable', 'boolean'],
            'custom_fields'   => ['nullable', 'array'],
        ];
    }

    public function search(Request $request): JsonResponse
    {
        $search = $request->string('q')->trim()->toString();
        $products = Product::where('is_active', true)
            ->where(function ($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                  ->orWhere('sku', 'like', "%{$search}%")
                  ->orWhere('code', 'like', "%{$search}%");
            })
            ->limit(20)
            ->get(['id', 'name', 'code', 'sku', 'hsn_sac', 'unit', 'sale_price', 'gst_rate', 'current_stock']);

        return response()->json(['data' => $products, 'meta' => [], 'message' => 'OK']);
    }

    public function stockSummary(Request $request): JsonResponse
    {
        $data = $this->inventoryService->stockSummary();
        return response()->json(['data' => $data, 'meta' => [], 'message' => 'OK']);
    }

    public function movements(Request $request, Product $product): JsonResponse
    {
        $data = $this->inventoryService->movements(
            $product->id,
            $request->string('from_date')->toString() ?: null,
            $request->string('to_date')->toString() ?: null,
            $request->integer('page', 1),
            $request->integer('per_page', 50)
        );

        return response()->json([
            'data'    => $data['records'],
            'meta'    => [
                'total'      => $data['total'],
                'per_page'   => $data['per_page'],
                'page'       => $data['page'],
                'last_page'  => $data['last_page'],
                'product_id' => $data['product_id'],
            ],
            'message' => 'OK',
        ]);
    }

    public function stockAdjustment(Request $request, Product $product): JsonResponse
    {
        $validated = $request->validate([
            'adjusted_qty'  => ['required', 'numeric', 'min:0'],
            'adjusted_cost' => ['nullable', 'numeric', 'min:0'],
            'narration'     => ['required', 'string', 'max:500'],
        ]);

        $updated = $this->inventoryService->adjust(
            $product->id,
            (float) $validated['adjusted_qty'],
            isset($validated['adjusted_cost']) ? (float) $validated['adjusted_cost'] : null,
            $validated['narration'],
            $request->user()->id
        );

        return response()->json(['data' => $updated, 'meta' => [], 'message' => 'Stock adjusted.']);
    }
}

