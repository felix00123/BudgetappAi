import 'package:flutter/material.dart';

import '../models/transaction.dart';
import '../screens/add_transaction_screen.dart';
import '../theme/app_theme.dart';

/// Side-by-side quick actions to add income or expense.
class QuickAddActions extends StatelessWidget {
  const QuickAddActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: QuickAddIncomeWidget(
            onTap: () => _open(context, TransactionType.income),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: QuickAddExpenseWidget(
            onTap: () => _open(context, TransactionType.expense),
          ),
        ),
      ],
    );
  }

  void _open(BuildContext context, TransactionType type) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddTransactionScreen(initialType: type),
      ),
    );
  }
}

/// Tappable card to quickly add income.
class QuickAddIncomeWidget extends StatelessWidget {
  const QuickAddIncomeWidget({
    super.key,
    this.onTap,
    this.compact = false,
  });

  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return _QuickAddTile(
      label: 'Add Income',
      subtitle: compact ? null : 'Money in',
      icon: Icons.arrow_downward_rounded,
      color: AppColors.income,
      onTap: onTap ??
          () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AddTransactionScreen(
                    initialType: TransactionType.income,
                  ),
                ),
              ),
      compact: compact,
    );
  }
}

/// Tappable card to quickly add an expense.
class QuickAddExpenseWidget extends StatelessWidget {
  const QuickAddExpenseWidget({
    super.key,
    this.onTap,
    this.compact = false,
  });

  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return _QuickAddTile(
      label: 'Add Expense',
      subtitle: compact ? null : 'Money out',
      icon: Icons.arrow_upward_rounded,
      color: AppColors.expense,
      onTap: onTap ??
          () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AddTransactionScreen(
                    initialType: TransactionType.expense,
                  ),
                ),
              ),
      compact: compact,
    );
  }
}

class _QuickAddTile extends StatelessWidget {
  const _QuickAddTile({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.subtitle,
    this.compact = false,
  });

  final String label;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 12 : 16,
            vertical: compact ? 14 : 18,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              Container(
                width: compact ? 40 : 44,
                height: compact ? 40 : 44,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: compact ? 20 : 22),
              ),
              SizedBox(width: compact ? 10 : 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w700,
                        fontSize: compact ? 14 : 15,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.add_circle_outline,
                color: color.withValues(alpha: 0.8),
                size: compact ? 20 : 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
