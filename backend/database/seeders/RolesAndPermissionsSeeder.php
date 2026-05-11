<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Spatie\Permission\Models\Permission;
use Spatie\Permission\Models\Role;
use Spatie\Permission\PermissionRegistrar;

class RolesAndPermissionsSeeder extends Seeder
{
    public function run(): void
    {
        // Clear cached roles/permissions
        app()[PermissionRegistrar::class]->forgetCachedPermissions();

        // Define all permissions
        $permissions = [
            // Dashboard
            'dashboard.view',

            // Customers
            'customers.view', 'customers.create', 'customers.edit', 'customers.delete',

            // Vendors
            'vendors.view', 'vendors.create', 'vendors.edit', 'vendors.delete',

            // Products
            'products.view', 'products.create', 'products.edit', 'products.delete',

            // Sales Invoices
            'sales_invoices.view', 'sales_invoices.create', 'sales_invoices.edit',
            'sales_invoices.delete', 'sales_invoices.confirm', 'sales_invoices.pdf',

            // Quotations
            'quotations.view', 'quotations.create', 'quotations.edit',
            'quotations.delete', 'quotations.convert',

            // Purchase Invoices
            'purchase_invoices.view', 'purchase_invoices.create', 'purchase_invoices.edit',
            'purchase_invoices.delete', 'purchase_invoices.confirm',

            // Receipts
            'receipts.view', 'receipts.create', 'receipts.edit', 'receipts.delete', 'receipts.confirm',

            // Payments
            'payments.view', 'payments.create', 'payments.edit', 'payments.delete', 'payments.confirm',

            // Reports
            'reports.gst', 'reports.financial', 'reports.inventory', 'reports.receivable', 'reports.payable',

            // Settings
            'settings.view', 'settings.edit',

            // Admin: User management
            'users.view', 'users.create', 'users.edit', 'users.delete',
            'users.assign_roles',

            // Admin: Tenant provisioning
            'tenants.view', 'tenants.create', 'tenants.edit', 'tenants.delete',
        ];

        foreach ($permissions as $permission) {
            Permission::firstOrCreate(['name' => $permission, 'guard_name' => 'web']);
        }

        // Define roles with their permissions
        $rolePermissions = [
            'admin' => $permissions, // All permissions

            'acc' => [
                'dashboard.view',
                'customers.view', 'customers.create', 'customers.edit',
                'vendors.view', 'vendors.create', 'vendors.edit',
                'products.view', 'products.create', 'products.edit',
                'sales_invoices.view', 'sales_invoices.create', 'sales_invoices.edit',
                'sales_invoices.confirm', 'sales_invoices.pdf',
                'quotations.view', 'quotations.create', 'quotations.edit', 'quotations.convert',
                'purchase_invoices.view', 'purchase_invoices.create', 'purchase_invoices.edit',
                'purchase_invoices.confirm',
                'receipts.view', 'receipts.create', 'receipts.edit', 'receipts.confirm',
                'payments.view', 'payments.create', 'payments.edit', 'payments.confirm',
                'reports.gst', 'reports.financial', 'reports.inventory',
                'reports.receivable', 'reports.payable',
                'settings.view',
            ],

            'billing' => [
                'dashboard.view',
                'customers.view',
                'products.view',
                'sales_invoices.view', 'sales_invoices.create', 'sales_invoices.edit',
                'sales_invoices.pdf',
                'quotations.view', 'quotations.create', 'quotations.edit', 'quotations.convert',
                'receipts.view', 'receipts.create',
                'reports.receivable',
            ],

            'view' => [
                'dashboard.view',
                'customers.view',
                'vendors.view',
                'products.view',
                'sales_invoices.view',
                'quotations.view',
                'purchase_invoices.view',
                'receipts.view',
                'payments.view',
                'reports.gst', 'reports.financial', 'reports.inventory',
                'reports.receivable', 'reports.payable',
            ],
        ];

        foreach ($rolePermissions as $roleName => $rolePerms) {
            $role = Role::firstOrCreate(['name' => $roleName, 'guard_name' => 'web']);
            $role->syncPermissions($rolePerms);
        }

        // Super-admin gets all permissions via Spatie's wildcard (set in config)
        Role::firstOrCreate(['name' => 'super-admin', 'guard_name' => 'web']);
    }
}
