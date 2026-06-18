import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/budget_provider.dart';
import '../services/home_widget_service.dart';
import '../theme/app_theme.dart';

enum ProgressWidgetKind { goal, loan }

class ProgressWidgetSetupScreen extends StatefulWidget {
  const ProgressWidgetSetupScreen({super.key});

  @override
  State<ProgressWidgetSetupScreen> createState() =>
      _ProgressWidgetSetupScreenState();
}

class _ProgressWidgetSetupScreenState extends State<ProgressWidgetSetupScreen> {
  ProgressWidgetKind _filter = ProgressWidgetKind.goal;
  String? _selectedType;
  String? _selectedId;

  Future<void> _selectItem({
    required String type,
    required String id,
    required String name,
  }) async {
    await HomeWidgetService.saveWidgetSelection(type: type, itemId: id);
    setState(() {
      _selectedType = type;
      _selectedId = id;
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Widget will track "$name"')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Screen Widget'),
      ),
      body: Consumer<BudgetProvider>(
        builder: (context, provider, _) {
          final goals = provider.goals;
          final loans = provider.loans;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Card(
                color: AppColors.primary.withValues(alpha: 0.06),
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.widgets_outlined, color: AppColors.primary),
                          SizedBox(width: 8),
                          Text(
                            'Progress widget',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Add the "Goal / Loan Progress" widget to your home screen. '
                        'When placing it, you can choose exactly which goal or loan to track.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Android: add widget → pick goal or loan on the spot.\n'
                        'iOS: add widget → long-press → Edit Widget → choose Track (goal or loan).',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SegmentedButton<ProgressWidgetKind>(
                segments: const [
                  ButtonSegment(
                    value: ProgressWidgetKind.goal,
                    label: Text('Goals'),
                    icon: Icon(Icons.flag_outlined),
                  ),
                  ButtonSegment(
                    value: ProgressWidgetKind.loan,
                    label: Text('Loans'),
                    icon: Icon(Icons.account_balance_outlined),
                  ),
                ],
                selected: {_filter},
                onSelectionChanged: (selection) {
                  setState(() => _filter = selection.first);
                },
              ),
              const SizedBox(height: 16),
              if (_filter == ProgressWidgetKind.goal) ...[
                if (goals.isEmpty)
                  const _EmptyHint(
                    message: 'Create a savings goal first, then add the widget.',
                  )
                else
                  ...goals.map(
                    (goal) => _SelectableProgressTile(
                      icon: goal.icon ?? '🎯',
                      name: goal.name,
                      progress: goal.progress,
                      subtitle:
                          '${(goal.progress * 100).toStringAsFixed(0)}% complete',
                      color: AppColors.primary,
                      selected: _selectedType == 'goal' && _selectedId == goal.id,
                      onTap: () => _selectItem(
                        type: 'goal',
                        id: goal.id,
                        name: goal.name,
                      ),
                    ),
                  ),
              ] else ...[
                if (loans.isEmpty)
                  const _EmptyHint(
                    message: 'Create a loan first, then add the widget.',
                  )
                else
                  ...loans.map(
                    (loan) => _SelectableProgressTile(
                      icon: loan.icon ?? '🏦',
                      name: loan.name,
                      progress: loan.progress,
                      subtitle:
                          '${(loan.progress * 100).toStringAsFixed(0)}% paid off',
                      color: AppColors.warning,
                      selected: _selectedType == 'loan' && _selectedId == loan.id,
                      onTap: () => _selectItem(
                        type: 'loan',
                        id: loan.id,
                        name: loan.name,
                      ),
                    ),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _SelectableProgressTile extends StatelessWidget {
  const _SelectableProgressTile({
    required this.icon,
    required this.name,
    required this.progress,
    required this.subtitle,
    required this.color,
    this.selected = false,
    this.onTap,
  });

  final String icon;
  final String name;
  final double progress;
  final String subtitle;
  final Color color;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: selected
            ? BorderSide(color: color, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: AppColors.border,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${(progress * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppColors.textSecondary),
      ),
    );
  }
}
