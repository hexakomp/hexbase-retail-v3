<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class ChartOfAccountsSeeder extends Seeder
{
    public function run(): void
    {
        $accounts = [
            // Cash & Bank
            ['code' => '1001', 'name' => 'Cash in Hand',         'type' => 'cash',          'normal_balance' => 'dr', 'is_system' => true],
            ['code' => '1002', 'name' => 'Bank Account',         'type' => 'bank',          'normal_balance' => 'dr', 'is_system' => true],

            // Receivable & Payable
            ['code' => '2001', 'name' => 'Accounts Receivable',  'type' => 'receivable',    'normal_balance' => 'dr', 'is_system' => true],
            ['code' => '2002', 'name' => 'Accounts Payable',     'type' => 'payable',       'normal_balance' => 'cr', 'is_system' => true],

            // GST — Output (Payable)
            ['code' => '3001', 'name' => 'CGST Payable',         'type' => 'cgst_payable',  'normal_balance' => 'cr', 'is_system' => true],
            ['code' => '3002', 'name' => 'SGST Payable',         'type' => 'sgst_payable',  'normal_balance' => 'cr', 'is_system' => true],
            ['code' => '3003', 'name' => 'IGST Payable',         'type' => 'igst_payable',  'normal_balance' => 'cr', 'is_system' => true],
            ['code' => '3004', 'name' => 'TDS Payable',          'type' => 'tds_payable',   'normal_balance' => 'cr', 'is_system' => true],
            ['code' => '3006', 'name' => 'CESS Payable',         'type' => 'cess_payable',  'normal_balance' => 'cr', 'is_system' => true],

            // GST — Input (ITC Receivable)
            ['code' => '3101', 'name' => 'CGST Input Tax Credit', 'type' => 'itc_receivable', 'normal_balance' => 'dr', 'is_system' => true],
            ['code' => '3102', 'name' => 'SGST Input Tax Credit', 'type' => 'itc_receivable', 'normal_balance' => 'dr', 'is_system' => true],
            ['code' => '3103', 'name' => 'IGST Input Tax Credit', 'type' => 'itc_receivable', 'normal_balance' => 'dr', 'is_system' => true],
            ['code' => '3106', 'name' => 'CESS Input Tax Credit', 'type' => 'itc_receivable', 'normal_balance' => 'dr', 'is_system' => true],

            // Revenue
            ['code' => '4001', 'name' => 'Sales Revenue',        'type' => 'sales',         'normal_balance' => 'cr', 'is_system' => true],
            ['code' => '4002', 'name' => 'Sales Returns',        'type' => 'sales',         'normal_balance' => 'dr', 'is_system' => false],

            // Purchases
            ['code' => '5001', 'name' => 'Purchases',            'type' => 'purchase',      'normal_balance' => 'dr', 'is_system' => true],
            ['code' => '5002', 'name' => 'Purchase Returns',     'type' => 'purchase',      'normal_balance' => 'cr', 'is_system' => false],

            // Stock
            ['code' => '6001', 'name' => 'Inventory / Stock',    'type' => 'stock',         'normal_balance' => 'dr', 'is_system' => true],

            // Expenses
            ['code' => '7001', 'name' => 'Operating Expenses',   'type' => 'expense',       'normal_balance' => 'dr', 'is_system' => false],
            ['code' => '7002', 'name' => 'Freight & Transport',  'type' => 'expense',       'normal_balance' => 'dr', 'is_system' => false],

            // Round-off
            ['code' => '8001', 'name' => 'Round Off',            'type' => 'round_off',     'normal_balance' => 'dr', 'is_system' => true],

            // Capital
            ['code' => '9001', 'name' => "Owner's Capital",      'type' => 'capital',       'normal_balance' => 'cr', 'is_system' => false],
        ];

        $now = now();

        foreach ($accounts as $account) {
            DB::connection('tenant')
                ->table('chart_of_accounts')
                ->insertOrIgnore(array_merge($account, [
                    'is_active'  => true,
                    'created_at' => $now,
                    'updated_at' => $now,
                ]));
        }
    }
}
