import 'package:flutter/material.dart';

import '../models/category.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

/// Horizontal ranking of spending per category, widest bar first.
class CategoryBreakdownChart extends StatelessWidget {
  const CategoryBreakdownChart({
    super.key,
    required this.totals,
    required this.categories,
    this.maxEntries = 6,
  });

  /// Expense totals per category id, already sorted highest first.
  final Map<String, double> totals;
  final List<BudgetCategory> categories;
  final int maxEntries;

  BudgetCategory? _categoryById(String id) {
    for (final c in categories) {
      if (c.id == id) return c;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final entries = totals.entries.take(maxEntries).toList();
    if (entries.isEmpty) {
      return const _EmptyChart(
        icon: Icons.donut_large_outlined,
        title: 'No categorized spending yet',
        message: 'Import a bank email or add an expense to fill this in.',
      );
    }

    final maxValue = entries.first.value;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            for (final entry in entries) ...[
              _CategoryRow(
                category: _categoryById(entry.key),
                amount: entry.value,
                ratio: maxValue <= 0 ? 0 : entry.value / maxValue,
              ),
              if (entry != entries.last) const SizedBox(height: 14),
            ],
          ],
        ),
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.category,
    required this.amount,
    required this.ratio,
  });

  final BudgetCategory? category;
  final double amount;
  final double ratio;

  @override
  Widget build(BuildContext context) {
    final color = category?.color ?? AppColors.textSecondary;

    return Row(
      children: [
        SizedBox(
          width: 104,
          child: Row(
            children: [
              Icon(
                categoryIconData(category?.icon ?? 'account_balance_wallet'),
                size: 17,
                color: color,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  category?.name ?? 'Uncategorized',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: ratio),
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: 9,
                backgroundColor: AppColors.surface,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(width: 9),
        SizedBox(
          width: 78,
          child: Text(
            formatCurrency(amount),
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}

class _EmptyChart extends StatelessWidget {
  const _EmptyChart({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(icon, size: 32, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
