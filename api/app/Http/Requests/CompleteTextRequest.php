<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class CompleteTextRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    /**
     * @return array<string, mixed>
     */
    public function rules(): array
    {
        return [
            'systemPrompt' => ['required', 'string', 'max:20000'],
            'userPrompt' => ['required', 'string', 'max:20000'],
            'temperature' => ['sometimes', 'numeric', 'between:0,2'],
            'maxTokens' => ['sometimes', 'integer', 'between:1,4000'],
        ];
    }
}
