<?php

namespace App\Application\Ai;

use App\Domain\Ai\LlmGateway;

class CompletePrompt
{
    public function __construct(private readonly LlmGateway $gateway) {}

    public function text(string $systemPrompt, string $userPrompt, float $temperature, int $maxTokens): string
    {
        return $this->gateway->complete($systemPrompt, $userPrompt, $temperature, $maxTokens);
    }

    public function image(
        string $systemPrompt,
        string $userPrompt,
        string $imageBase64,
        string $mimeType,
        float $temperature,
        int $maxTokens,
    ): string {
        return $this->gateway->completeWithImage(
            $systemPrompt,
            $userPrompt,
            $imageBase64,
            $mimeType,
            $temperature,
            $maxTokens,
        );
    }
}
