<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Tenant Batch 5: Finance tables
 * - receipts + receipt_allocations
 * - payments + payment_allocations
 * - expenses
 */
return new class extends Migration
{
    protected $connection = 'tenant';

    public function up(): void
    {
        Schema::connection('tenant')->create('receipts', function (Blueprint $table) {
            $table->id();
            $table->string('receipt_number', 50)->unique();
            $table->date('receipt_date');
            $table->foreignId('customer_id')->constrained('customers');
            $table->foreignId('bank_account_id')->nullable()->constrained('bank_accounts')->nullOnDelete();
            $table->enum('payment_mode', ['cash', 'bank_transfer', 'cheque', 'upi', 'card', 'other'])->default('cash');
            $table->string('reference_number', 100)->nullable(); // cheque/UTR number
            $table->decimal('amount', 15, 2);
            $table->text('notes')->nullable();
            $table->enum('status', ['draft', 'confirmed'])->default('draft');
            $table->foreignId('created_by')->nullable()->constrained('users');
            $table->timestamps();
            $table->softDeletes();
        });

        Schema::connection('tenant')->create('receipt_allocations', function (Blueprint $table) {
            $table->id();
            $table->foreignId('receipt_id')->constrained('receipts')->cascadeOnDelete();
            $table->foreignId('sales_invoice_id')->constrained('sales_invoices')->cascadeOnDelete();
            $table->decimal('allocated_amount', 15, 2);
            $table->timestamps();
        });

        Schema::connection('tenant')->create('payments', function (Blueprint $table) {
            $table->id();
            $table->string('payment_number', 50)->unique();
            $table->date('payment_date');
            $table->foreignId('vendor_id')->constrained('vendors');
            $table->foreignId('bank_account_id')->nullable()->constrained('bank_accounts')->nullOnDelete();
            $table->enum('payment_mode', ['cash', 'bank_transfer', 'cheque', 'upi', 'card', 'other'])->default('cash');
            $table->string('reference_number', 100)->nullable();
            $table->decimal('amount', 15, 2);
            $table->decimal('tds_amount', 15, 2)->default(0);
            $table->text('notes')->nullable();
            $table->enum('status', ['draft', 'confirmed'])->default('draft');
            $table->foreignId('created_by')->nullable()->constrained('users');
            $table->timestamps();
            $table->softDeletes();
        });

        Schema::connection('tenant')->create('payment_allocations', function (Blueprint $table) {
            $table->id();
            $table->foreignId('payment_id')->constrained('payments')->cascadeOnDelete();
            $table->foreignId('purchase_invoice_id')->constrained('purchase_invoices')->cascadeOnDelete();
            $table->decimal('allocated_amount', 15, 2);
            $table->timestamps();
        });

        Schema::connection('tenant')->create('expenses', function (Blueprint $table) {
            $table->id();
            $table->string('expense_number', 50)->unique();
            $table->date('expense_date');
            $table->string('category', 100);
            $table->string('description');
            $table->foreignId('vendor_id')->nullable()->constrained('vendors')->nullOnDelete();
            $table->foreignId('bank_account_id')->nullable()->constrained('bank_accounts')->nullOnDelete();
            $table->enum('payment_mode', ['cash', 'bank_transfer', 'cheque', 'upi', 'card', 'other'])->default('cash');
            $table->decimal('amount', 15, 2);
            $table->decimal('gst_amount', 15, 2)->default(0);
            $table->decimal('total_amount', 15, 2);
            $table->boolean('is_billable')->default(false);
            $table->foreignId('customer_id')->nullable()->constrained('customers')->nullOnDelete();
            $table->foreignId('created_by')->nullable()->constrained('users');
            $table->timestamps();
            $table->softDeletes();
        });
    }

    public function down(): void
    {
        Schema::connection('tenant')->dropIfExists('expenses');
        Schema::connection('tenant')->dropIfExists('payment_allocations');
        Schema::connection('tenant')->dropIfExists('payments');
        Schema::connection('tenant')->dropIfExists('receipt_allocations');
        Schema::connection('tenant')->dropIfExists('receipts');
    }
};
