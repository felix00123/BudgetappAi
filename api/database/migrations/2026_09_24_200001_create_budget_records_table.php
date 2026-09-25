<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('budget_records', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('entity');
            $table->string('client_id');
            $table->json('payload');
            $table->timestamp('client_updated_at');
            $table->softDeletes();
            $table->timestamps();

            $table->unique(['user_id', 'entity', 'client_id']);
            $table->index(['user_id', 'entity', 'updated_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('budget_records');
    }
};
