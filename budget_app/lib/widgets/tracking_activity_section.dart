import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/transaction.dart';
import '../providers/budget_provider.dart';
import '../providers/locale_controller.dart';
import '../screens/add_transaction_screen.dart';
import '../theme/app_theme.dart';
import 'tracking_activity_card.dart';

class TrackingActivitySection extends StatelessWidget {
  const TrackingActivitySection({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BudgetProvider>();
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.loggingActivity,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.loggingActivitySubtitle,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 12),
        TrackingActivityCard(
          icon: Icons.receipt_long_rounded,
          title: l10n.logTransactions,
          subtitle: l10n.logTransactionsSubtitle,
          color: AppColors.primary,
          activityCounts: provider.dailyActivityCounts,
          completedToday: provider.loggedToday,
          onCheckTap: () => _openAddTransaction(context, null),
        ),
        const SizedBox(height: 12),
        TrackingActivityCard(
          icon: Icons.arrow_downward_rounded,
          title: l10n.trackIncome,
          subtitle: l10n.trackIncomeSubtitle,
          color: AppColors.income,
          activityCounts: provider.dailyIncomeCounts,
          completedToday: provider.loggedIncomeToday,
          onCheckTap: () => _openAddTransaction(context, TransactionType.income),
        ),
        const SizedBox(height: 12),
        TrackingActivityCard(
          icon: Icons.arrow_upward_rounded,
          title: l10n.trackExpenses,
          subtitle: l10n.trackExpensesSubtitle,
          color: AppColors.expense,
          activityCounts: provider.dailyExpenseCounts,
          completedToday: provider.loggedExpenseToday,
          onCheckTap: () => _openAddTransaction(context, TransactionType.expense),
        ),
      ],
    );
  }

  void _openAddTransaction(BuildContext context, TransactionType? type) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddTransactionScreen(initialType: type),
      ),
    );
  }
}
