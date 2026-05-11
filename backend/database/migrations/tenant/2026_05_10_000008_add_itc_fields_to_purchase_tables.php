<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Add ITC / attachment / reverse-charge columns missing from initial purchase migration.
 */
return new class extends Migration
{
    protected $connection = 'tenant';

    public function up(): void
    {
        Schema::connection('tenant')->table('purchase_invoices', function (Blueprint $table) {
            $table->date('vendor_invoice_date')->nullable()->after('vendor_invoice_number');
            $table->date('entry_date')->nullable()->after('vendor_invoice_date');
            $table->boolean('reverse_charge')->default(false)->after('vendor_gstin');
            $table->foreignId('purchase_order_id')
                ->nullable()
                ->after('vendor_id')
                ->constrained('purchase_orders')
                ->nullOnDelete();
            $table->string('attachment_path')->nullable()->after('notes');
            $table->text('narration')->nullable()->after('notes');
            $table->json('custom_fields')->nullable()->after('narration');
        });

        Schema::connection('tenant')->table('purchase_invoice_lines', function (Blueprint $table) {
            $table->boolean('itc_eligible')->default(false)->after('cess_amount');
            $table->json('custom_columns')->nullable()->after('itc_eligible');
        });
    }

    public function down(): void
    {
        Schema::connection('tenant')->table('purchase_invoice_lines', function (Blueprint $table) {
            $table->dropColumn(['itc_eligible', 'custom_columns']);
        });
        Schema::connection('tenant')->table('purchase_invoices', function (Blueprint $table) {
            $table->dropForeign(['purchase_order_id']);
            $table->dropColumn([
                'vendor_invoice_date', 'entry_date', 'reverse_charge',
                'purchase_order_id', 'attachment_path', 'narration', 'custom_fields',
            ]);
        });
    }
};
