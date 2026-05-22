<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * The database connection that should be used by the migration.
     *
     * @var string
     */
    protected $connection = 'tenant';

    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::connection('tenant')->table('products', function (Blueprint $table) {
            $table->decimal('current_stock', 15, 3)->default(0)->after('reorder_level');
            $table->decimal('weighted_average_cost', 15, 6)->default(0)->after('current_stock');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::connection('tenant')->table('products', function (Blueprint $table) {
            $table->dropColumn(['current_stock', 'weighted_average_cost']);
        });
    }
};
