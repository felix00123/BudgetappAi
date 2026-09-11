import 'package:flutter/material.dart';

import '../models/transaction.dart';
import '../screens/add_transaction_screen.dart';
import '../theme/app_theme.dart';
import 'ai_capture_actions.dart';
import 'app_nav_bar.dart';

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

/// Compact floating dock above the nav: income, photo, expense.
class HomeFloatingQuickActions extends StatelessWidget {
  const HomeFloatingQuickActions({
    super.key,
    required this.onIncome,
    required this.onExpense,
    required this.onPhoto,
  });

  final VoidCallback onIncome;
  final VoidCallback onExpense;
  final VoidCallback onPhoto;

  /// Extra scroll padding so list content clears this dock + nav bar.
  static double contentInset(BuildContext context) =>
      AppNavBar.contentInset(context) + 72;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppNavBar.reservedHeight(context) + 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          boxShadow: AppShadows.floating,
        ),
        child: Material(
          color: AppColors.card.withValues(alpha: 0.94),
          shape: StadiumBorder(
            side: BorderSide(color: AppColors.border.withValues(alpha: 0.9)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _DockAction(
                  tooltip: 'Add income',
                  icon: Icons.south_west_rounded,
                  background: AppColors.income,
                  onTap: onIncome,
                ),
                const SizedBox(width: 8),
                _DockAction(
                  tooltip: 'Take photo',
                  icon: Icons.photo_camera_rounded,
                  background: AppColors.primary,
                  emphasized: true,
                  onTap: onPhoto,
                ),
                const SizedBox(width: 8),
                _DockAction(
                  tooltip: 'Add expense',
                  icon: Icons.north_east_rounded,
                  background: AppColors.expense,
                  onTap: onExpense,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DockAction extends StatelessWidget {
  const _DockAction({
    required this.tooltip,
    required this.icon,
    required this.background,
    required this.onTap,
    this.emphasized = false,
  });

  final String tooltip;
  final IconData icon;
  final Color background;
  final VoidCallback onTap;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final size = emphasized ? 52.0 : 44.0;
    final iconSize = emphasized ? 24.0 : 20.0;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: background,
        shape: const CircleBorder(),
        elevation: emphasized ? 2 : 0,
        shadowColor: background.withValues(alpha: 0.45),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(icon, color: Colors.white, size: iconSize),
          ),
        ),
      ),
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
