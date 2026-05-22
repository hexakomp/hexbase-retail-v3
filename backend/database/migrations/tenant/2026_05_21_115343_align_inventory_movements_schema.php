<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    protected $connection = 'tenant';

    public function up(): void
    {
        Schema::connection('tenant')->table('inventory_movements', function (Blueprint $table) {
            $table->renameColumn('moveable_type', 'source_type');
            $table->renameColumn('moveable_id', 'source_id');
            $table->renameColumn('notes', 'narration');
            $table->string('reference')->after('unit_cost')->nullable();
        });

        \Illuminate\Support\Facades\DB::connection('tenant')->statement("ALTER TABLE `inventory_movements` CHANGE `type` `movement_type` VARCHAR(50) NOT NULL");
    }

    public function down(): void
    {
        \Illuminate\Support\Facades\DB::connection('tenant')->statement("ALTER TABLE `inventory_movements` CHANGE `movement_type` `type` ENUM('in', 'out', 'adjustment') NOT NULL");
        Schema::connection('tenant')->table('inventory_movements', function (Blueprint $table) {
            $table->renameColumn('source_type', 'moveable_type');
            $table->renameColumn('source_id', 'moveable_id');
            $table->renameColumn('narration', 'notes');
            $table->dropColumn('reference');
        });
    }
};
