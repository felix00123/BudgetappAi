<?php

namespace App\Http\Controllers\Api\V1;

use App\Application\Sync\PullSync;
use App\Application\Sync\PushSync;
use App\Domain\Sync\SyncedEntity;
use App\Http\Controllers\Controller;
use App\Http\Requests\PushSyncRequest;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class SyncController extends Controller
{
    public function push(PushSyncRequest $request, PushSync $push): JsonResponse
    {
        $push->handle($request->user()->id, $request->only(SyncedEntity::values()));

        return response()->json(['ok' => true]);
    }

    public function pull(Request $request, PullSync $pull): JsonResponse
    {
        $since = $request->query('since');

        return response()->json($pull->handle(
            $request->user()->id,
            is_string($since) ? $since : null,
        ));
    }
}
