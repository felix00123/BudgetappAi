<?php

namespace App\Domain\Budget;

final class DefaultBudgetCatalog
{
    /**
     * @return list<array<string, mixed>>
     */
    public static function accounts(): array
    {
        return [
            [
                'id' => 'acc_cash',
                'name' => 'Cash',
                'type' => 'cash',
                'initialBalance' => 0,
                'colorValue' => 0xFF22C55E,
            ],
            [
                'id' => 'acc_bank',
                'name' => 'Bank Account',
                'type' => 'bank',
                'initialBalance' => 0,
                'colorValue' => 0xFF6366F1,
            ],
        ];
    }

    /**
     * @return list<array<string, mixed>>
     */
    public static function categories(): array
    {
        return [
            self::category('cat_salary', 'Salary', 'income', 'work', 0xFF22C55E),
            self::category('cat_freelance', 'Freelance', 'income', 'laptop_mac', 0xFF10B981),
            self::category('cat_investment', 'Investment', 'income', 'trending_up', 0xFF6366F1),
            self::category('cat_gift', 'Gift', 'income', 'card_giftcard', 0xFFEC4899),
            self::category('cat_income_other', 'Other', 'income', 'account_balance_wallet', 0xFF64748B),
            self::category('cat_food', 'Food', 'expense', 'restaurant', 0xFFEF4444),
            self::category('cat_transport', 'Transport', 'expense', 'directions_car', 0xFFF59E0B),
            self::category('cat_housing', 'Housing', 'expense', 'home', 0xFF8B5CF6),
            self::category('cat_entertainment', 'Entertainment', 'expense', 'movie', 0xFFEC4899),
            self::category('cat_health', 'Health', 'expense', 'favorite', 0xFF14B8A6),
            self::category('cat_shopping', 'Shopping', 'expense', 'shopping_bag', 0xFF3B82F6),
            self::category('cat_bills', 'Bills', 'expense', 'receipt_long', 0xFF64748B),
            self::category('cat_education', 'Education', 'expense', 'school', 0xFF6366F1),
            self::category('cat_expense_other', 'Other', 'expense', 'account_balance_wallet', 0xFF94A3B8),
        ];
    }

    /**
     * @return array<string, mixed>
     */
    private static function category(string $id, string $name, string $type, string $icon, int $color): array
    {
        return [
            'id' => $id,
            'name' => $name,
            'type' => $type,
            'icon' => $icon,
            'colorValue' => $color,
        ];
    }
}
