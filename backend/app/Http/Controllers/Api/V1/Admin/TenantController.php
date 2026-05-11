<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Services\TenantProvisioningService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;

class TenantController extends Controller
{
    public function __construct(private readonly TenantProvisioningService $provisioning)
    {}

    public function index(Request $request): JsonResponse
    {
        $tenants = DB::connection('central')
            ->table('tenants')
            ->orderBy('name')
            ->paginate($request->integer('per_page', 20));

        return response()->json([
            'data'    => $tenants->items(),
            'meta'    => [
                'current_page' => $tenants->currentPage(),
                'last_page'    => $tenants->lastPage(),
                'total'        => $tenants->total(),
            ],
            'message' => 'OK',
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'code' => ['required', 'string', 'max:30', 'unique:central.tenants,code'],
            'name' => ['required', 'string', 'max:255'],
            'plan' => ['nullable', 'string', Rule::in(['basic', 'pro', 'enterprise'])],
        ]);

        try {
            $tenant = $this->provisioning->provision($validated);
        } catch (\Exception $e) {
            return response()->json([
                'data'    => null,
                'meta'    => [],
                'message' => $e->getMessage(),
            ], 422);
        }

        return response()->json([
            'data'    => $tenant,
            'meta'    => [],
            'message' => 'Tenant provisioned successfully.',
        ], 201);
    }

    public function show(string $code): JsonResponse
    {
        $tenant = DB::connection('central')
            ->table('tenants')
            ->where('code', $code)
            ->first();

        if (! $tenant) {
            return response()->json(['data' => null, 'meta' => [], 'message' => 'Tenant not found.'], 404);
        }

        return response()->json(['data' => $tenant, 'meta' => [], 'message' => 'OK']);
    }

    public function update(Request $request, string $code): JsonResponse
    {
        $validated = $request->validate([
            'name'      => ['sometimes', 'string', 'max:255'],
            'plan'      => ['sometimes', 'string', Rule::in(['basic', 'pro', 'enterprise'])],
            'is_active' => ['sometimes', 'boolean'],
        ]);

        $updated = DB::connection('central')
            ->table('tenants')
            ->where('code', $code)
            ->update(array_merge($validated, ['updated_at' => now()]));

        if (! $updated) {
            return response()->json(['data' => null, 'meta' => [], 'message' => 'Tenant not found.'], 404);
        }

        return response()->json(['data' => null, 'meta' => [], 'message' => 'Tenant updated.']);
    }

    public function destroy(string $code): JsonResponse
    {
        try {
            $this->provisioning->deactivate($code);
        } catch (\Exception $e) {
            return response()->json(['data' => null, 'meta' => [], 'message' => $e->getMessage()], 422);
        }

        return response()->json(['data' => null, 'meta' => [], 'message' => 'Tenant deactivated.']);
    }
}
