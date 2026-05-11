<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('pdf_templates', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->enum('document_type', [
                'sales_invoice',
                'credit_note',
                'debit_note',
                'purchase_order',
                'delivery_challan',
                'quotation',
            ]);
            $table->longText('template_html');
            $table->boolean('is_default')->default(false);
            $table->unsignedBigInteger('created_by')->nullable();
            $table->timestamps();
            $table->softDeletes();

            $table->index('document_type');
            $table->index(['document_type', 'is_default']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('pdf_templates');
    }
};
