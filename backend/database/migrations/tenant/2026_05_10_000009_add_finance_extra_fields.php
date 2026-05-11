<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Tenant Batch 9: Add missing columns to receipts and payments tables
 *  - receipts:  advance_amount, narration, custom_fields, cancelled status
 *  - payments:  advance_amount, narration, custom_fields, cancelled status
 */
return new class extends Migration
{
    protected $connection = 'tenant';

    public function up(): void
    {
        Schema::connection('tenant')->table('receipts', function (Blueprint $table) {
            $table->decimal('advance_amount', 15, 2)->default(0)->after('amount');
            $table->text('narration')->nullable()->after('notes');
            $table->json('custom_fields')->nullable()->after('narration');
        });

        // Extend receipts.status enum to include 'cancelled'
        \DB::connection('tenant')->statement(
            "ALTER TABLE receipts MODIFY COLUMN status ENUM('draft','confirmed','cancelled') NOT NULL DEFAULT 'draft'"
        );

        Schema::connection('tenant')->table('payments', function (Blueprint $table) {
            $table->decimal('advance_amount', 15, 2)->default(0)->after('tds_amount');
            $table->text('narration')->nullable()->after('notes');
            $table->json('custom_fields')->nullable()->after('narration');
        });

        // Extend payments.status enum to include 'cancelled'
        \DB::connection('tenant')->statement(
            "ALTER TABLE payments MODIFY COLUMN status ENUM('draft','confirmed','cancelled') NOT NULL DEFAULT 'draft'"
        );
    }

    public function down(): void
    {
        Schema::connection('tenant')->table('receipts', function (Blueprint $table) {
            $table->dropColumn(['advance_amount', 'narration', 'custom_fields']);
        });
        \DB::connection('tenant')->statement(
            "ALTER TABLE receipts MODIFY COLUMN status ENUM('draft','confirmed') NOT NULL DEFAULT 'draft'"
        );

        Schema::connection('tenant')->table('payments', function (Blueprint $table) {
            $table->dropColumn(['advance_amount', 'narration', 'custom_fields']);
        });
        \DB::connection('tenant')->statement(
            "ALTER TABLE payments MODIFY COLUMN status ENUM('draft','confirmed') NOT NULL DEFAULT 'draft'"
        );
    }
};
