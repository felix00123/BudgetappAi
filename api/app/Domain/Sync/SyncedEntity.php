<?php

namespace App\Domain\Sync;

enum SyncedEntity: string
{
    case Accounts = 'accounts';
    case Categories = 'categories';
    case Transactions = 'transactions';
    case RecurringTransactions = 'recurring_transactions';
    case SavingsGoals = 'savings_goals';
    case Loans = 'loans';
    case BalanceSnapshots = 'balance_snapshots';
    case ChatMessages = 'chat_messages';
    case MonthSummaries = 'month_summaries';

    /**
     * @return list<string>
     */
    public static function values(): array
    {
        return array_map(fn (self $entity) => $entity->value, self::cases());
    }
}
