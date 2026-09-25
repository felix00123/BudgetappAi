<?php

namespace App\Http\Requests;

use App\Domain\Sync\SyncedEntity;
use Illuminate\Foundation\Http\FormRequest;

class PushSyncRequest extends FormRequest
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
        $rules = [];
        foreach (SyncedEntity::values() as $entity) {
            $rules[$entity] = ['sometimes', 'array'];
            $rules[$entity.'.*.id'] = ['required', 'string', 'max:191'];
            $rules[$entity.'.*.updatedAt'] = ['required', 'date'];
        }

        return $rules;
    }
}
