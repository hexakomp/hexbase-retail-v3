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
        Schema::table('sales_invoices', function (Blueprint $table) {
            $table->text('customer_billing_address')->nullable()->after('customer_id');
            $table->string('customer_phone', 50)->nullable()->after('customer_billing_address');
            $table->string('customer_pincode', 20)->nullable()->after('customer_phone');
            $table->text('internal_notes')->nullable()->after('notes');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('sales_invoices', function (Blueprint $table) {
            $table->dropColumn([
                'customer_billing_address',
                'customer_phone',
                'customer_pincode',
                'internal_notes'
            ]);
        });
    }
};
