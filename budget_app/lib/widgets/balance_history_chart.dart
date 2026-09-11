import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/balance_snapshot.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

/// Line of the balances a bank stated over time for one account.
///
/// These values are history only; they never feed [BudgetProvider.accountBalance].
class BalanceHistoryChart extends StatelessWidget {
  const BalanceHistoryChart({super.key, required this.snapshots});

  /// Snapshots for a single account, oldest first.
  final List<BalanceSnapshot> snapshots;

  @override
  Widget build(BuildContext context) {
    if (snapshots.isEmpty) return const SizedBox.shrink();

    final currency = snapshots.last.currency;

    if (snapshots.length == 1) {
      return _SinglePoint(snapshot: snapshots.single);
    }

    final spots = [
      for (var i = 0; i < snapshots.length; i++)
        FlSpot(i.toDouble(), snapshots[i].balance),
    ];
    final values = snapshots.map((s) => s.balance).toList();
    final minValue = values.reduce(math.min);
    final maxValue = values.reduce(math.max);
    final padding = math.max((maxValue - minValue) * 0.15, maxValue * 0.05 + 1);

    return SizedBox(
      height: 160,
      child: LineChart(
        LineChartData(
          minY: math.max(0, minValue - padding),
          maxY: maxValue + padding,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) =>
                const FlLine(color: AppColors.border, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 52,
                getTitlesWidget: (value, meta) => Text(
                  formatCompactCurrency(value),
                  style: const TextStyle(
                    fontSize: 9,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final index = value.round();
                  if (index < 0 || index >= snapshots.length) {
                    return const SizedBox.shrink();
                  }
                  // Only label the ends so dense histories stay readable.
                  if (index != 0 && index != snapshots.length - 1) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      formatShortDate(snapshots[index].capturedAt),
                      style: const TextStyle(
                        fontSize: 9,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touched) => touched.map((spot) {
                final snapshot = snapshots[spot.x.round()];
                return LineTooltipItem(
                  '${formatAmountWithCurrency(snapshot.balance, currency)}\n'
                  '${formatDate(snapshot.capturedAt)}',
                  const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                );
              }).toList(),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.25,
              preventCurveOverShooting: true,
              color: AppColors.primary,
              barWidth: 3,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                  radius: 3,
                  color: Colors.white,
                  strokeWidth: 2,
                  strokeColor: AppColors.primary,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.primary.withValues(alpha: 0.10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SinglePoint extends StatelessWidget {
  const _SinglePoint({required this.snapshot});

  final BalanceSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.timeline_rounded, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Only ${formatAmountWithCurrency(snapshot.balance, snapshot.currency)} '
              'on ${formatShortDate(snapshot.capturedAt)} so far. '
              'Import another email to see the trend.',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
