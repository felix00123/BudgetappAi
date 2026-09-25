<?php

namespace App\Domain\Sync;

interface SyncStore
{
    /**
     * @param  list<array<string, mixed>>  $records
     */
    public function push(int $userId, SyncedEntity $entity, array $records): void;

    /**
     * @return list<array<string, mixed>>
     */
    public function pull(int $userId, SyncedEntity $entity, ?string $since): array;

    public function seedDefaults(int $userId): void;
}
