<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Tenancy Configuration
    |--------------------------------------------------------------------------
    |
    | This file contains the configuration for the multi-tenant setup.
    | Tenants are resolved from subdomain or X-Tenant-Code header.
    | Each tenant gets its own database (hexbase_{code}).
    |
    */

    'central_connection' => env('CENTRAL_DB_CONNECTION', 'central'),

    'tenant_connection' => env('TENANT_DB_CONNECTION', 'tenant'),

    'resolution' => [
        'subdomain_pattern' => env('TENANT_SUBDOMAIN_PATTERN', '.hexbase.in'),
        'header'            => 'X-Tenant-Code',
    ],

    'tenant_db_prefix' => env('TENANT_DB_PREFIX', 'hexbase_'),

    'tenant_db_host'     => env('TENANT_DB_HOST', env('DB_HOST', '127.0.0.1')),
    'tenant_db_port'     => env('TENANT_DB_PORT', env('DB_PORT', '3306')),
    'tenant_db_username' => env('TENANT_DB_USERNAME', env('DB_USERNAME', 'root')),
    'tenant_db_password' => env('TENANT_DB_PASSWORD', env('DB_PASSWORD', '')),

    /*
    | Migrations path for per-tenant schema.
    */
    'migrations_path' => database_path('migrations/tenant'),

];
