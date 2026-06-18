import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/savings_goal.dart';
import '../providers/budget_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/empty_state.dart';
import '../widgets/goal_card.dart';
import 'add_goal_screen.dart';
import 'progress_widget_setup_screen.dart';

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Savings Goals'),
        actions: [
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ProgressWidgetSetupScreen(),
              ),
            ),
            icon: const Icon(Icons.widgets_outlined),
            tooltip: 'Home screen widget',
          ),
        ],
      ),
      body: Consumer<BudgetProvider>(
        builder: (context, provider, _) {
          if (provider.goals.isEmpty) {
            return EmptyState(
              icon: Icons.flag_outlined,
              title: 'No savings goals yet',
              subtitle:
                  'Create a goal like buying a car and see how long it will take to reach it',
              action: FilledButton.icon(
                onPressed: () => _openAddGoal(context),
                icon: const Icon(Icons.add),
                label: const Text('Create Goal'),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SavingsOverview(provider: provider),
              const SizedBox(height: 20),
              ...provider.goals.map(
                (g) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GoalCard(
                    goal: g,
                    monthlySavings: provider.monthlySavings,
                    onTap: () => _showGoalDetails(context, g, provider),
                  ),
                ),
              ),
              const SizedBox(height: 80),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddGoal(context),
        icon: const Icon(Icons.add),
        label: const Text('New Goal'),
      ),
    );
  }

  void _openAddGoal(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddGoalScreen()),
    );
  }

  void _showGoalDetails(
    BuildContext context,
    SavingsGoal goal,
    BudgetProvider provider,
  ) {
    final months = goal.monthsToReach(provider.monthlySavings);
    final completion = goal.estimatedCompletionDate(provider.monthlySavings);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).padding.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(goal.icon ?? '🎯', style: const TextStyle(fontSize: 36)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    goal.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _DetailRow('Target', formatCurrency(goal.targetAmount)),
            _DetailRow('Saved', formatCurrency(goal.currentSaved)),
            _DetailRow('Remaining', formatCurrency(goal.remaining)),
            _DetailRow('Progress', '${(goal.progress * 100).toStringAsFixed(0)}%'),
            if (months != null && months > 0) ...[
              _DetailRow('Time to goal', formatDuration(months)),
              if (completion != null)
                _DetailRow('Estimated date', formatDate(completion)),
              _DetailRow(
                'At savings rate',
                '${formatCurrency(provider.monthlySavings)}/month',
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddGoalScreen(existing: goal),
                        ),
                      );
                    },
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showAddSavingsDialog(context, goal, provider);
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add Savings'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await provider.deleteGoal(goal.id);
                },
                style: TextButton.styleFrom(foregroundColor: AppColors.expense),
                child: const Text('Delete Goal'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddSavingsDialog(
    BuildContext context,
    SavingsGoal goal,
    BudgetProvider provider,
  ) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Add to ${goal.name}'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
          ],
          decoration: const InputDecoration(
            labelText: 'Amount',
            prefixText: '\$ ',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final amount = double.tryParse(controller.text);
              if (amount != null && amount > 0) {
                await provider.addToGoal(goal.id, amount);
                if (context.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class _SavingsOverview extends StatelessWidget {
  const _SavingsOverview({required this.provider});

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
              'Monthly Savings Rate',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              formatCurrency(provider.monthlySavings),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              provider.monthlySavings > 0
                  ? 'Based on this month\'s income and expenses'
                  : 'Add transactions to calculate your savings rate',
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

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
