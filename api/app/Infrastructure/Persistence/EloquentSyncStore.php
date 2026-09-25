<?php

namespace App\Infrastructure\Persistence;

use App\Domain\Budget\DefaultBudgetCatalog;
use App\Domain\Sync\SyncedEntity;
use App\Domain\Sync\SyncStore;
use App\Models\BudgetRecord;
use Illuminate\Support\Carbon;

class EloquentSyncStore implements SyncStore
{
    public function push(int $userId, SyncedEntity $entity, array $records): void
    {
        foreach ($records as $record) {
            $clientId = isset($record['id']) ? (string) $record['id'] : '';
            if ($clientId === '') {
                continue;
            }

            $incomingAt = Carbon::parse((string) ($record['updatedAt'] ?? Carbon::now()->toISOString()));
            $deleted = ! empty($record['deleted']) || ! empty($record['deletedAt']);

            $existing = BudgetRecord::withTrashed()
                ->where('user_id', $userId)
                ->where('entity', $entity->value)
                ->where('client_id', $clientId)
                ->first();

            if ($existing !== null && $existing->client_updated_at->greaterThan($incomingAt)) {
                continue;
            }

            if ($existing === null) {
                $existing = new BudgetRecord([
                    'user_id' => $userId,
                    'entity' => $entity->value,
                    'client_id' => $clientId,
                ]);
            }

            $existing->payload = $record;
            $existing->client_updated_at = $incomingAt;
            $existing->save();

            if ($deleted) {
                if (! $existing->trashed()) {
                    $existing->delete();
                }
            } elseif ($existing->trashed()) {
                $existing->restore();
            }
        }
    }

    public function pull(int $userId, SyncedEntity $entity, ?string $since): array
    {
        $query = BudgetRecord::withTrashed()
            ->where('user_id', $userId)
            ->where('entity', $entity->value);

        if ($since !== null && $since !== '') {
            $query->where('updated_at', '>', Carbon::parse($since));
        }

        return $query->orderBy('id')->get()->map(function (BudgetRecord $record) {
            $payload = $record->payload;
            $payload['id'] = $record->client_id;
            $payload['updatedAt'] = $record->client_updated_at->toISOString();
            $payload['deletedAt'] = $record->deleted_at?->toISOString();

            return $payload;
        })->all();
    }

    public function seedDefaults(int $userId): void
    {
        $now = Carbon::now()->toISOString();
        $stamp = fn (array $row) => $row + ['updatedAt' => $now];

        $this->push($userId, SyncedEntity::Accounts, array_map($stamp, DefaultBudgetCatalog::accounts()));
        $this->push($userId, SyncedEntity::Categories, array_map($stamp, DefaultBudgetCatalog::categories()));
    }
}
