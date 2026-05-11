<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Tenant Batch 1: Core user/company tables
 * - users
 * - personal_access_tokens
 * - company_settings
 * - bank_accounts
 * - numbering_sequences
 */
return new class extends Migration
{
    protected $connection = 'tenant';

    public function up(): void
    {
        Schema::connection('tenant')->create('users', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('email')->unique();
            $table->string('password');
            $table->boolean('is_active')->default(true);
            $table->rememberToken();
            $table->timestamps();
            $table->softDeletes();
        });

        Schema::connection('tenant')->create('personal_access_tokens', function (Blueprint $table) {
            $table->id();
            $table->morphs('tokenable');
            $table->string('name');
            $table->string('token', 64)->unique();
            $table->text('abilities')->nullable();
            $table->timestamp('last_used_at')->nullable();
            $table->timestamp('expires_at')->nullable();
            $table->timestamps();
        });

        Schema::connection('tenant')->create('company_settings', function (Blueprint $table) {
            $table->id();
            $table->string('company_name');
            $table->string('gstin', 20)->nullable();
            $table->text('address')->nullable();
            $table->string('city', 100)->nullable();
            $table->string('state', 100)->nullable();
            $table->string('pincode', 10)->nullable();
            $table->string('phone', 20)->nullable();
            $table->string('email')->nullable();
            $table->string('pan', 20)->nullable();
            $table->string('logo_path')->nullable();
            $table->string('currency', 5)->default('INR');
            $table->string('financial_year_start', 5)->default('04-01'); // MM-DD
            $table->tinyInteger('default_gst_rate')->default(18);
            $table->json('invoice_template')->nullable();
            $table->timestamps();
        });

        Schema::connection('tenant')->create('bank_accounts', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('account_number')->nullable();
            $table->string('ifsc', 20)->nullable();
            $table->string('bank_name')->nullable();
            $table->string('branch')->nullable();
            $table->boolean('is_default')->default(false);
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });

        Schema::connection('tenant')->create('numbering_sequences', function (Blueprint $table) {
            $table->id();
            $table->string('type', 50)->unique(); // sales_invoice, purchase_invoice, quotation, etc.
            $table->string('prefix', 20)->default('');
            $table->string('suffix', 20)->default('');
            $table->unsignedInteger('next_number')->default(1);
            $table->unsignedTinyInteger('pad_length')->default(4);
            $table->string('financial_year', 9)->nullable(); // e.g. "2025-2026"
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::connection('tenant')->dropIfExists('numbering_sequences');
        Schema::connection('tenant')->dropIfExists('bank_accounts');
        Schema::connection('tenant')->dropIfExists('company_settings');
        Schema::connection('tenant')->dropIfExists('personal_access_tokens');
        Schema::connection('tenant')->dropIfExists('users');
    }
};
