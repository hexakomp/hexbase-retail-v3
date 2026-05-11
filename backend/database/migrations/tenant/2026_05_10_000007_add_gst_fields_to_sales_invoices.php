<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Add missing GST columns to sales_invoices:
 *  - invoice_type  (b2b / b2c / export)
 *  - place_of_supply (2-char state code)
 *  - narration
 *  - payment_terms
 */
return new class extends Migration
{
    protected $connection = 'tenant';

    public function up(): void
    {
        Schema::connection('tenant')->table('sales_invoices', function (Blueprint $table) {
            $table->enum('invoice_type', ['b2b', 'b2c', 'export'])
                  ->default('b2b')
                  ->after('supply_type');

            $table->string('place_of_supply', 2)
                  ->nullable()
                  ->after('invoice_type');

            $table->string('payment_terms', 100)
                  ->nullable()
                  ->after('place_of_supply');

            $table->text('narration')
                  ->nullable()
                  ->after('payment_terms');
        });
    }

    public function down(): void
    {
        Schema::connection('tenant')->table('sales_invoices', function (Blueprint $table) {
            $table->dropColumn(['invoice_type', 'place_of_supply', 'payment_terms', 'narration']);
        });
    }
};
