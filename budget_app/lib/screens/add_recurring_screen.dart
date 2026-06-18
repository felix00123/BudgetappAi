import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/recurring_transaction.dart';
import '../models/transaction.dart';
import '../providers/budget_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/inline_create_sheets.dart';

class AddRecurringScreen extends StatefulWidget {
  const AddRecurringScreen({super.key, this.existing});

  final RecurringTransaction? existing;

  @override
  State<AddRecurringScreen> createState() => _AddRecurringScreenState();
}

class _AddRecurringScreenState extends State<AddRecurringScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  late TransactionType _type;
  late RecurrenceFrequency _frequency;
  String _categoryId = '';
  String _accountId = '';
  int _dayOfMonth = 1;
  int _dayOfWeek = DateTime.monday;
  int _monthOfYear = DateTime.now().month;
  DateTime _startDate = DateTime.now();
  bool _isActive = true;

  bool get isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _type = existing.type;
      _frequency = existing.frequency;
      _categoryId = existing.categoryId;
      _accountId = existing.accountId;
      _dayOfMonth = existing.dayOfMonth;
      _dayOfWeek = existing.dayOfWeek;
      _monthOfYear = existing.monthOfYear;
      _startDate = existing.startDate;
      _isActive = existing.isActive;
      _titleController.text = existing.title;
      _amountController.text = existing.amount.toString();
      _noteController.text = existing.note ?? '';
    } else {
      _type = TransactionType.income;
      _frequency = RecurrenceFrequency.monthly;
      _dayOfMonth = DateTime.now().day;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BudgetProvider>();
    final categories = provider.categoriesForType(_type);
    final accounts = provider.accounts;

    if (_categoryId.isEmpty && categories.isNotEmpty) {
      _categoryId = categories.first.id;
    }
    if (_accountId.isEmpty && accounts.isNotEmpty) {
      _accountId = accounts.first.id;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Recurring' : 'New Recurring'),
        actions: [
          if (isEditing)
            IconButton(
              onPressed: _delete,
              icon: const Icon(Icons.delete_outline),
              color: AppColors.expense,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            SegmentedButton<TransactionType>(
              segments: const [
                ButtonSegment(
                  value: TransactionType.income,
                  label: Text('Income'),
                  icon: Icon(Icons.arrow_downward_rounded),
                ),
                ButtonSegment(
                  value: TransactionType.expense,
                  label: Text('Expense'),
                  icon: Icon(Icons.arrow_upward_rounded),
                ),
              ],
              selected: {_type},
              onSelectionChanged: (selection) {
                setState(() {
                  _type = selection.first;
                  _categoryId = '';
                });
              },
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Title',
                hintText: _type == TransactionType.income
                    ? 'e.g. Salary'
                    : 'e.g. Rent',
              ),
              textCapitalization: TextCapitalization.sentences,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Enter a title' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixText: '\$ ',
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              validator: (v) {
                if (v == null || v.isEmpty) return 'Enter amount';
                final amount = double.tryParse(v);
                if (amount == null || amount <= 0) return 'Enter a valid amount';
                return null;
              },
            ),
            const SizedBox(height: 20),
            const Text(
              'Frequency',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            SegmentedButton<RecurrenceFrequency>(
              segments: RecurrenceFrequency.values
                  .map(
                    (f) => ButtonSegment(
                      value: f,
                      label: Text(frequencyLabel(f)),
                    ),
                  )
                  .toList(),
              selected: {_frequency},
              onSelectionChanged: (selection) {
                setState(() => _frequency = selection.first);
              },
            ),
            const SizedBox(height: 16),
            if (_frequency == RecurrenceFrequency.monthly)
              _DayOfMonthPicker(
                day: _dayOfMonth,
                onChanged: (day) => setState(() => _dayOfMonth = day),
              )
            else if (_frequency == RecurrenceFrequency.weekly)
              _DayOfWeekPicker(
                day: _dayOfWeek,
                onChanged: (day) => setState(() => _dayOfWeek = day),
              )
            else
              _YearlyPicker(
                month: _monthOfYear,
                day: _dayOfMonth,
                onMonthChanged: (m) => setState(() => _monthOfYear = m),
                onDayChanged: (d) => setState(() => _dayOfMonth = d),
              ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Start date'),
              subtitle: Text(formatDate(_startDate)),
              trailing: const Icon(Icons.calendar_today_outlined),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _startDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                );
                if (picked != null) setState(() => _startDate = picked);
              },
            ),
            const SizedBox(height: 16),
            CategoryPickerField(
              categoryId: _categoryId,
              categories: categories,
              type: _type,
              onChanged: (id) => setState(() => _categoryId = id),
            ),
            const SizedBox(height: 16),
            AccountPickerField(
              accountId: _accountId,
              accounts: accounts,
              onChanged: (id) => setState(() => _accountId = id),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
              ),
              maxLines: 2,
            ),
            if (isEditing) ...[
              const SizedBox(height: 16),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Active'),
                subtitle: const Text('Paused items are not auto-added'),
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v),
              ),
            ],
            const SizedBox(height: 24),
            _SchedulePreview(
              type: _type,
              amount: double.tryParse(_amountController.text) ?? 0,
              frequency: _frequency,
              dayOfMonth: _dayOfMonth,
              dayOfWeek: _dayOfWeek,
              monthOfYear: _monthOfYear,
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                isEditing ? 'Update Recurring' : 'Create Recurring',
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
    if (_categoryId.isEmpty || _accountId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a category and account')),
      );
      return;
    }

    final provider = context.read<BudgetProvider>();
    final recurring = RecurringTransaction(
      id: widget.existing?.id ?? const Uuid().v4(),
      title: _titleController.text.trim(),
      amount: double.parse(_amountController.text),
      type: _type,
      categoryId: _categoryId,
      accountId: _accountId,
      frequency: _frequency,
      dayOfMonth: _dayOfMonth,
      dayOfWeek: _dayOfWeek,
      monthOfYear: _monthOfYear,
      startDate: _startDate,
      isActive: _isActive,
      lastGeneratedDate: widget.existing?.lastGeneratedDate,
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
      createdAt: widget.existing?.createdAt ?? DateTime.now(),
    );

    if (isEditing) {
      await provider.updateRecurring(recurring);
    } else {
      await provider.addRecurring(recurring);
    }

    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete recurring?'),
        content: const Text(
          'Future automatic entries will stop. Existing transactions stay.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.expense),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    await context.read<BudgetProvider>().deleteRecurring(widget.existing!.id);
    if (mounted) Navigator.pop(context);
  }
}

