<?php

namespace App\Application\Sync;

use App\Domain\Sync\SyncedEntity;
use App\Domain\Sync\SyncStore;

class PushSync
{
    public function __construct(private readonly SyncStore $sync) {}

    /**
     * @param  array<string, list<array<string, mixed>>>  $batches
     */
    public function handle(int $userId, array $batches): void
    {
        foreach (SyncedEntity::cases() as $entity) {
            $records = $batches[$entity->value] ?? [];
            if ($records === []) {
                continue;
            }
            $this->sync->push($userId, $entity, $records);
        }
    }
}
