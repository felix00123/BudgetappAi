<?php

namespace App\Providers;

use App\Domain\Ai\LlmGateway;
use App\Domain\Sync\SyncStore;
use App\Infrastructure\Ai\OpenAiCompatibleGateway;
use App\Infrastructure\Persistence\EloquentSyncStore;
use Illuminate\Cache\RateLimiting\Limit;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        $this->app->bind(SyncStore::class, EloquentSyncStore::class);
        $this->app->bind(LlmGateway::class, OpenAiCompatibleGateway::class);
    }

    public function boot(): void
    {
        RateLimiter::for('ai', function (Request $request) {
            return Limit::perMinute(30)->by((string) ($request->user()?->id ?? $request->ip()));
        });
    }
}
