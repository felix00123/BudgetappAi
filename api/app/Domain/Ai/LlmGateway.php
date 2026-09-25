<?php

namespace App\Domain\Ai;

interface LlmGateway
{
    public function complete(string $systemPrompt, string $userPrompt, float $temperature, int $maxTokens): string;

    public function completeWithImage(
        string $systemPrompt,
        string $userPrompt,
        string $imageBase64,
        string $mimeType,
        float $temperature,
        int $maxTokens,
    ): string;
}
