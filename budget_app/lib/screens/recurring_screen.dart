import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/recurring_transaction.dart';
import '../models/transaction.dart';
import '../providers/budget_provider.dart';
import '../providers/locale_controller.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/empty_state.dart';
import '../widgets/recurring_card.dart';
import 'add_recurring_screen.dart';

class RecurringScreen extends StatelessWidget {
  const RecurringScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.recurring),
      ),
      body: Consumer<BudgetProvider>(
        builder: (context, provider, _) {
          if (provider.recurring.isEmpty) {
            return EmptyState(
              icon: Icons.event_repeat_rounded,
              title: l10n.noRecurringYet,
              subtitle: l10n.noRecurringYetBody,
              action: FilledButton.icon(
                onPressed: () => _openAdd(context),
                icon: const Icon(Icons.add),
                label: Text(l10n.addRecurring),
              ),
            );
          }

          final income = provider.recurring
              .where((r) => r.type == TransactionType.income)
              .toList();
          final expenses = provider.recurring
              .where((r) => r.type == TransactionType.expense)
              .toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _RecurringOverview(provider: provider),
              if (income.isNotEmpty) ...[
                const SizedBox(height: 20),
                const _SectionHeader(
                  title: 'Recurring Income',
                  color: AppColors.income,
                ),
                ...income.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: RecurringCard(
                      recurring: item,
                      categoryName: provider.categoryName(item.categoryId),
                      accountName: provider.accountName(item.accountId),
                      onTap: () => _openEdit(context, item),
                      onToggle: (active) =>
                          provider.setRecurringActive(item.id, active),
                    ),
                  ),
                ),
              ],
              if (expenses.isNotEmpty) ...[
                const SizedBox(height: 8),
                const _SectionHeader(
                  title: 'Recurring Expenses',
                  color: AppColors.expense,
                ),
                ...expenses.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: RecurringCard(
                      recurring: item,
                      categoryName: provider.categoryName(item.categoryId),
                      accountName: provider.accountName(item.accountId),
                      onTap: () => _openEdit(context, item),
                      onToggle: (active) =>
                          provider.setRecurringActive(item.id, active),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 80),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'recurring-fab',
        onPressed: () => _openAdd(context),
        icon: const Icon(Icons.add),
        label: Text(l10n.addRecurring),
      ),
    );
  }

  void _openAdd(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddRecurringScreen()),
    );
  }

  void _openEdit(BuildContext context, RecurringTransaction item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddRecurringScreen(existing: item),
      ),
    );
  }
}

class _RecurringOverview extends StatelessWidget {
  const _RecurringOverview({required this.provider});

  final BudgetProvider provider;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.primary,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Expected each month',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Income',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        formatCurrency(provider.expectedMonthlyRecurringIncome),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Expenses',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        formatCurrency(provider.expectedMonthlyRecurringExpenses),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${provider.activeRecurring.length} active schedule${provider.activeRecurring.length == 1 ? '' : 's'}',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.color});

  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
