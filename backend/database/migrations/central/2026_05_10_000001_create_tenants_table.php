<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    protected $connection = 'central';

    public function up(): void
    {
        Schema::connection('central')->create('tenants', function (Blueprint $table) {
            $table->id();
            $table->string('code', 50)->unique(); // e.g. "acme"
            $table->string('name');
            $table->string('db_host')->nullable();
            $table->string('db_username')->nullable();
            $table->string('db_password')->nullable();
            $table->boolean('is_active')->default(true);
            $table->string('plan')->default('basic'); // basic, pro, enterprise
            $table->json('settings')->nullable();
            $table->timestamp('trial_ends_at')->nullable();
            $table->timestamps();
            $table->softDeletes();
        });
    }

    public function down(): void
    {
        Schema::connection('central')->dropIfExists('tenants');
    }
};
