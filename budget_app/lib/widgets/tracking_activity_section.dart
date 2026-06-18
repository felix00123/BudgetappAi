import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/transaction.dart';
import '../providers/budget_provider.dart';
import '../screens/add_transaction_screen.dart';
import '../theme/app_theme.dart';
import 'tracking_activity_card.dart';

class TrackingActivitySection extends StatelessWidget {
  const TrackingActivitySection({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BudgetProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Logging Activity',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        const Text(
          'See how consistently you track your finances',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 12),
        TrackingActivityCard(
          icon: Icons.receipt_long_rounded,
          title: 'Log Transactions',
          subtitle: 'Record income and expenses daily',
          color: AppColors.primary,
          activityCounts: provider.dailyActivityCounts,
          completedToday: provider.loggedToday,
          onCheckTap: () => _openAddTransaction(context, null),
        ),
        const SizedBox(height: 12),
        TrackingActivityCard(
          icon: Icons.arrow_downward_rounded,
          title: 'Track Income',
          subtitle: 'Log when money comes in',
          color: AppColors.income,
          activityCounts: provider.dailyIncomeCounts,
          completedToday: provider.loggedIncomeToday,
          onCheckTap: () => _openAddTransaction(context, TransactionType.income),
        ),
        const SizedBox(height: 12),
        TrackingActivityCard(
          icon: Icons.arrow_upward_rounded,
          title: 'Track Expenses',
          subtitle: 'Log when money goes out',
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
