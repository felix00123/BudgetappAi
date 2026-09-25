<?php

namespace App\Infrastructure\Ai;

use App\Domain\Ai\LlmGateway;
use Illuminate\Http\Client\RequestException;
use Illuminate\Support\Facades\Http;
use RuntimeException;

class OpenAiCompatibleGateway implements LlmGateway
{
    public function complete(string $systemPrompt, string $userPrompt, float $temperature, int $maxTokens): string
    {
        return $this->send([
            ['role' => 'system', 'content' => $systemPrompt],
            ['role' => 'user', 'content' => $userPrompt],
        ], $temperature, $maxTokens);
    }

    public function completeWithImage(
        string $systemPrompt,
        string $userPrompt,
        string $imageBase64,
        string $mimeType,
        float $temperature,
        int $maxTokens,
    ): string {
        return $this->send([
            ['role' => 'system', 'content' => $systemPrompt],
            [
                'role' => 'user',
                'content' => [
                    ['type' => 'text', 'text' => $userPrompt],
                    [
                        'type' => 'image_url',
                        'image_url' => [
                            'url' => 'data:'.$mimeType.';base64,'.$imageBase64,
                        ],
                    ],
                ],
            ],
        ], $temperature, $maxTokens);
    }

    /**
     * @param  list<array<string, mixed>>  $messages
     */
    private function send(array $messages, float $temperature, int $maxTokens): string
    {
        $base = rtrim((string) config('services.ai.base_url'), '/');
        $model = (string) config('services.ai.model');
        $key = (string) config('services.ai.api_key');

        if ($base === '' || $model === '') {
            throw new RuntimeException('The hosted model is not configured.');
        }

        $endpoint = str_ends_with($base, '/chat/completions')
            ? $base
            : (str_ends_with($base, '/v1') ? $base.'/chat/completions' : $base.'/v1/chat/completions');

        try {
            $response = Http::withToken($key)
                ->acceptJson()
                ->timeout(60)
                ->post($endpoint, [
                    'model' => $model,
                    'messages' => $messages,
                    'temperature' => $temperature,
                    'max_tokens' => $maxTokens,
                ])
                ->throw();
        } catch (RequestException $exception) {
            throw new RuntimeException('The hosted model request failed.', previous: $exception);
        }

        $content = $response->json('choices.0.message.content');
        if (! is_string($content) || trim($content) === '') {
            throw new RuntimeException('The hosted model returned an empty response.');
        }

        return $content;
    }
}
