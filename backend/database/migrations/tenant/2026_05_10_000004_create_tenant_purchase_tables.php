<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Tenant Batch 4: Purchase documents
 * - purchase_invoices + lines
 * - purchase_orders + lines
 * - debit_notes + lines
 */
return new class extends Migration
{
    protected $connection = 'tenant';

    public function up(): void
    {
        // Purchase Invoices
        Schema::connection('tenant')->create('purchase_invoices', function (Blueprint $table) {
            $table->id();
            $table->string('invoice_number', 50);
            $table->string('vendor_invoice_number', 50)->nullable();
            $table->date('invoice_date');
            $table->date('due_date')->nullable();
            $table->foreignId('vendor_id')->constrained('vendors');
            $table->string('vendor_gstin', 20)->nullable();
            $table->enum('supply_type', ['intra', 'inter', 'import'])->default('intra');
            $table->decimal('subtotal', 15, 2)->default(0);
            $table->decimal('discount_amount', 15, 2)->default(0);
            $table->decimal('taxable_amount', 15, 2)->default(0);
            $table->decimal('cgst_amount', 15, 2)->default(0);
            $table->decimal('sgst_amount', 15, 2)->default(0);
            $table->decimal('igst_amount', 15, 2)->default(0);
            $table->decimal('cess_amount', 15, 2)->default(0);
            $table->decimal('round_off', 15, 2)->default(0);
            $table->decimal('total_amount', 15, 2)->default(0);
            $table->decimal('paid_amount', 15, 2)->default(0);
            $table->decimal('balance_amount', 15, 2)->default(0);
            $table->enum('status', ['draft', 'confirmed', 'partially_paid', 'paid', 'cancelled'])->default('draft');
            $table->text('notes')->nullable();
            $table->foreignId('created_by')->nullable()->constrained('users');
            $table->timestamps();
            $table->softDeletes();

            $table->unique(['vendor_id', 'invoice_number']);
        });

        Schema::connection('tenant')->create('purchase_invoice_lines', function (Blueprint $table) {
            $table->id();
            $table->foreignId('purchase_invoice_id')->constrained('purchase_invoices')->cascadeOnDelete();
            $table->foreignId('product_id')->constrained('products');
            $table->string('description')->nullable();
            $table->string('hsn_sac', 10)->nullable();
            $table->decimal('quantity', 15, 3);
            $table->string('unit', 20)->default('PCS');
            $table->decimal('unit_price', 15, 2);
            $table->decimal('discount_pct', 5, 2)->default(0);
            $table->decimal('discount_amount', 15, 2)->default(0);
            $table->decimal('taxable_amount', 15, 2);
            $table->tinyInteger('gst_rate')->default(0);
            $table->decimal('cgst_rate', 5, 2)->default(0);
            $table->decimal('cgst_amount', 15, 2)->default(0);
            $table->decimal('sgst_rate', 5, 2)->default(0);
            $table->decimal('sgst_amount', 15, 2)->default(0);
            $table->decimal('igst_rate', 5, 2)->default(0);
            $table->decimal('igst_amount', 15, 2)->default(0);
            $table->decimal('cess_rate', 5, 2)->default(0);
            $table->decimal('cess_amount', 15, 2)->default(0);
            $table->decimal('line_total', 15, 2);
            $table->unsignedSmallInteger('sort_order')->default(0);
        });

        // Purchase Orders
        Schema::connection('tenant')->create('purchase_orders', function (Blueprint $table) {
            $table->id();
            $table->string('po_number', 50)->unique();
            $table->date('po_date');
            $table->date('expected_date')->nullable();
            $table->foreignId('vendor_id')->constrained('vendors');
            $table->decimal('total_amount', 15, 2)->default(0);
            $table->enum('status', ['draft', 'sent', 'acknowledged', 'partially_received', 'received', 'cancelled'])->default('draft');
            $table->foreignId('converted_to_invoice_id')->nullable()->constrained('purchase_invoices')->nullOnDelete();
            $table->text('notes')->nullable();
            $table->foreignId('created_by')->nullable()->constrained('users');
            $table->timestamps();
            $table->softDeletes();
        });

        Schema::connection('tenant')->create('purchase_order_lines', function (Blueprint $table) {
            $table->id();
            $table->foreignId('purchase_order_id')->constrained('purchase_orders')->cascadeOnDelete();
            $table->foreignId('product_id')->constrained('products');
            $table->decimal('quantity', 15, 3);
            $table->decimal('received_quantity', 15, 3)->default(0);
            $table->string('unit', 20)->default('PCS');
            $table->decimal('unit_price', 15, 2);
            $table->decimal('line_total', 15, 2);
            $table->unsignedSmallInteger('sort_order')->default(0);
        });

        // Debit Notes
        Schema::connection('tenant')->create('debit_notes', function (Blueprint $table) {
            $table->id();
            $table->string('debit_note_number', 50)->unique();
            $table->date('debit_note_date');
            $table->foreignId('vendor_id')->constrained('vendors');
            $table->foreignId('purchase_invoice_id')->nullable()->constrained('purchase_invoices')->nullOnDelete();
            $table->string('reason')->nullable();
            $table->decimal('subtotal', 15, 2)->default(0);
            $table->decimal('tax_amount', 15, 2)->default(0);
            $table->decimal('total_amount', 15, 2)->default(0);
            $table->enum('status', ['draft', 'confirmed', 'adjusted'])->default('draft');
            $table->foreignId('created_by')->nullable()->constrained('users');
            $table->timestamps();
            $table->softDeletes();
        });

        Schema::connection('tenant')->create('debit_note_lines', function (Blueprint $table) {
            $table->id();
            $table->foreignId('debit_note_id')->constrained('debit_notes')->cascadeOnDelete();
            $table->foreignId('product_id')->constrained('products');
            $table->decimal('quantity', 15, 3);
            $table->decimal('unit_price', 15, 2);
            $table->tinyInteger('gst_rate')->default(0);
            $table->decimal('taxable_amount', 15, 2);
            $table->decimal('tax_amount', 15, 2)->default(0);
            $table->decimal('line_total', 15, 2);
            $table->unsignedSmallInteger('sort_order')->default(0);
        });
    }

    public function down(): void
    {
        Schema::connection('tenant')->dropIfExists('debit_note_lines');
        Schema::connection('tenant')->dropIfExists('debit_notes');
        Schema::connection('tenant')->dropIfExists('purchase_order_lines');
        Schema::connection('tenant')->dropIfExists('purchase_orders');
        Schema::connection('tenant')->dropIfExists('purchase_invoice_lines');
        Schema::connection('tenant')->dropIfExists('purchase_invoices');
    }
};
