<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Tenant Batch 3: Sales documents
 * - sales_invoices + lines
 * - quotations + lines
 * - delivery_challans + lines
 * - credit_notes + lines
 */
return new class extends Migration
{
    protected $connection = 'tenant';

    public function up(): void
    {
        // Sales Invoices
        Schema::connection('tenant')->create('sales_invoices', function (Blueprint $table) {
            $table->id();
            $table->string('invoice_number', 50)->unique();
            $table->date('invoice_date');
            $table->date('due_date')->nullable();
            $table->foreignId('customer_id')->constrained('customers');
            $table->string('customer_gstin', 20)->nullable();
            $table->enum('supply_type', ['intra', 'inter', 'export'])->default('intra');
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
            $table->text('terms_conditions')->nullable();
            $table->string('pdf_path')->nullable();
            $table->json('custom_fields')->nullable();
            $table->foreignId('created_by')->nullable()->constrained('users');
            $table->timestamps();
            $table->softDeletes();
        });

        Schema::connection('tenant')->create('sales_invoice_lines', function (Blueprint $table) {
            $table->id();
            $table->foreignId('sales_invoice_id')->constrained('sales_invoices')->cascadeOnDelete();
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

        // Quotations
        Schema::connection('tenant')->create('quotations', function (Blueprint $table) {
            $table->id();
            $table->string('quotation_number', 50)->unique();
            $table->date('quotation_date');
            $table->date('valid_until')->nullable();
            $table->foreignId('customer_id')->constrained('customers');
            $table->decimal('subtotal', 15, 2)->default(0);
            $table->decimal('discount_amount', 15, 2)->default(0);
            $table->decimal('taxable_amount', 15, 2)->default(0);
            $table->decimal('tax_amount', 15, 2)->default(0);
            $table->decimal('total_amount', 15, 2)->default(0);
            $table->enum('status', ['draft', 'sent', 'accepted', 'rejected', 'converted'])->default('draft');
            $table->foreignId('converted_to_invoice_id')->nullable()->constrained('sales_invoices')->nullOnDelete();
            $table->text('notes')->nullable();
            $table->foreignId('created_by')->nullable()->constrained('users');
            $table->timestamps();
            $table->softDeletes();
        });

        Schema::connection('tenant')->create('quotation_lines', function (Blueprint $table) {
            $table->id();
            $table->foreignId('quotation_id')->constrained('quotations')->cascadeOnDelete();
            $table->foreignId('product_id')->constrained('products');
            $table->string('description')->nullable();
            $table->decimal('quantity', 15, 3);
            $table->string('unit', 20)->default('PCS');
            $table->decimal('unit_price', 15, 2);
            $table->decimal('discount_pct', 5, 2)->default(0);
            $table->decimal('taxable_amount', 15, 2);
            $table->tinyInteger('gst_rate')->default(0);
            $table->decimal('tax_amount', 15, 2)->default(0);
            $table->decimal('line_total', 15, 2);
            $table->unsignedSmallInteger('sort_order')->default(0);
        });

        // Delivery Challans
        Schema::connection('tenant')->create('delivery_challans', function (Blueprint $table) {
            $table->id();
            $table->string('challan_number', 50)->unique();
            $table->date('challan_date');
            $table->foreignId('customer_id')->constrained('customers');
            $table->foreignId('sales_invoice_id')->nullable()->constrained('sales_invoices')->nullOnDelete();
            $table->enum('status', ['draft', 'dispatched', 'delivered', 'returned'])->default('draft');
            $table->text('delivery_address')->nullable();
            $table->text('notes')->nullable();
            $table->foreignId('created_by')->nullable()->constrained('users');
            $table->timestamps();
            $table->softDeletes();
        });

        Schema::connection('tenant')->create('delivery_challan_lines', function (Blueprint $table) {
            $table->id();
            $table->foreignId('delivery_challan_id')->constrained('delivery_challans')->cascadeOnDelete();
            $table->foreignId('product_id')->constrained('products');
            $table->decimal('quantity', 15, 3);
            $table->string('unit', 20)->default('PCS');
            $table->text('remarks')->nullable();
            $table->unsignedSmallInteger('sort_order')->default(0);
        });

        // Credit Notes
        Schema::connection('tenant')->create('credit_notes', function (Blueprint $table) {
            $table->id();
            $table->string('credit_note_number', 50)->unique();
            $table->date('credit_note_date');
            $table->foreignId('customer_id')->constrained('customers');
            $table->foreignId('sales_invoice_id')->nullable()->constrained('sales_invoices')->nullOnDelete();
            $table->string('reason')->nullable();
            $table->decimal('subtotal', 15, 2)->default(0);
            $table->decimal('tax_amount', 15, 2)->default(0);
            $table->decimal('total_amount', 15, 2)->default(0);
            $table->enum('status', ['draft', 'confirmed', 'adjusted'])->default('draft');
            $table->foreignId('created_by')->nullable()->constrained('users');
            $table->timestamps();
            $table->softDeletes();
        });

        Schema::connection('tenant')->create('credit_note_lines', function (Blueprint $table) {
            $table->id();
            $table->foreignId('credit_note_id')->constrained('credit_notes')->cascadeOnDelete();
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
        Schema::connection('tenant')->dropIfExists('credit_note_lines');
        Schema::connection('tenant')->dropIfExists('credit_notes');
        Schema::connection('tenant')->dropIfExists('delivery_challan_lines');
        Schema::connection('tenant')->dropIfExists('delivery_challans');
        Schema::connection('tenant')->dropIfExists('quotation_lines');
        Schema::connection('tenant')->dropIfExists('quotations');
        Schema::connection('tenant')->dropIfExists('sales_invoice_lines');
        Schema::connection('tenant')->dropIfExists('sales_invoices');
    }
};
