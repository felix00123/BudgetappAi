import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_navigation.dart';
import '../providers/budget_provider.dart';
import '../providers/locale_controller.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/account_summary_card.dart';
import '../widgets/ai_capture_actions.dart';
import '../widgets/balance_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/goal_card.dart';
import '../widgets/language_picker.dart';
import '../widgets/loan_card.dart';
import '../widgets/quick_add_actions.dart';
import '../widgets/stat_card.dart';
import '../widgets/tracking_activity_section.dart';
import '../widgets/transaction_tile.dart';
import 'add_transaction_screen.dart';
import 'data_screen.dart';
import 'goals_screen.dart';
import 'insights_screen.dart';
import 'loans_screen.dart';
import 'manage_screen.dart';
import '../models/transaction.dart';

/// Small tonal icon button used in the home header.
class _HeaderButton extends StatelessWidget {
  const _HeaderButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: Ink(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(color: AppColors.border),
            ),
            child: Icon(icon, size: 18, color: AppColors.textPrimary),
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: Consumer<BudgetProvider>(
          builder: (context, provider, _) {
            final l10n = context.l10n;
            if (provider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.greeting,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.6,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    formatMonthYear(DateTime.now()),
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _HeaderButton(
                                  icon: Icons.translate_rounded,
                                  tooltip: l10n.languageLabel,
                                  onTap: () => showLanguagePickerSheet(context),
                                ),
                                const SizedBox(width: 8),
                                _HeaderButton(
                                  icon: Icons.insights_rounded,
                                  tooltip: l10n.insights,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const InsightsScreen(),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _HeaderButton(
                                  icon: Icons.tune_rounded,
                                  tooltip: l10n.categoriesAndAccounts,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const ManageScreen(),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _HeaderButton(
                                  icon: Icons.swap_vert_rounded,
                                  tooltip: l10n.importAndExport,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const DataScreen(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        BalanceCard(
                          balance: provider.balance,
                          income: provider.totalIncome,
                          expenses: provider.totalExpenses,
                        ),
                        const SizedBox(height: 16),
                        const QuickAddActions(),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: StatCard(
                                title: l10n.thisMonthIncome,
                                value: provider.monthlyIncome,
                                icon: Icons.trending_up_rounded,
                                color: AppColors.income,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: StatCard(
                                title: l10n.thisMonthExpenses,
                                value: provider.monthlyExpenses,
                                icon: Icons.trending_down_rounded,
                                color: AppColors.expense,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        StatCard(
                          title: l10n.monthlySavings,
                          value: provider.monthlySavings,
                          icon: Icons.savings_outlined,
                          color: provider.monthlySavings >= 0
                              ? AppColors.secondary
                              : AppColors.warning,
                        ),
                        const SizedBox(height: 24),
                        const TrackingActivitySection(),
                        if (provider.expensesByCategory.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          _ExpenseChart(categories: provider.expensesByCategory),
                        ],
                        const SizedBox(height: 24),
                        const AccountSummaryCard(),
                        if (provider.goals.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                l10n.savingsGoals,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              TextButton(
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const GoalsScreen(),
                                  ),
                                ),
                                child: Text(l10n.seeAll),
                              ),
                            ],
                          ),
                          ...provider.goals.take(2).map(
                                (g) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: GoalCard(
                                    goal: g,
                                    monthlySavings: provider.monthlySavings,
                                  ),
                                ),
                              ),
                        ],
                        if (provider.activeLoans.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                l10n.loans,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              TextButton(
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const LoansScreen(),
                                  ),
                                ),
                                child: Text(l10n.seeAll),
                              ),
                            ],
                          ),
                          ...provider.activeLoans.take(2).map(
                                (loan) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: LoanCard(loan: loan),
                                ),
                              ),
                        ],
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              l10n.recentTransactions,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextButton(
                              onPressed: () =>
                                  context.read<AppNavigation>().navigateTo(1),
                              child: Text(l10n.seeAll),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                if (provider.recentTransactions.isEmpty)
                  SliverPadding(
                    padding: EdgeInsets.only(
                      bottom: HomeFloatingQuickActions.contentInset(context),
                    ),
                    sliver: SliverFillRemaining(
                      hasScrollBody: false,
                      child: EmptyState(
                        icon: Icons.receipt_long_outlined,
                        title: l10n.noTransactionsYet,
                        subtitle: l10n.noTransactionsYetBody,
                        action: FilledButton.icon(
                          onPressed: () => _openAddTransaction(
                            context,
                            type: TransactionType.expense,
                          ),
                          icon: const Icon(Icons.add),
                          label: Text(l10n.addTransaction),
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      0,
                      16,
                      HomeFloatingQuickActions.contentInset(context),
                    ),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final t = provider.recentTransactions[index];
                          return TransactionTile(
                            transaction: t,
                            onDelete: () => provider.deleteTransaction(t.id),
                          );
                        },
                        childCount: provider.recentTransactions.length,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: HomeFloatingQuickActions(
        onIncome: () => _openAddTransaction(
          context,
          type: TransactionType.income,
        ),
        onExpense: () => _openAddTransaction(
          context,
          type: TransactionType.expense,
        ),
        onPhoto: () => AiCaptureActions.captureReceiptFromCamera(context),
      ),
    );
  }

  void _openAddTransaction(BuildContext context, {TransactionType? type}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddTransactionScreen(initialType: type),
      ),
    );
  }
}

class _ExpenseChart extends StatelessWidget {
  const _ExpenseChart({required this.categories});

  final Map<String, double> categories;

  static const _colors = [
    AppColors.primary,
    AppColors.expense,
    AppColors.warning,
    AppColors.secondary,
    AppColors.primaryLight,
    Color(0xFF8B5CF6),
    Color(0xFFEC4899),
  ];

  @override
  Widget build(BuildContext context) {
    final entries = categories.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = entries.fold(0.0, (sum, e) => sum + e.value);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.expensesByCategory,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 160,
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 30,
                        sections: [
                          for (var i = 0; i < entries.length && i < 7; i++)
                            PieChartSectionData(
                              value: entries[i].value,
                              color: _colors[i % _colors.length],
                              radius: 40,
                              title: '',
                            ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (var i = 0; i < entries.length && i < 5; i++)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: _colors[i % _colors.length],
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    entries[i].key,
                                    style: const TextStyle(fontSize: 12),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  '${(entries[i].value / total * 100).toStringAsFixed(0)}%',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
