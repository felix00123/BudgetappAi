import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/account.dart';
import '../providers/budget_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

class ManageAccountsScreen extends StatelessWidget {
  const ManageAccountsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<BudgetProvider>(
      builder: (context, provider, _) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              color: AppColors.primary.withValues(alpha: 0.06),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Track money across accounts',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Assign each transaction to an account. Balance = starting balance + income − expenses.',
                      style: TextStyle(
                        color: AppColors.textSecondary.withValues(alpha: 0.9),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ...provider.accounts.map(
              (account) => _AccountTile(
                account: account,
                balance: provider.accountBalance(account.id),
              ),
            ),
            const SizedBox(height: 80),
          ],
        );
      },
    );
  }
}

class _AccountTile extends StatelessWidget {
  const _AccountTile({required this.account, required this.balance});

  final Account account;
  final double balance;

  @override
  Widget build(BuildContext context) {
    final provider = context.read<BudgetProvider>();

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: account.color.withValues(alpha: 0.15),
          child: Icon(accountTypeIcon(account.type), color: account.color, size: 20),
        ),
        title: Text(account.name),
        subtitle: Text('${accountTypeLabel(account.type)} · ${formatCurrency(balance)}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AccountEditorScreen(existing: account),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.expense),
              onPressed: () async {
                final error = await provider.deleteAccount(account.id);
                if (context.mounted && error != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(error), backgroundColor: AppColors.expense),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class AccountEditorScreen extends StatefulWidget {
  const AccountEditorScreen({
    super.key,
    this.existing,
    this.initialLastFour,
    this.initialDueDate,
    this.initialCutoffDate,
    this.initialBalance,
    this.initialType,
  });

  final Account? existing;
  final String? initialLastFour;
  final DateTime? initialDueDate;
  final DateTime? initialCutoffDate;
  final double? initialBalance;
  final AccountType? initialType;

  @override
  State<AccountEditorScreen> createState() => _AccountEditorScreenState();
}

class _AccountEditorScreenState extends State<AccountEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController();
  final _bankController = TextEditingController();
  final _lastFourController = TextEditingController();
  late AccountType _type;
  late int _colorValue;
  DateTime? _dueDate;
  DateTime? _cutoffDate;

  bool get isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _nameController.text = existing.name;
      _balanceController.text = existing.initialBalance.toString();
      _bankController.text = existing.bank ?? '';
      _lastFourController.text = existing.lastFour ?? '';
      _type = existing.type;
      _colorValue = existing.colorValue;
      _dueDate = existing.dueDate;
      _cutoffDate = existing.cutoffDate;
    } else {
      _lastFourController.text = widget.initialLastFour ?? '';
      if (widget.initialLastFour != null) {
        _nameController.text = 'Card ••${widget.initialLastFour}';
      }
      if (widget.initialBalance != null) {
        _balanceController.text = widget.initialBalance!.toStringAsFixed(2);
      }
      _type = widget.initialType ??
          (widget.initialLastFour == null ? AccountType.bank : AccountType.credit);
      _colorValue = accountColorOptions.first;
      _dueDate = widget.initialDueDate;
      _cutoffDate = widget.initialCutoffDate;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    _bankController.dispose();
    _lastFourController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Account' : 'New Account'),
      ),
      floatingActionButton: isEditing
          ? null
          : FloatingActionButton(
              heroTag: 'account-editor-fab',
              onPressed: _save,
              child: const Icon(Icons.check),
            ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Account Name',
                hintText: 'e.g. Main Checking',
              ),
              textCapitalization: TextCapitalization.sentences,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Enter a name' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<AccountType>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'Account Type'),
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
              controller: _bankController,
              decoration: const InputDecoration(
                labelText: 'Bank (optional)',
                hintText: 'e.g. BHD',
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _lastFourController,
              decoration: const InputDecoration(
                labelText: 'Last 4 digits (optional)',
                hintText: '9675',
                helperText: 'Used to match purchase alerts from email',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
              validator: (value) {
                final digits = value?.trim() ?? '';
                if (digits.isEmpty || digits.length == 4) return null;
                return 'Enter all 4 digits';
              },
            ),
            const SizedBox(height: 16),
            _DateTile(
              title: 'Fecha de corte',
              value: _cutoffDate,
              emptyHint: 'Cutoff date from your card screenshot',
              onPick: () => _pickDate(isCutoff: true),
              onClear: () => setState(() => _cutoffDate = null),
            ),
            const SizedBox(height: 12),
            _DateTile(
              title: 'Fecha de vencimiento',
              value: _dueDate,
              emptyHint: 'Pagar antes de, from your card screenshot',
              onPick: () => _pickDate(isCutoff: false),
              onClear: () => setState(() => _dueDate = null),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _balanceController,
              decoration: const InputDecoration(
                labelText: 'Balance',
                prefixText: '\$ ',
                helperText: 'Crédito disponible from the screenshot',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d{0,2}')),
              ],
            ),
            const SizedBox(height: 20),
            const Text('Color', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: accountColorOptions.map((color) {
                final selected = color == _colorValue;
                return GestureDetector(
                  onTap: () => setState(() => _colorValue = color),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Color(color),
                      shape: BoxShape.circle,
                      border: selected
                          ? Border.all(color: AppColors.textPrimary, width: 3)
                          : null,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(isEditing ? 'Update Account' : 'Create Account'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<BudgetProvider>();
    final lastFour = _lastFourController.text.trim();
    final bank = _bankController.text.trim();
    final account = Account(
      id: widget.existing?.id ?? const Uuid().v4(),
      name: _nameController.text.trim(),
      type: _type,
      initialBalance: double.tryParse(_balanceController.text) ?? 0,
      colorValue: _colorValue,
      bank: bank.isEmpty ? null : bank,
      lastFour: lastFour.isEmpty ? null : lastFour,
      dueDate: _dueDate,
      cutoffDate: _cutoffDate,
    );

    if (isEditing) {
      await provider.updateAccount(account);
    } else {
      await provider.addAccount(account);
    }

    if (mounted) Navigator.pop(context);
  }

  Future<void> _pickDate({required bool isCutoff}) async {
    final current = isCutoff ? _cutoffDate : _dueDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null && mounted) {
      setState(() {
        if (isCutoff) {
          _cutoffDate = picked;
        } else {
          _dueDate = picked;
        }
      });
    }
  }
}

class _DateTile extends StatelessWidget {
  const _DateTile({
    required this.title,
    required this.value,
    required this.emptyHint,
    required this.onPick,
    required this.onClear,
  });

  final String title;
  final DateTime? value;
  final String emptyHint;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: const BorderSide(color: AppColors.border),
      ),
      title: Text(title),
      subtitle: Text(value == null ? emptyHint : formatDate(value!)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (value != null)
            IconButton(
              tooltip: 'Clear date',
              onPressed: onClear,
              icon: const Icon(Icons.close_rounded),
            ),
          IconButton(
            tooltip: 'Pick date',
            onPressed: onPick,
            icon: const Icon(Icons.event_rounded),
          ),
        ],
      ),
    );
  }
}
