<?php

use App\Http\Controllers\Api\V1\AiController;
use App\Http\Controllers\Api\V1\AuthController;
use App\Http\Controllers\Api\V1\SyncController;
use Illuminate\Support\Facades\Route;

Route::prefix('v1')->group(function () {
    Route::post('/auth/register', [AuthController::class, 'register']);
    Route::post('/auth/login', [AuthController::class, 'login']);

    Route::middleware('auth:sanctum')->group(function () {
        Route::post('/auth/logout', [AuthController::class, 'logout']);
        Route::get('/me', [AuthController::class, 'me']);
        Route::post('/sync/push', [SyncController::class, 'push']);
        Route::get('/sync/pull', [SyncController::class, 'pull']);
        Route::middleware('throttle:ai')->group(function () {
            Route::post('/ai/complete', [AiController::class, 'complete']);
            Route::post('/ai/complete-image', [AiController::class, 'completeImage']);
        });
    });
});
