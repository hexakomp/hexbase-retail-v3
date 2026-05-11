<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Tenant Batch 2: Master entities
 * - customers
 * - vendors
 * - products
 * - price_lists
 */
return new class extends Migration
{
    protected $connection = 'tenant';

    public function up(): void
    {
        Schema::connection('tenant')->create('customers', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('code', 30)->nullable()->unique();
            $table->string('gstin', 20)->nullable();
            $table->enum('gst_type', ['regular', 'composition', 'unregistered', 'sez', 'overseas'])->default('regular');
            $table->string('pan', 20)->nullable();
            $table->text('billing_address')->nullable();
            $table->string('billing_city', 100)->nullable();
            $table->string('billing_state', 100)->nullable();
            $table->string('billing_pincode', 10)->nullable();
            $table->text('shipping_address')->nullable();
            $table->string('phone', 20)->nullable();
            $table->string('email')->nullable();
            $table->decimal('credit_limit', 15, 2)->default(0);
            $table->tinyInteger('credit_days')->default(30);
            $table->decimal('opening_balance', 15, 2)->default(0);
            $table->enum('opening_balance_type', ['dr', 'cr'])->default('dr');
            $table->boolean('is_active')->default(true);
            $table->json('custom_fields')->nullable();
            $table->timestamps();
            $table->softDeletes();
        });

        Schema::connection('tenant')->create('vendors', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('code', 30)->nullable()->unique();
            $table->string('gstin', 20)->nullable();
            $table->enum('gst_type', ['regular', 'composition', 'unregistered', 'sez', 'overseas'])->default('regular');
            $table->string('pan', 20)->nullable();
            $table->text('address')->nullable();
            $table->string('city', 100)->nullable();
            $table->string('state', 100)->nullable();
            $table->string('pincode', 10)->nullable();
            $table->string('phone', 20)->nullable();
            $table->string('email')->nullable();
            $table->decimal('credit_limit', 15, 2)->default(0);
            $table->tinyInteger('credit_days')->default(30);
            $table->decimal('opening_balance', 15, 2)->default(0);
            $table->enum('opening_balance_type', ['dr', 'cr'])->default('cr');
            $table->boolean('is_active')->default(true);
            $table->json('custom_fields')->nullable();
            $table->timestamps();
            $table->softDeletes();
        });

        Schema::connection('tenant')->create('products', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('code', 50)->nullable()->unique();
            $table->string('sku', 50)->nullable()->unique();
            $table->string('hsn_sac', 10)->nullable();
            $table->enum('type', ['goods', 'service'])->default('goods');
            $table->string('unit', 20)->default('PCS');
            $table->decimal('sale_price', 15, 2)->default(0);
            $table->decimal('purchase_price', 15, 2)->default(0);
            $table->decimal('mrp', 15, 2)->nullable();
            $table->tinyInteger('gst_rate')->default(18); // 0, 5, 12, 18, 28
            $table->tinyInteger('cess_rate')->default(0);
            $table->boolean('track_inventory')->default(true);
            $table->decimal('opening_stock', 15, 3)->default(0);
            $table->decimal('reorder_level', 15, 3)->default(0);
            $table->boolean('is_active')->default(true);
            $table->json('custom_fields')->nullable();
            $table->timestamps();
            $table->softDeletes();
        });

        Schema::connection('tenant')->create('price_lists', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->enum('type', ['sale', 'purchase'])->default('sale');
            $table->foreignId('product_id')->constrained('products')->cascadeOnDelete();
            $table->foreignId('customer_id')->nullable()->constrained('customers')->nullOnDelete();
            $table->decimal('price', 15, 2);
            $table->date('valid_from')->nullable();
            $table->date('valid_to')->nullable();
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::connection('tenant')->dropIfExists('price_lists');
        Schema::connection('tenant')->dropIfExists('products');
        Schema::connection('tenant')->dropIfExists('vendors');
        Schema::connection('tenant')->dropIfExists('customers');
    }
};