class _DayOfMonthPicker extends StatelessWidget {
  const _DayOfMonthPicker({required this.day, required this.onChanged});

  final int day;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int>(
      initialValue: day,
      decoration: const InputDecoration(
        labelText: 'Day of month',
        helperText: 'e.g. 1 = every 1st of the month',
      ),
      items: List.generate(
        31,
        (index) => DropdownMenuItem(
          value: index + 1,
          child: Text(ordinalDay(index + 1)),
        ),
      ),
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    );
  }
}

class _DayOfWeekPicker extends StatelessWidget {
  const _DayOfWeekPicker({required this.day, required this.onChanged});

  final int day;
  final ValueChanged<int> onChanged;

  static const _days = [
    (DateTime.monday, 'Monday'),
    (DateTime.tuesday, 'Tuesday'),
    (DateTime.wednesday, 'Wednesday'),
    (DateTime.thursday, 'Thursday'),
    (DateTime.friday, 'Friday'),
    (DateTime.saturday, 'Saturday'),
    (DateTime.sunday, 'Sunday'),
  ];

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int>(
      initialValue: day,
      decoration: const InputDecoration(labelText: 'Day of week'),
      items: _days
          .map(
            (entry) => DropdownMenuItem(
              value: entry.$1,
              child: Text(entry.$2),
            ),
          )
          .toList(),
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    );
  }
}

class _YearlyPicker extends StatelessWidget {
  const _YearlyPicker({
    required this.month,
    required this.day,
    required this.onMonthChanged,
    required this.onDayChanged,
  });

  final int month;
  final int day;
  final ValueChanged<int> onMonthChanged;
  final ValueChanged<int> onDayChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<int>(
            initialValue: month,
            decoration: const InputDecoration(labelText: 'Month'),
            items: List.generate(
              12,
              (index) => DropdownMenuItem(
                value: index + 1,
                child: Text(formatMonthYear(DateTime(2000, index + 1, 1))),
              ),
            ),
            onChanged: (value) {
              if (value != null) onMonthChanged(value);
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: DropdownButtonFormField<int>(
            initialValue: day,
            decoration: const InputDecoration(labelText: 'Day'),
            items: List.generate(
              31,
              (index) => DropdownMenuItem(
                value: index + 1,
                child: Text('${index + 1}'),
              ),
            ),
            onChanged: (value) {
              if (value != null) onDayChanged(value);
            },
          ),
        ),
      ],
    );
  }
}

class _SchedulePreview extends StatelessWidget {
  const _SchedulePreview({
    required this.type,
    required this.amount,
    required this.frequency,
    required this.dayOfMonth,
    required this.dayOfWeek,
    required this.monthOfYear,
  });

  final TransactionType type;
  final double amount;
  final RecurrenceFrequency frequency;
  final int dayOfMonth;
  final int dayOfWeek;
  final int monthOfYear;

  @override
  Widget build(BuildContext context) {
    if (amount <= 0) return const SizedBox.shrink();

    final preview = RecurringTransaction(
      id: 'preview',
      title: 'Preview',
      amount: amount,
      type: type,
      categoryId: 'cat',
      accountId: 'acc',
      frequency: frequency,
      dayOfMonth: dayOfMonth,
      dayOfWeek: dayOfWeek,
      monthOfYear: monthOfYear,
      startDate: DateTime.now(),
      createdAt: DateTime.now(),
    );

    return Card(
      color: AppColors.primary.withValues(alpha: 0.06),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Schedule preview',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '${preview.scheduleLabel} • ${formatCurrency(amount)}',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 4),
            Text(
              'Transactions are added automatically on each due date when you open the app.',
              style: TextStyle(
                color: AppColors.textSecondary.withValues(alpha: 0.9),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
