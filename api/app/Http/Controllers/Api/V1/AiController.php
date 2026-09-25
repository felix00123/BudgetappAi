<?php

namespace App\Http\Controllers\Api\V1;

use App\Application\Ai\CompletePrompt;
use App\Http\Controllers\Controller;
use App\Http\Requests\CompleteImageRequest;
use App\Http\Requests\CompleteTextRequest;
use Illuminate\Http\JsonResponse;
use RuntimeException;

class AiController extends Controller
{
    public function complete(CompleteTextRequest $request, CompletePrompt $complete): JsonResponse
    {
        return $this->respond(fn () => $complete->text(
            $request->string('systemPrompt')->toString(),
            $request->string('userPrompt')->toString(),
            (float) $request->input('temperature', 0.7),
            (int) $request->input('maxTokens', 600),
        ));
    }

    public function completeImage(CompleteImageRequest $request, CompletePrompt $complete): JsonResponse
    {
        return $this->respond(fn () => $complete->image(
            $request->string('systemPrompt')->toString(),
            $request->string('userPrompt')->toString(),
            $request->string('imageBase64')->toString(),
            $request->string('mimeType')->toString(),
            (float) $request->input('temperature', 0.1),
            (int) $request->input('maxTokens', 400),
        ));
    }

    private function respond(\Closure $action): JsonResponse
    {
        try {
            return response()->json(['content' => $action()]);
        } catch (RuntimeException) {
            return response()->json([
                'message' => 'The hosted model is unavailable.',
            ], 502);
        }
    }
}
