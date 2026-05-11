<?php

namespace App\Services;

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Str;

class TenantProvisioningService
{
    /**
     * Create a new tenant: registers in central DB, creates the tenant DB,
     * runs tenant migrations, and seeds default data.
     *
     * @param  array{code: string, name: string, plan?: string} $data
     * @return object  The newly created tenant row
     * @throws \RuntimeException
     */
    public function provision(array $data): object
    {
        $code   = strtolower(trim($data['code']));
        $dbName = config('tenancy.tenant_db_prefix', 'hexbase_') . $code;

        // Validate code format
        if (! preg_match('/^[a-z][a-z0-9_]{2,29}$/', $code)) {
            throw new \InvalidArgumentException(
                'Tenant code must be 3–30 characters, start with a letter, and contain only a-z, 0-9, _'
            );
        }

        // Check uniqueness
        $exists = DB::connection('central')->table('tenants')->where('code', $code)->exists();
        if ($exists) {
            throw new \RuntimeException("Tenant with code '{$code}' already exists.");
        }

        // Create tenant DB
        DB::connection('central')->statement("CREATE DATABASE IF NOT EXISTS `{$dbName}` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci");

        // Switch tenant connection
        config(['database.connections.tenant.database' => $dbName]);
        DB::purge('tenant');

        // Run tenant migrations
        Artisan::call('migrate', [
            '--path'     => 'database/migrations/tenant',
            '--database' => 'tenant',
            '--force'    => true,
        ]);

        // Seed default roles/permissions and chart of accounts
        Artisan::call('db:seed', [
            '--class'    => \Database\Seeders\RolesAndPermissionsSeeder::class,
            '--database' => 'tenant',
            '--force'    => true,
        ]);

        Artisan::call('db:seed', [
            '--class'    => \Database\Seeders\ChartOfAccountsSeeder::class,
            '--database' => 'tenant',
            '--force'    => true,
        ]);

        // Register tenant in central DB
        $id = DB::connection('central')->table('tenants')->insertGetId([
            'code'       => $code,
            'name'       => $data['name'],
            'plan'       => $data['plan'] ?? 'basic',
            'is_active'  => true,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        return DB::connection('central')->table('tenants')->find($id);
    }

    /**
     * Deactivate a tenant (soft disable — does not drop DB).
     */
    public function deactivate(string $code): void
    {
        DB::connection('central')
            ->table('tenants')
            ->where('code', $code)
            ->update(['is_active' => false, 'updated_at' => now()]);
    }

    /**
     * Reactivate a previously deactivated tenant.
     */
    public function activate(string $code): void
    {
        DB::connection('central')
            ->table('tenants')
            ->where('code', $code)
            ->update(['is_active' => true, 'updated_at' => now()]);
    }
}
