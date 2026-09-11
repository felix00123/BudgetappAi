import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/expense_draft.dart';
import '../models/transaction.dart';
import '../providers/budget_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'inline_create_sheets.dart';

/// Lets the user edit an AI draft before it becomes a real transaction.
Future<bool> showAiExpenseReviewSheet(
  BuildContext context, {
  required ExpenseDraft draft,
}) async {
  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => _AiExpenseReviewSheet(initial: draft),
  );
  return saved == true;
}

class _AiExpenseReviewSheet extends StatefulWidget {
  const _AiExpenseReviewSheet({required this.initial});

  final ExpenseDraft initial;

  @override
  State<_AiExpenseReviewSheet> createState() => _AiExpenseReviewSheetState();
}

class _AiExpenseReviewSheetState extends State<_AiExpenseReviewSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;

  late TransactionType _type;
  late String _categoryId;
  late String _accountId;
  late DateTime _date;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final draft = widget.initial;
    _type = draft.type;
    _date = draft.date;
    _titleController = TextEditingController(text: draft.title);
    _amountController = TextEditingController(
      text: draft.amount.toStringAsFixed(
        draft.amount == draft.amount.roundToDouble() ? 0 : 2,
      ),
    );
    _noteController = TextEditingController(text: draft.note ?? '');

    final provider = context.read<BudgetProvider>();
    final categories = provider.categoriesForType(_type);
    final accounts = provider.accounts;

    _categoryId = draft.categoryId ??
        (categories.isNotEmpty ? categories.first.id : '');
    _accountId =
        draft.accountId ?? (accounts.isNotEmpty ? accounts.first.id : '');
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
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final kindLabel =
        widget.initial.captureKind == 'voice' ? 'Voice' : 'Receipt';

    if (_categoryId.isEmpty && categories.isNotEmpty) {
      _categoryId = categories.first.id;
    }
    if (_accountId.isEmpty && accounts.isNotEmpty) {
      _accountId = accounts.first.id;
    }

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    widget.initial.captureKind == 'voice'
                        ? Icons.mic_rounded
                        : Icons.receipt_long_rounded,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Confirm $kindLabel expense',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  if (widget.initial.confidence != null)
                    Text(
                      '${(widget.initial.confidence! * 100).round()}%',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Review what the AI found, then save.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 20),
              SegmentedButton<TransactionType>(
                segments: const [
                  ButtonSegment(
                    value: TransactionType.expense,
                    label: Text('Expense'),
                    icon: Icon(Icons.arrow_upward_rounded, size: 16),
                  ),
                  ButtonSegment(
                    value: TransactionType.income,
                    label: Text('Income'),
                    icon: Icon(Icons.arrow_downward_rounded, size: 16),
                  ),
                ],
                selected: {_type},
                onSelectionChanged: (selected) {
                  final type = selected.first;
                  final next = provider.categoriesForType(type);
                  setState(() {
                    _type = type;
                    _categoryId = next.isNotEmpty ? next.first.id : '';
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                textCapitalization: TextCapitalization.sentences,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Enter a title' : null,
              ),
              const SizedBox(height: 12),
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
                  if (v == null || v.isEmpty) return 'Enter an amount';
                  final amount = double.tryParse(v);
                  if (amount == null || amount <= 0) {
                    return 'Enter a valid amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              AccountPickerField(
                accountId: _accountId,
                accounts: accounts,
                onChanged: (id) => setState(() => _accountId = id),
              ),
              const SizedBox(height: 8),
              CategoryPickerField(
                categoryId: _categoryId,
                categories: categories,
                type: _type,
                onChanged: (id) => setState(() => _categoryId = id),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date',
                    suffixIcon: Icon(Icons.calendar_today_rounded),
                  ),
                  child: Text(formatShortDate(_date)),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(labelText: 'Note (optional)'),
                maxLines: 2,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _saving ? null : () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Save'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_categoryId.isEmpty || _accountId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pick an account and category first.'),
          backgroundColor: AppColors.expense,
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final draft = ExpenseDraft(
        title: _titleController.text.trim(),
        amount: double.parse(_amountController.text),
        type: _type,
        categoryId: _categoryId,
        accountId: _accountId,
        date: _date,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
        captureKind: widget.initial.captureKind,
        confidence: widget.initial.confidence,
      );
      await context.read<BudgetProvider>().saveExpenseDraft(draft);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$e'),
          backgroundColor: AppColors.expense,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
