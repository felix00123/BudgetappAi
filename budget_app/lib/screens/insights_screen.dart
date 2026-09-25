import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/account.dart';
import '../models/balance_snapshot.dart';
import '../providers/budget_provider.dart';
import '../providers/locale_controller.dart';
import '../services/finance_insights.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/balance_history_chart.dart';
import '../widgets/category_breakdown_chart.dart';
import '../widgets/monthly_spending_chart.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.insights)),
      body: Consumer<BudgetProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final analytics = buildAnalytics(provider.transactions);
          final tracked = provider.accountsWithSnapshots;

          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
            children: [
              _SummaryRow(analytics: analytics),
              const SizedBox(height: 20),
              _SectionHeader(
                title: context.l10n.spendingByCategory,
                trailing: context.l10n.last6Months,
              ),
              const SizedBox(height: 8),
              CategoryBreakdownChart(
                totals: analytics.categoryTotals,
                categories: provider.categories,
              ),
              const SizedBox(height: 20),
              _SectionHeader(title: context.l10n.monthlySpending),
              const SizedBox(height: 8),
              MonthlySpendingChart(values: analytics.monthlyTotals),
              const SizedBox(height: 20),
              _SectionHeader(
                title: context.l10n.bankReportedBalances,
                trailing: tracked.isEmpty
                    ? null
                    : context.l10n.accountsCount(tracked.length),
              ),
              const SizedBox(height: 8),
              if (tracked.isEmpty)
                const _NoBalancesCard()
              else
                ...tracked.map(
                  (account) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _BalanceHistoryCard(
                      account: account,
                      snapshots: provider.snapshotsForAccount(account.id),
                      computedBalance: provider.accountBalance(account.id),
                    ),
                  ),
                ),
              if (analytics.topMerchant != null) ...[
                const SizedBox(height: 8),
                _TopMerchantCard(merchant: analytics.topMerchant!),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.analytics});

  final AnalyticsSnapshot analytics;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _Metric(
            icon: Icons.shopping_bag_outlined,
            label: context.l10n.spent,
            value: formatCurrency(analytics.spending),
            color: AppColors.expense,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _Metric(
            icon: Icons.south_west_rounded,
            label: context.l10n.received,
            value: formatCurrency(analytics.income),
            color: AppColors.income,
          ),
        ),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 21),
            const SizedBox(height: 12),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _BalanceHistoryCard extends StatelessWidget {
  const _BalanceHistoryCard({
    required this.account,
    required this.snapshots,
    required this.computedBalance,
  });

  final Account account;
  final List<BalanceSnapshot> snapshots;

  /// Balance derived from transactions, shown side by side but never replaced.
  final double computedBalance;

  @override
  Widget build(BuildContext context) {
    final latest = snapshots.last;
    final difference = (latest.balance - computedBalance).abs();
    final mismatch = difference > 0.01;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: account.color.withValues(alpha: 0.15),
                  child: Icon(
                    accountTypeIcon(account.type),
                    size: 17,
                    color: account.color,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        account.name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        '${snapshots.length} reading'
                        '${snapshots.length == 1 ? '' : 's'} · '
                        'latest ${formatShortDate(latest.capturedAt)}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _BalanceColumn(
                    label: latest.label,
                    value: formatAmountWithCurrency(latest.balance, latest.currency),
                    color: AppColors.primary,
                  ),
                ),
                Expanded(
                  child: _BalanceColumn(
                    label: 'From transactions',
                    value: formatCurrency(computedBalance),
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            if (mismatch) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      size: 17,
                      color: AppColors.warning,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'The bank and your transactions differ by '
                        '${formatCurrency(difference)}. Nothing was changed.',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 8),
            BalanceHistoryChart(snapshots: snapshots),
          ],
        ),
      ),
    );
  }
}

class _BalanceColumn extends StatelessWidget {
  const _BalanceColumn({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: color),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
        ),
      ],
    );
  }
}

class _NoBalancesCard extends StatelessWidget {
  const _NoBalancesCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(
              Icons.mark_email_read_outlined,
              size: 32,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 12),
            const Text(
              'No bank balances yet',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            const Text(
              'Paste a bank alert email under Import & Export to start tracking '
              'the balance your bank reports.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopMerchantCard extends StatelessWidget {
  const _TopMerchantCard({required this.merchant});

  final String merchant;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.primary.withValues(alpha: 0.06),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.storefront_outlined, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                  children: [
                    const TextSpan(text: 'You spend the most at '),
                    TextSpan(
                      text: merchant,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const TextSpan(text: '.'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.trailing});

  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        if (trailing != null)
          Text(
            trailing!,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
      ],
    );
  }
}
