import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/account.dart';
import '../models/category.dart';
import '../models/transaction.dart';
import '../providers/budget_provider.dart';
import '../theme/app_theme.dart';

const _newCategoryValue = '__new_category__';
const _newAccountValue = '__new_account__';

/// Shows a bottom sheet to create a category. Returns the new category id.
Future<String?> showCreateCategorySheet(
  BuildContext context,
  TransactionType type,
) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => _CreateCategorySheet(type: type),
  );
}

/// Shows a bottom sheet to create an account. Returns the new account id.
Future<String?> showCreateAccountSheet(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => const _CreateAccountSheet(),
  );
}

class _CreateCategorySheet extends StatefulWidget {
  const _CreateCategorySheet({required this.type});

  final TransactionType type;

  @override
  State<_CreateCategorySheet> createState() => _CreateCategorySheetState();
}

class _CreateCategorySheetState extends State<_CreateCategorySheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  late String _icon;
  late int _colorValue;

  @override
  void initState() {
    super.initState();
    _icon = categoryIconOptions.first;
    _colorValue =
        widget.type == TransactionType.income ? 0xFF22C55E : 0xFFEF4444;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final typeLabel =
        widget.type == TransactionType.income ? 'Income' : 'Expense';

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottom + 20),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'New $typeLabel Category',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Category name',
                  hintText: 'e.g. Subscriptions',
                ),
                textCapitalization: TextCapitalization.sentences,
                autofocus: true,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Enter a name' : null,
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: categoryIconOptions.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final icon = categoryIconOptions[index];
                    final selected = icon == _icon;
                    return GestureDetector(
                      onTap: () => setState(() => _icon = icon),
                      child: Container(
                        width: 44,
                        decoration: BoxDecoration(
                          color: selected
                              ? Color(_colorValue).withValues(alpha: 0.2)
                              : AppColors.border.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(10),
                          border: selected
                              ? Border.all(color: Color(_colorValue), width: 2)
                              : null,
                        ),
                        child: Icon(categoryIconData(icon), size: 22),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _save,
                child: const Text('Create Category'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final category = BudgetCategory(
      id: const Uuid().v4(),
      name: _nameController.text.trim(),
      type: widget.type,
      icon: _icon,
      colorValue: _colorValue,
    );

    await context.read<BudgetProvider>().addCategory(category);
    if (mounted) Navigator.pop(context, category.id);
  }
}

class _CreateAccountSheet extends StatefulWidget {
  const _CreateAccountSheet();

  @override
  State<_CreateAccountSheet> createState() => _CreateAccountSheetState();
}

class _CreateAccountSheetState extends State<_CreateAccountSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController();
  AccountType _type = AccountType.bank;
  int _colorValue = accountColorOptions.first;

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottom + 20),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'New Account',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Account name',
                  hintText: 'e.g. Main Checking',
                ),
                textCapitalization: TextCapitalization.sentences,
                autofocus: true,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Enter a name' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<AccountType>(
                initialValue: _type,
                decoration: const InputDecoration(labelText: 'Account type'),
                items: AccountType.values
                    .map(
                      (t) => DropdownMenuItem(
                        value: t,
                        child: Row(
                          children: [
                            Icon(accountTypeIcon(t), size: 20),
                            const SizedBox(width: 8),
                            Text(accountTypeLabel(t)),
                          ],
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _type = v!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _balanceController,
                decoration: const InputDecoration(
                  labelText: 'Starting balance (optional)',
                  prefixText: '\$ ',
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true, signed: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d{0,2}')),
                ],
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _save,
                child: const Text('Create Account'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final account = Account(
      id: const Uuid().v4(),
      name: _nameController.text.trim(),
      type: _type,
      initialBalance: double.tryParse(_balanceController.text) ?? 0,
      colorValue: _colorValue,
    );

    await context.read<BudgetProvider>().addAccount(account);
    if (mounted) Navigator.pop(context, account.id);
  }
}

/// Dropdown field for accounts with inline "Add new account" option.
class AccountPickerField extends StatelessWidget {
  const AccountPickerField({
    super.key,
    required this.accountId,
    required this.accounts,
    required this.onChanged,
  });

  final String accountId;
  final List<Account> accounts;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (accounts.isEmpty)
          InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Account',
              helperText: 'No accounts yet — create one below',
            ),
            child: const Text(
              'No account selected',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          )
        else
          DropdownButtonFormField<String>(
            value: accounts.any((a) => a.id == accountId) ? accountId : null,
            decoration: const InputDecoration(labelText: 'Account'),
            items: [
              ...accounts.map(
                (a) => DropdownMenuItem(
                  value: a.id,
                  child: Row(
                    children: [
                      Icon(accountTypeIcon(a.type), size: 18, color: a.color),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(a.name, overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ),
              ),
              const DropdownMenuItem(
                value: _newAccountValue,
                child: Row(
                  children: [
                    Icon(Icons.add_circle_outline,
                        size: 18, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text(
                      'Add new account...',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            onChanged: (v) async {
              if (v == null) return;
              if (v == _newAccountValue) {
                final id = await showCreateAccountSheet(context);
                if (id != null) onChanged(id);
              } else {
                onChanged(v);
              }
            },
          ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () async {
              final id = await showCreateAccountSheet(context);
              if (id != null) onChanged(id);
            },
            icon: const Icon(Icons.add, size: 18),
            label: Text(accounts.isEmpty ? 'Create account' : 'New account'),
          ),
        ),
      ],
    );
  }
}

/// Dropdown field for categories with inline "Add new category" option.
class CategoryPickerField extends StatelessWidget {
  const CategoryPickerField({
    super.key,
    required this.categoryId,
    required this.categories,
    required this.type,
    required this.onChanged,
  });

  final String categoryId;
  final List<BudgetCategory> categories;
  final TransactionType type;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (categories.isEmpty)
          InputDecorator(
            decoration: InputDecoration(
              labelText: 'Category',
              helperText:
                  'No ${type == TransactionType.income ? 'income' : 'expense'} categories yet',
            ),
            child: const Text(
              'No category selected',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          )
        else
          DropdownButtonFormField<String>(
            value: categories.any((c) => c.id == categoryId) ? categoryId : null,
            decoration: const InputDecoration(labelText: 'Category'),
            items: [
              ...categories.map(
                (c) => DropdownMenuItem(
                  value: c.id,
                  child: Row(
                    children: [
                      Icon(categoryIconData(c.icon), size: 18, color: c.color),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(c.name, overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ),
              ),
              const DropdownMenuItem(
                value: _newCategoryValue,
                child: Row(
                  children: [
                    Icon(Icons.add_circle_outline,
                        size: 18, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text(
                      'Add new category...',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            onChanged: (v) async {
              if (v == null) return;
              if (v == _newCategoryValue) {
                final id = await showCreateCategorySheet(context, type);
                if (id != null) onChanged(id);
              } else {
                onChanged(v);
              }
            },
          ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () async {
              final id = await showCreateCategorySheet(context, type);
              if (id != null) onChanged(id);
            },
            icon: const Icon(Icons.add, size: 18),
            label: Text(categories.isEmpty ? 'Create category' : 'New category'),
          ),
        ),
      ],
    );
  }
}
