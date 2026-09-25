<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\SoftDeletes;

class BudgetRecord extends Model
{
    use SoftDeletes;

    protected $fillable = [
        'user_id',
        'entity',
        'client_id',
        'payload',
        'client_updated_at',
    ];

    protected function casts(): array
    {
        return [
            'payload' => 'array',
            'client_updated_at' => 'datetime',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
