import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'activity_heatmap.dart';

/// HabitKit-style card showing how often a tracking habit is completed.
class TrackingActivityCard extends StatelessWidget {
  const TrackingActivityCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.activityCounts,
    this.weeks = 20,
    this.completedToday = false,
    this.onCheckTap,
    this.onDayTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Map<String, int> activityCounts;
  final int weeks;
  final bool completedToday;
  final VoidCallback? onCheckTap;
  final ValueChanged<DateTime>? onDayTap;

  int get _streak => _calculateStreak(activityCounts);
  int get _activeDays => activityCounts.values.where((c) => c > 0).length;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '$_activeDays days logged · $_streak day streak',
                        style: TextStyle(
                          fontSize: 12,
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onCheckTap != null)
                  _CheckButton(
                    color: color,
                    checked: completedToday,
                    onTap: onCheckTap!,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            ActivityHeatmap(
              activityCounts: activityCounts,
              color: color,
              weeks: weeks,
              onDayTap: onDayTap,
            ),
            const SizedBox(height: 10),
            ActivityHeatmapLegend(color: color),
          ],
        ),
      ),
    );
  }

  static int _calculateStreak(Map<String, int> counts) {
    var streak = 0;
    var day = ActivityHeatmap.dateOnly(DateTime.now());

    while ((counts[dateKey(day)] ?? 0) > 0) {
      streak++;
      day = day.subtract(const Duration(days: 1));
    }
    return streak;
  }
}

class _CheckButton extends StatelessWidget {
  const _CheckButton({
    required this.color,
    required this.checked,
    required this.onTap,
  });

  final Color color;
  final bool checked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: checked ? color : color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          child: Icon(
            checked ? Icons.check_rounded : Icons.add_rounded,
            color: checked ? Colors.white : color,
            size: 26,
          ),
        ),
      ),
    );
  }
}
