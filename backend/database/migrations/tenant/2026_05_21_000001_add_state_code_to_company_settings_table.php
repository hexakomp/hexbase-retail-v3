<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::connection('tenant')->table('company_settings', function (Blueprint $table) {
            $table->string('state_code', 2)->nullable()->after('state');
        });
    }

    public function down(): void
    {
        Schema::connection('tenant')->table('company_settings', function (Blueprint $table) {
            $table->dropColumn('state_code');
        });
    }
};
