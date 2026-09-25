<?php

namespace App\Application\Sync;

use App\Domain\Sync\SyncedEntity;
use App\Domain\Sync\SyncStore;
use Illuminate\Support\Carbon;

class PullSync
{
    public function __construct(private readonly SyncStore $sync) {}

    /**
     * @return array<string, mixed>
     */
    public function handle(int $userId, ?string $since): array
    {
        $payload = [
            'serverTime' => Carbon::now()->toISOString(),
        ];

        foreach (SyncedEntity::cases() as $entity) {
            $payload[$entity->value] = $this->sync->pull($userId, $entity, $since);
        }

        return $payload;
    }
}
