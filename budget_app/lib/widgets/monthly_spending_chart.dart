import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../theme/app_theme.dart';
import '../utils/formatters.dart';

/// Month-by-month spending bars, with the current month highlighted.
class MonthlySpendingChart extends StatelessWidget {
  const MonthlySpendingChart({super.key, required this.values});

  /// Expense totals per month, oldest first.
  final Map<DateTime, double> values;

  @override
  Widget build(BuildContext context) {
    final maxValue = values.values.fold(0.0, math.max);
    final currentMonth = DateTime.now();

    return Card(
      child: SizedBox(
        height: 186,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 18, 14, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final entry in values.entries)
                Expanded(
                  child: _MonthBar(
                    month: entry.key,
                    amount: entry.value,
                    ratio: maxValue <= 0 ? 0 : entry.value / maxValue,
                    isCurrent: entry.key.year == currentMonth.year &&
                        entry.key.month == currentMonth.month,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MonthBar extends StatelessWidget {
  const _MonthBar({
    required this.month,
    required this.amount,
    required this.ratio,
    required this.isCurrent,
  });

  static const _maxBarHeight = 104.0;

  final DateTime month;
  final double amount;
  final double ratio;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            amount <= 0 ? '' : formatCompactCurrency(amount),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 9,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: ratio),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) => Container(
              height: math.max(4, _maxBarHeight * value),
              decoration: BoxDecoration(
                color: isCurrent ? AppColors.primary : AppColors.primaryLight,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            DateFormat.MMM().format(month),
            style: TextStyle(
              fontSize: 10,
              color: isCurrent ? AppColors.textPrimary : AppColors.textSecondary,
              fontWeight: isCurrent ? FontWeight.w700 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
