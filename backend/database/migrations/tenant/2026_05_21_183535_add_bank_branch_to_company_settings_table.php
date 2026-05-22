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
        Schema::connection('tenant')->table('company_settings', function (Blueprint $table) {
            $table->string('bank_branch')->nullable()->after('bank_account_no');
            $table->string('cin', 50)->nullable()->after('pan');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::connection('tenant')->table('company_settings', function (Blueprint $table) {
            $table->dropColumn(['bank_branch', 'cin']);
        });
    }
};
