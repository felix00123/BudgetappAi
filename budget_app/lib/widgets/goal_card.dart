import 'package:flutter/material.dart';

import '../models/savings_goal.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

class GoalCard extends StatelessWidget {
  const GoalCard({
    super.key,
    required this.goal,
    required this.monthlySavings,
    this.onTap,
  });

  final SavingsGoal goal;
  final double monthlySavings;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final months = goal.monthsToReach(monthlySavings);
    final progress = goal.progress;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    goal.icon ?? '🎯',
                    style: const TextStyle(fontSize: 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          goal.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          '${formatCurrency(goal.currentSaved)} of ${formatCurrency(goal.targetAmount)}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${(progress * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: AppColors.border,
                  color: AppColors.primary,
                ),
              ),
              if (months != null && months > 0) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(
                      Icons.schedule_rounded,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${formatDuration(months)} at current savings rate',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ] else if (goal.remaining <= 0) ...[
                const SizedBox(height: 10),
                const Row(
                  children: [
                    Icon(Icons.check_circle_rounded, size: 14, color: AppColors.income),
                    SizedBox(width: 4),
                    Text(
                      'Goal reached!',
                      style: TextStyle(color: AppColors.income, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
