import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/savings_goal.dart';
import '../providers/budget_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

class AddGoalScreen extends StatefulWidget {
  const AddGoalScreen({super.key, this.existing});

  final SavingsGoal? existing;

  @override
  State<AddGoalScreen> createState() => _AddGoalScreenState();
}

class _AddGoalScreenState extends State<AddGoalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _targetController = TextEditingController();
  final _savedController = TextEditingController();
  final _noteController = TextEditingController();

  String _selectedIcon = goalIcons.first;
  bool get isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _nameController.text = existing.name;
      _targetController.text = existing.targetAmount.toString();
      _savedController.text = existing.currentSaved.toString();
      _noteController.text = existing.note ?? '';
      _selectedIcon = existing.icon ?? goalIcons.first;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetController.dispose();
    _savedController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BudgetProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Goal' : 'New Savings Goal'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Choose an icon',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: goalIcons.map((icon) {
                final selected = icon == _selectedIcon;
                return GestureDetector(
                  onTap: () => setState(() => _selectedIcon = icon),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primary.withValues(alpha: 0.15)
                          : AppColors.border.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: selected
                          ? Border.all(color: AppColors.primary, width: 2)
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(icon, style: const TextStyle(fontSize: 24)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Goal Name',
                hintText: 'e.g. Buy a car',
              ),
              textCapitalization: TextCapitalization.sentences,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Enter a goal name' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _targetController,
              decoration: const InputDecoration(
                labelText: 'Target Amount',
                prefixText: '\$ ',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              validator: (v) {
                if (v == null || v.isEmpty) return 'Enter target amount';
                final amount = double.tryParse(v);
                if (amount == null || amount <= 0) return 'Enter a valid amount';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _savedController,
              decoration: const InputDecoration(
                labelText: 'Already Saved (optional)',
                prefixText: '\$ ',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
              ),
              maxLines: 2,
            ),
            if (provider.monthlySavings > 0 &&
                _targetController.text.isNotEmpty) ...[
              const SizedBox(height: 24),
              _TimeEstimate(
                targetAmount: double.tryParse(_targetController.text) ?? 0,
                currentSaved: double.tryParse(_savedController.text) ?? 0,
                monthlySavings: provider.monthlySavings,
              ),
            ],
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                isEditing ? 'Update Goal' : 'Create Goal',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<BudgetProvider>();
    final goal = SavingsGoal(
      id: widget.existing?.id ?? const Uuid().v4(),
      name: _nameController.text.trim(),
      targetAmount: double.parse(_targetController.text),
      currentSaved: double.tryParse(_savedController.text) ?? 0,
      createdAt: widget.existing?.createdAt ?? DateTime.now(),
      icon: _selectedIcon,
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
    );

    if (isEditing) {
      await provider.updateGoal(goal);
    } else {
      await provider.addGoal(goal);
    }

    if (mounted) Navigator.pop(context);
  }
}

class _TimeEstimate extends StatelessWidget {
  const _TimeEstimate({
    required this.targetAmount,
    required this.currentSaved,
    required this.monthlySavings,
  });

  final double targetAmount;
  final double currentSaved;
  final double monthlySavings;

  @override
  Widget build(BuildContext context) {
    final remaining = (targetAmount - currentSaved).clamp(0, double.infinity);
    if (remaining <= 0) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: AppColors.income),
              SizedBox(width: 12),
              Text('You\'ve already reached this target amount!'),
            ],
          ),
        ),
      );
    }

    final months = (remaining / monthlySavings).ceil();
    final completion = DateTime.now().add(Duration(days: months * 30));

    return Card(
      color: AppColors.primary.withValues(alpha: 0.06),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.schedule_rounded, color: AppColors.primary, size: 20),
                SizedBox(width: 8),
                Text(
                  'Time Estimate',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'At your current savings rate of ${formatCurrency(monthlySavings)}/month:',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Text(
              '⏱️ ${formatDuration(months)}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            Text(
              '📅 Estimated: ${formatDate(completion)}',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
