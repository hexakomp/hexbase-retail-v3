<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        $tables = [
            'quotation_lines',
            'sales_invoice_lines',
            'delivery_challan_lines',
            'credit_note_lines',
            'purchase_order_lines',
            'debit_note_lines',
        ];

        foreach ($tables as $table) {
            Schema::connection('tenant')->table($table, function (Blueprint $t) {
                // Ensure the column does not already exist before adding it
                if (!Schema::connection('tenant')->hasColumn($t->getTable(), 'custom_columns')) {
                    $t->json('custom_columns')->nullable();
                }
            });
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        $tables = [
            'quotation_lines',
            'sales_invoice_lines',
            'delivery_challan_lines',
            'credit_note_lines',
            'purchase_order_lines',
            'debit_note_lines',
        ];

        foreach ($tables as $table) {
            Schema::connection('tenant')->table($table, function (Blueprint $t) {
                $t->dropColumn('custom_columns');
            });
        }
    }
};
