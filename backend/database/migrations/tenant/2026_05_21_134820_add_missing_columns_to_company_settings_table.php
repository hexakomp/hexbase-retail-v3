<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    protected $connection = 'tenant';

    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::connection('tenant')->table('company_settings', function (Blueprint $table) {
            $table->string('legal_name', 200)->nullable();
            $table->string('website')->nullable();
            $table->string('bank_name')->nullable();
            $table->string('bank_account_no')->nullable();
            $table->string('bank_ifsc', 20)->nullable();
            $table->text('invoice_terms')->nullable();
            $table->text('invoice_footer')->nullable();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::connection('tenant')->table('company_settings', function (Blueprint $table) {
            $table->dropColumn([
                'legal_name',
                'website',
                'bank_name',
                'bank_account_no',
                'bank_ifsc',
                'invoice_terms',
                'invoice_footer',
            ]);
        });
    }
};

