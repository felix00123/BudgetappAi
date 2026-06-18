import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/formatters.dart';

/// GitHub-style contribution grid showing activity per day.
class ActivityHeatmap extends StatelessWidget {
  const ActivityHeatmap({
    super.key,
    required this.activityCounts,
    required this.color,
    this.weeks = 20,
    this.endDate,
    this.cellSize = 12,
    this.cellSpacing = 3,
    this.emptyColor,
    this.onDayTap,
  });

  /// yyyy-MM-dd keys mapped to activity count for that day.
  final Map<String, int> activityCounts;
  final Color color;
  final int weeks;
  final DateTime? endDate;
  final double cellSize;
  final double cellSpacing;
  final Color? emptyColor;
  final ValueChanged<DateTime>? onDayTap;

  static DateTime dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  double get _gridHeight => cellSize * 7 + cellSpacing * 6;

  @override
  Widget build(BuildContext context) {
    final today = dateOnly(endDate ?? DateTime.now());
    final grid = _buildGrid(today);
    final empty = emptyColor ?? AppColors.border.withValues(alpha: 0.65);
    final gridWidth = grid.length * (cellSize + cellSpacing);

    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width - 72;

        return SizedBox(
          height: _gridHeight,
          width: viewportWidth,
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(
              scrollbars: false,
              overscroll: false,
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              reverse: true,
              primary: false,
              physics: const BouncingScrollPhysics(),
              child: SizedBox(
                height: _gridHeight,
                width: gridWidth < viewportWidth ? viewportWidth : gridWidth,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final week in grid)
                      Padding(
                        padding: EdgeInsets.only(right: cellSpacing),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (final day in week)
                              Padding(
                                padding: EdgeInsets.only(bottom: cellSpacing),
                                child: _HeatmapCell(
                                  date: day.date,
                                  count: day.count,
                                  isToday: day.isToday,
                                  isFuture: day.isFuture,
                                  color: color,
                                  emptyColor: empty,
                                  size: cellSize,
                                  onTap: onDayTap,
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  List<List<_DayCell>> _buildGrid(DateTime today) {
    final totalDays = weeks * 7;
    final start = today.subtract(Duration(days: totalDays - 1));
    final alignedStart = _alignToWeekStart(start);
    final columns = <List<_DayCell>>[];

    var cursor = alignedStart;
    while (cursor.isBefore(today.add(const Duration(days: 1))) ||
        columns.length < weeks) {
      final week = <_DayCell>[];
      for (var i = 0; i < 7; i++) {
        final day = dateOnly(cursor);
        week.add(
          _DayCell(
            date: day,
            count: activityCounts[dateKey(day)] ?? 0,
            isToday: day == today,
            isFuture: day.isAfter(today),
          ),
        );
        cursor = cursor.add(const Duration(days: 1));
      }
      columns.add(week);
      if (cursor.isAfter(today.add(const Duration(days: 7)))) break;
    }

    if (columns.length > weeks) {
      return columns.sublist(columns.length - weeks);
    }
    return columns;
  }

  DateTime _alignToWeekStart(DateTime date) {
    final weekday = date.weekday;
    return dateOnly(date.subtract(Duration(days: weekday - 1)));
  }
}

class _DayCell {
  const _DayCell({
    required this.date,
    required this.count,
    required this.isToday,
    required this.isFuture,
  });

  final DateTime date;
  final int count;
  final bool isToday;
  final bool isFuture;
}

class _HeatmapCell extends StatelessWidget {
  const _HeatmapCell({
    required this.date,
    required this.count,
    required this.isToday,
    required this.isFuture,
    required this.color,
    required this.emptyColor,
    required this.size,
    this.onTap,
  });

  final DateTime date;
  final int count;
  final bool isToday;
  final bool isFuture;
  final Color color;
  final Color emptyColor;
  final double size;
  final ValueChanged<DateTime>? onTap;

  @override
  Widget build(BuildContext context) {
    final fill = _fillColor();

    return Semantics(
      label: _tooltipMessage(),
      button: onTap != null && !isFuture,
      child: GestureDetector(
        onTap: isFuture || onTap == null ? null : () => onTap!(date),
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(3),
            border: isToday
                ? Border.all(color: color, width: 1.5)
                : Border.all(
                    color: emptyColor.withValues(alpha: 0.35),
                    width: 0.5,
                  ),
          ),
        ),
      ),
    );
  }

  Color _fillColor() {
    if (isFuture) return emptyColor.withValues(alpha: 0.25);
    if (count <= 0) return emptyColor;

    if (count == 1) return color.withValues(alpha: 0.4);
    if (count <= 3) return color.withValues(alpha: 0.7);
    return color;
  }

  String _tooltipMessage() {
    if (isFuture) return formatDate(date);
    if (count <= 0) return '${formatDate(date)}, no entries';
    return '${formatDate(date)}, $count ${count == 1 ? 'entry' : 'entries'}';
  }
}

/// Legend showing intensity levels for the heatmap.
class ActivityHeatmapLegend extends StatelessWidget {
  const ActivityHeatmapLegend({
    super.key,
    required this.color,
    this.emptyColor,
  });

  final Color color;
  final Color? emptyColor;

  @override
  Widget build(BuildContext context) {
    final empty = emptyColor ?? AppColors.border.withValues(alpha: 0.65);
    final levels = [
      empty,
      color.withValues(alpha: 0.4),
      color.withValues(alpha: 0.7),
      color,
    ];

    return Row(
      children: [
        const Text(
          'Less',
          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
        const SizedBox(width: 6),
        for (final level in levels)
          Container(
            width: 12,
            height: 12,
            margin: const EdgeInsets.only(right: 3),
            decoration: BoxDecoration(
              color: level,
              borderRadius: BorderRadius.circular(3),
              border: Border.all(
                color: empty.withValues(alpha: 0.35),
                width: 0.5,
              ),
            ),
          ),
        const SizedBox(width: 3),
        const Text(
          'More',
          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
