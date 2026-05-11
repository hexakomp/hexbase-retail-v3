<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Tenant Batch 6: Accounting & audit tables
 * - chart_of_accounts
 * - ledger_entries
 * - inventory_movements
 * - activity_log
 * - custom_field_definitions
 * - line_column_definitions
 */
return new class extends Migration
{
    protected $connection = 'tenant';

    public function up(): void
    {
        Schema::connection('tenant')->create('chart_of_accounts', function (Blueprint $table) {
            $table->id();
            $table->string('code', 20)->unique();
            $table->string('name');
            $table->enum('type', [
                'cash', 'bank', 'sales', 'purchase',
                'receivable', 'payable',
                'cgst_payable', 'sgst_payable', 'igst_payable',
                'itc_receivable', 'expense', 'stock', 'round_off',
                'capital', 'loan', 'fixed_asset', 'other',
            ]);
            $table->enum('normal_balance', ['dr', 'cr'])->default('dr');
            $table->foreignId('parent_id')->nullable()->constrained('chart_of_accounts')->nullOnDelete();
            $table->boolean('is_system')->default(false); // Cannot be deleted
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });

        Schema::connection('tenant')->create('ledger_entries', function (Blueprint $table) {
            $table->id();
            $table->date('entry_date');
            $table->foreignId('account_id')->constrained('chart_of_accounts');
            $table->morphs('entryable'); // polymorphic: sales_invoice, payment, receipt, expense...
            $table->decimal('debit_amount', 15, 2)->default(0);
            $table->decimal('credit_amount', 15, 2)->default(0);
            $table->string('narration')->nullable();
            $table->string('voucher_number', 50)->nullable();
            $table->foreignId('created_by')->nullable()->constrained('users');
            $table->timestamps();

            $table->index(['entry_date', 'account_id']);
        });

        Schema::connection('tenant')->create('inventory_movements', function (Blueprint $table) {
            $table->id();
            $table->foreignId('product_id')->constrained('products');
            $table->morphs('moveable'); // polymorphic source
            $table->enum('type', ['in', 'out', 'adjustment']);
            $table->decimal('quantity', 15, 3);
            $table->decimal('unit_cost', 15, 2)->nullable();
            $table->decimal('balance_quantity', 15, 3)->default(0);
            $table->text('notes')->nullable();
            $table->date('movement_date');
            $table->foreignId('created_by')->nullable()->constrained('users');
            $table->timestamps();

            $table->index(['product_id', 'movement_date']);
        });

        Schema::connection('tenant')->create('activity_log', function (Blueprint $table) {
            $table->id();
            $table->string('log_name')->nullable();
            $table->string('description');
            $table->nullableMorphs('subject');
            $table->nullableMorphs('causer');
            $table->json('properties')->nullable();
            $table->timestamps();

            // nullableMorphs already creates subject_type/subject_id index
            $table->index('created_at');
        });

        Schema::connection('tenant')->create('custom_field_definitions', function (Blueprint $table) {
            $table->id();
            $table->string('entity', 50); // customer, vendor, product, sales_invoice, etc.
            $table->string('field_key', 50);
            $table->string('field_label');
            $table->enum('field_type', ['text', 'number', 'date', 'select', 'boolean'])->default('text');
            $table->json('options')->nullable(); // for select type
            $table->boolean('is_required')->default(false);
            $table->unsignedSmallInteger('sort_order')->default(0);
            $table->boolean('is_active')->default(true);
            $table->timestamps();

            $table->unique(['entity', 'field_key']);
        });

        Schema::connection('tenant')->create('line_column_definitions', function (Blueprint $table) {
            $table->id();
            $table->string('document_type', 50); // sales_invoice, purchase_invoice, etc.
            $table->string('column_key', 50);
            $table->string('column_label');
            $table->boolean('is_visible')->default(true);
            $table->boolean('is_required')->default(false);
            $table->unsignedSmallInteger('sort_order')->default(0);
            $table->timestamps();

            $table->unique(['document_type', 'column_key']);
        });
    }

    public function down(): void
    {
        Schema::connection('tenant')->dropIfExists('line_column_definitions');
        Schema::connection('tenant')->dropIfExists('custom_field_definitions');
        Schema::connection('tenant')->dropIfExists('activity_log');
        Schema::connection('tenant')->dropIfExists('inventory_movements');
        Schema::connection('tenant')->dropIfExists('ledger_entries');
        Schema::connection('tenant')->dropIfExists('chart_of_accounts');
    }
};
