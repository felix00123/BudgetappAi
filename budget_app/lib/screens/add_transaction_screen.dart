import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/transaction.dart';
import '../providers/budget_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/inline_create_sheets.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({
    super.key,
    this.existing,
    this.initialType,
  });

  final Transaction? existing;
  final TransactionType? initialType;

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  late TransactionType _type;
  String _categoryId = '';
  String _accountId = '';
  late DateTime _date;

  bool get isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _type = existing.type;
      _categoryId = existing.categoryId;
      _accountId = existing.accountId;
      _date = existing.date;
      _titleController.text = existing.title;
      _amountController.text = existing.amount.toString();
      _noteController.text = existing.note ?? '';
    } else {
      _type = widget.initialType ?? TransactionType.expense;
      _date = DateTime.now();
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

    if (categories.isEmpty && accounts.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Add Transaction')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.settings_outlined, size: 48, color: AppColors.primary),
                const SizedBox(height: 16),
                const Text(
                  'Create a category and account first',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'You need at least one of each before adding transactions.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 24),
                if (accounts.isEmpty)
                  FilledButton.icon(
                    onPressed: () async {
                      final id = await showCreateAccountSheet(context);
                      if (id != null && mounted) setState(() => _accountId = id);
                    },
                    icon: const Icon(Icons.account_balance_wallet_outlined),
                    label: const Text('Create Account'),
                  ),
                if (categories.isEmpty) ...[
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final id = await showCreateCategorySheet(context, _type);
                      if (id != null && mounted) setState(() => _categoryId = id);
                    },
                    icon: const Icon(Icons.category_outlined),
                    label: const Text('Create Category'),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    if (categories.isEmpty || accounts.isEmpty) {
      // Allow partial setup with inline create prompts below.
      if (_categoryId.isEmpty && categories.isNotEmpty) {
        _categoryId = categories.first.id;
      }
      if (_accountId.isEmpty && accounts.isNotEmpty) {
        _accountId = accounts.first.id;
      }
    } else if (!isEditing) {
      if (_categoryId.isEmpty || !categories.any((c) => c.id == _categoryId)) {
        _categoryId = categories.first.id;
      }
      if (_accountId.isEmpty || !accounts.any((a) => a.id == _accountId)) {
        _accountId = accounts.first.id;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Transaction' : 'Add Transaction'),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.expense),
              onPressed: _delete,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _TypeToggle(
              type: _type,
              onChanged: (type) {
                final newCategories = provider.categoriesForType(type);
                setState(() {
                  _type = type;
                  _categoryId =
                      newCategories.isNotEmpty ? newCategories.first.id : '';
                });
              },
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'e.g. Grocery shopping',
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
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Enter an amount';
                final amount = double.tryParse(v);
                if (amount == null || amount <= 0) return 'Enter a valid amount';
                return null;
              },
            ),
            const SizedBox(height: 16),
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
            const SizedBox(height: 16),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Date',
                  suffixIcon: Icon(Icons.calendar_today_rounded),
                ),
                child: Text(
                  '${_date.day}/${_date.month}/${_date.year}',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                hintText: 'Add a note...',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: _type == TransactionType.income
                    ? AppColors.income
                    : AppColors.expense,
              ),
              child: Text(
                isEditing ? 'Update Transaction' : 'Save Transaction',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
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
          content: Text('Please select or create a category and account'),
          backgroundColor: AppColors.expense,
        ),
      );
      return;
    }

    final provider = context.read<BudgetProvider>();
    final transaction = Transaction(
      id: widget.existing?.id ?? const Uuid().v4(),
      title: _titleController.text.trim(),
      amount: double.parse(_amountController.text),
      type: _type,
      categoryId: _categoryId,
      accountId: _accountId,
      date: _date,
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
    );

    if (isEditing) {
      await provider.updateTransaction(transaction);
    } else {
      await provider.addTransaction(transaction);
    }

    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: const Text('Are you sure you want to delete this transaction?'),
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

    if (confirm == true && mounted) {
      await context.read<BudgetProvider>().deleteTransaction(widget.existing!.id);
      if (mounted) Navigator.pop(context);
    }
  }
}

class _TypeToggle extends StatelessWidget {
  const _TypeToggle({required this.type, required this.onChanged});

  final TransactionType type;
  final ValueChanged<TransactionType> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.border.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: _ToggleButton(
              label: 'Expense',
              icon: Icons.arrow_upward_rounded,
              color: AppColors.expense,
              selected: type == TransactionType.expense,
              onTap: () => onChanged(TransactionType.expense),
            ),
          ),
          Expanded(
            child: _ToggleButton(
              label: 'Income',
              icon: Icons.arrow_downward_rounded,
              color: AppColors.income,
              selected: type == TransactionType.income,
              onTap: () => onChanged(TransactionType.income),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  const _ToggleButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: selected ? Colors.white : color, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}