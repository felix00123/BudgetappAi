import 'package:flutter/material.dart';

import '../models/loan.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

class LoanCard extends StatelessWidget {
  const LoanCard({
    super.key,
    required this.loan,
    this.onTap,
  });

  final Loan loan;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final progress = loan.progress;
    final monthsLeft = loan.monthsRemaining;

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
                    loan.icon ?? '🏦',
                    style: const TextStyle(fontSize: 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loan.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          '${formatCurrency(loan.amountPaidOff)} of ${formatCurrency(loan.principal)} paid',
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
                      color: AppColors.warning,
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
                  color: AppColors.warning,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _Metric(
                      label: 'Balance',
                      value: formatCurrency(loan.remainingBalance),
                    ),
                  ),
                  Expanded(
                    child: _Metric(
                      label: 'Monthly',
                      value: formatCurrency(loan.totalMonthlyPayment),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (loan.isPaidOff)
                const Row(
                  children: [
                    Icon(Icons.check_circle_rounded,
                        size: 14, color: AppColors.income),
                    SizedBox(width: 4),
                    Text(
                      'Paid off!',
                      style: TextStyle(color: AppColors.income, fontSize: 12),
                    ),
                  ],
                )
              else if (monthsLeft != null) ...[
                Row(
                  children: [
                    const Icon(
                      Icons.schedule_rounded,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${formatDuration(monthsLeft)} remaining • ${loan.annualInterestRate.toStringAsFixed(2)}% APR',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ] else
                const Text(
                  'Payment too low to cover interest',
                  style: TextStyle(color: AppColors.expense, fontSize: 12),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
