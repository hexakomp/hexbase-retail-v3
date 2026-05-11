<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Config;
use Illuminate\Support\Facades\DB;
use Symfony\Component\HttpFoundation\Response;

class TenantResolver
{
    public function handle(Request $request, Closure $next): Response
    {
        $tenantCode = $this->resolveTenantCode($request);

        if (! $tenantCode) {
            return response()->json([
                'data'    => null,
                'meta'    => [],
                'message' => 'Tenant code is required (X-Tenant-Code header or subdomain).',
            ], 400);
        }

        // Look up tenant in central DB
        $tenant = DB::connection('central')
            ->table('tenants')
            ->where('code', $tenantCode)
            ->where('is_active', true)
            ->first();

        if (! $tenant) {
            return response()->json([
                'data'    => null,
                'meta'    => [],
                'message' => 'Tenant not found or inactive.',
            ], 404);
        }

        // Switch tenant DB connection at runtime
        $dbName = config('tenancy.tenant_db_prefix') . $tenantCode;

        Config::set('database.connections.tenant.database', $dbName);
        Config::set('database.connections.tenant.host', $tenant->db_host ?? config('database.connections.tenant.host'));
        Config::set('database.connections.tenant.username', $tenant->db_username ?? config('database.connections.tenant.username'));
        Config::set('database.connections.tenant.password', $tenant->db_password ?? config('database.connections.tenant.password'));

        // Purge cached connection so new config is used
        DB::purge('tenant');

        // Bind tenant model for downstream usage
        app()->instance('tenant', $tenant);

        return $next($request);
    }

    private function resolveTenantCode(Request $request): ?string
    {
        // 1. Try header first
        $code = $request->header(config('tenancy.resolution.header', 'X-Tenant-Code'));
        if ($code) {
            return strtolower(trim($code));
        }

        // 2. Try subdomain resolution
        $host = $request->getHost();
        $pattern = config('tenancy.resolution.subdomain_pattern', '/^([a-z0-9-]+)\./');
        if (preg_match($pattern, $host, $matches)) {
            $sub = $matches[1];
            // Exclude common non-tenant subdomains
            if (! in_array($sub, ['www', 'api', 'admin', 'app'], true)) {
                return strtolower($sub);
            }
        }

        return null;
    }
}
