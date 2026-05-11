<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Vendor;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class VendorController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $query = Vendor::query()->where('is_active', true);

        if ($search = $request->string('search')->trim()->toString()) {
            $query->where(function ($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                  ->orWhere('code', 'like', "%{$search}%")
                  ->orWhere('gstin', 'like', "%{$search}%")
                  ->orWhere('phone', 'like', "%{$search}%");
            });
        }

        if ($request->boolean('all')) {
            $vendors = $query->orderBy('name')->get(['id', 'name', 'code', 'gstin', 'gst_type']);
            return response()->json(['data' => $vendors, 'meta' => [], 'message' => 'OK']);
        }

        $vendors = $query->orderBy('name')->paginate($request->integer('per_page', 20));

        return response()->json([
            'data'    => $vendors->items(),
            'meta'    => [
                'current_page' => $vendors->currentPage(),
                'last_page'    => $vendors->lastPage(),
                'total'        => $vendors->total(),
            ],
            'message' => 'OK',
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate($this->rules());
        $vendor    = Vendor::create($validated);

        return response()->json(['data' => $vendor, 'meta' => [], 'message' => 'Vendor created.'], 201);
    }

    public function show(Vendor $vendor): JsonResponse
    {
        return response()->json(['data' => $vendor, 'meta' => [], 'message' => 'OK']);
    }

    public function update(Request $request, Vendor $vendor): JsonResponse
    {
        $validated = $request->validate($this->rules($vendor->id));
        $vendor->update($validated);

        return response()->json(['data' => $vendor->fresh(), 'meta' => [], 'message' => 'Vendor updated.']);
    }

    public function destroy(Vendor $vendor): JsonResponse
    {
        $vendor->delete();

        return response()->json(['data' => null, 'meta' => [], 'message' => 'Vendor deleted.']);
    }

    private function rules(?int $id = null): array
    {
        return [
            'name'                  => ['required', 'string', 'max:255'],
            'code'                  => ['nullable', 'string', 'max:30', Rule::unique('tenant.vendors', 'code')->ignore($id)->whereNull('deleted_at')],
            'gstin'                 => ['nullable', 'string', 'max:20'],
            'gst_type'              => ['nullable', Rule::in(['regular', 'composition', 'unregistered', 'sez', 'overseas'])],
            'pan'                   => ['nullable', 'string', 'max:20'],
            'address'               => ['nullable', 'string'],
            'city'                  => ['nullable', 'string', 'max:100'],
            'state'                 => ['nullable', 'string', 'max:100'],
            'pincode'               => ['nullable', 'string', 'max:10'],
            'phone'                 => ['nullable', 'string', 'max:20'],
            'email'                 => ['nullable', 'email', 'max:255'],
            'credit_limit'          => ['nullable', 'numeric', 'min:0'],
            'credit_days'           => ['nullable', 'integer', 'min:0'],
            'opening_balance'       => ['nullable', 'numeric', 'min:0'],
            'opening_balance_type'  => ['nullable', Rule::in(['dr', 'cr'])],
            'tds_applicable'        => ['nullable', 'boolean'],
            'tds_rate'              => ['nullable', 'numeric', 'min:0', 'max:100'],
            'is_active'             => ['nullable', 'boolean'],
            'custom_fields'         => ['nullable', 'array'],
        ];
    }

    public function search(Request $request): JsonResponse
    {
        $q = $request->string('q')->trim()->toString();
        $vendors = Vendor::where('is_active', true)
            ->where(function ($query) use ($q) {
                $query->where('name', 'like', "%{$q}%")
                      ->orWhere('code', 'like', "%{$q}%")
                      ->orWhere('gstin', 'like', "%{$q}%")
                      ->orWhere('phone', 'like', "%{$q}%");
            })
            ->limit(20)
            ->get(['id', 'name', 'code', 'gstin', 'gst_type', 'phone', 'state']);

        return response()->json(['data' => $vendors, 'meta' => [], 'message' => 'OK']);
    }
}

