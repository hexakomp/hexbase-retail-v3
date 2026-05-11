<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Customer;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class CustomerController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $query = Customer::query()->where('is_active', true);

        if ($search = $request->string('search')->trim()->toString()) {
            $query->where(function ($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                  ->orWhere('code', 'like', "%{$search}%")
                  ->orWhere('gstin', 'like', "%{$search}%")
                  ->orWhere('phone', 'like', "%{$search}%");
            });
        }

        if ($request->boolean('all')) {
            $customers = $query->orderBy('name')->get(['id', 'name', 'code', 'gstin', 'gst_type']);
            return response()->json(['data' => $customers, 'meta' => [], 'message' => 'OK']);
        }

        $customers = $query->orderBy('name')->paginate($request->integer('per_page', 20));

        return response()->json([
            'data'    => $customers->items(),
            'meta'    => [
                'current_page' => $customers->currentPage(),
                'last_page'    => $customers->lastPage(),
                'total'        => $customers->total(),
            ],
            'message' => 'OK',
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate($this->rules());
        $customer  = Customer::create($validated);

        return response()->json(['data' => $customer, 'meta' => [], 'message' => 'Customer created.'], 201);
    }

    public function show(Customer $customer): JsonResponse
    {
        return response()->json(['data' => $customer, 'meta' => [], 'message' => 'OK']);
    }

    public function update(Request $request, Customer $customer): JsonResponse
    {
        $validated = $request->validate($this->rules($customer->id));
        $customer->update($validated);

        return response()->json(['data' => $customer->fresh(), 'meta' => [], 'message' => 'Customer updated.']);
    }

    public function destroy(Customer $customer): JsonResponse
    {
        $customer->delete();

        return response()->json(['data' => null, 'meta' => [], 'message' => 'Customer deleted.']);
    }

    private function rules(?int $id = null): array
    {
        return [
            'name'                  => ['required', 'string', 'max:255'],
            'code'                  => ['nullable', 'string', 'max:30', Rule::unique('tenant.customers', 'code')->ignore($id)->whereNull('deleted_at')],
            'gstin'                 => ['nullable', 'string', 'max:20'],
            'gst_type'              => ['nullable', Rule::in(['regular', 'composition', 'unregistered', 'sez', 'overseas'])],
            'pan'                   => ['nullable', 'string', 'max:20'],
            'billing_address'       => ['nullable', 'string'],
            'billing_city'          => ['nullable', 'string', 'max:100'],
            'billing_state'         => ['nullable', 'string', 'max:100'],
            'billing_pincode'       => ['nullable', 'string', 'max:10'],
            'shipping_address'      => ['nullable', 'string'],
            'phone'                 => ['nullable', 'string', 'max:20'],
            'email'                 => ['nullable', 'email', 'max:255'],
            'credit_limit'          => ['nullable', 'numeric', 'min:0'],
            'credit_days'           => ['nullable', 'integer', 'min:0'],
            'opening_balance'       => ['nullable', 'numeric', 'min:0'],
            'opening_balance_type'  => ['nullable', Rule::in(['dr', 'cr'])],
            'is_active'             => ['nullable', 'boolean'],
            'custom_fields'         => ['nullable', 'array'],
        ];
    }

    public function search(Request $request): JsonResponse
    {
        $q = $request->string('q')->trim()->toString();
        $customers = Customer::where('is_active', true)
            ->where(function ($query) use ($q) {
                $query->where('name', 'like', "%{$q}%")
                      ->orWhere('code', 'like', "%{$q}%")
                      ->orWhere('gstin', 'like', "%{$q}%")
                      ->orWhere('phone', 'like', "%{$q}%");
            })
            ->limit(20)
            ->get(['id', 'name', 'code', 'gstin', 'gst_type', 'phone', 'billing_state']);

        return response()->json(['data' => $customers, 'meta' => [], 'message' => 'OK']);
    }
}

