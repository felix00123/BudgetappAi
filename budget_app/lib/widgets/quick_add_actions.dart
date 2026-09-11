import 'package:flutter/material.dart';

import '../models/transaction.dart';
import '../screens/add_transaction_screen.dart';
import '../theme/app_theme.dart';
import 'ai_capture_actions.dart';

/// Side-by-side quick actions to add income or expense, plus AI capture.
class QuickAddActions extends StatelessWidget {
  const QuickAddActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
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
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _QuickAddTile(
                label: 'Scan receipt',
                subtitle: 'Photo + AI',
                icon: Icons.photo_camera_rounded,
                color: AppColors.primary,
                onTap: () => AiCaptureActions.captureReceipt(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickAddTile(
                label: 'Say expense',
                subtitle: 'Voice + AI',
                icon: Icons.mic_rounded,
                color: AppColors.secondary,
                onTap: () => AiCaptureActions.captureVoice(context),
              ),
            ),
          ],
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
    final radius = BorderRadius.circular(AppRadius.lg);

    return Material(
      color: AppColors.card,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Ink(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 12 : 14,
            vertical: compact ? 12 : 14,
          ),
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: AppColors.border),
            boxShadow: AppShadows.card,
          ),
          child: Row(
            children: [
              Container(
                width: compact ? 38 : 42,
                height: compact ? 38 : 42,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  boxShadow: AppShadows.glow(color),
                ),
                child: Icon(icon, color: Colors.white, size: compact ? 19 : 21),
              ),
              SizedBox(width: compact ? 10 : 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: compact ? 13.5 : 14.5,
                        letterSpacing: -0.2,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 1),
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
