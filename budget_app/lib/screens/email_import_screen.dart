import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/account.dart';
import '../models/balance_snapshot.dart';
import '../models/transaction.dart';
import '../providers/budget_provider.dart';
import '../services/bank_email_parser.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

/// Turns a pasted bank alert email into transactions and a balance snapshot.
class EmailImportScreen extends StatefulWidget {
  const EmailImportScreen({super.key});

  @override
  State<EmailImportScreen> createState() => _EmailImportScreenState();
}

class _EmailImportScreenState extends State<EmailImportScreen> {
  final _bodyController = TextEditingController();
  final _senderController = TextEditingController();
  final _uuid = const Uuid();

  BankEmailResult? _result;
  String? _selectedAccountId;
  bool _isSaving = false;

  @override
  void dispose() {
    _bodyController.dispose();
    _senderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BudgetProvider>();
    final result = _result;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.mark_email_read_outlined, color: AppColors.primary),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Import from a bank email',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Open a card alert (notification of a purchase, withdrawal, or '
                  'stated balance), copy the whole email and paste it below. '
                  'Transactions and the balance the bank states are read separately.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _senderController,
                  decoration: const InputDecoration(
                    labelText: 'Sender address (optional)',
                    hintText: 'alertas@bhd.com.do',
                    prefixIcon: Icon(Icons.alternate_email_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _bodyController,
                  minLines: 6,
                  maxLines: 14,
                  decoration: const InputDecoration(
                    labelText: 'Email text',
                    hintText: 'Paste the email content here',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _isSaving ? null : _parse,
                        icon: const Icon(Icons.search_rounded),
                        label: const Text('Read email'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    if (result != null) ...[
                      const SizedBox(width: 12),
                      OutlinedButton(
                        onPressed: _isSaving ? null : _clear,
                        child: const Text('Clear'),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
        if (result != null) ...[
          const SizedBox(height: 20),
          _ResultSection(
            result: result,
            provider: provider,
            selectedAccountId: _selectedAccountId,
            isSaving: _isSaving,
            onAccountSelected: (id) => setState(() => _selectedAccountId = id),
            onCreateAccount: _createAccount,
            onSave: _save,
          ),
        ],
        const SizedBox(height: 40),
      ],
    );
  }

  void _parse() {
    final parsed = parseBankEmail(
      from: _senderController.text.trim(),
      body: _bodyController.text,
    );

    final matched = parsed.lastFour == null
        ? null
        : context.read<BudgetProvider>().accountByLastFour(parsed.lastFour!);

    setState(() {
      _result = parsed;
      _selectedAccountId = matched?.id;
    });
  }

  void _clear() {
    setState(() {
      _result = null;
      _selectedAccountId = null;
      _bodyController.clear();
    });
  }

  Future<void> _createAccount() async {
    final result = _result;
    if (result == null || result.lastFour == null) return;

    final lastFour = result.lastFour!;
    final isCredit = result.accountKind == BankAccountKind.credit;
    final account = Account(
      id: 'acc_${result.bank.toLowerCase()}_$lastFour',
      name: '${result.bank} ${isCredit ? 'Credit' : 'Debit'} ••$lastFour',
      type: accountTypeFor(result.accountKind),
      colorValue:
          accountColorOptions[lastFour.hashCode.abs() % accountColorOptions.length],
      bank: result.bank,
      lastFour: lastFour,
    );

    await context.read<BudgetProvider>().addAccount(account);
    if (!mounted) return;
    setState(() => _selectedAccountId = account.id);
  }

  Future<void> _save() async {
    final result = _result;
    final accountId = _selectedAccountId;
    if (result == null || accountId == null) return;

    setState(() => _isSaving = true);
    final provider = context.read<BudgetProvider>();

    try {
      final fresh = result.transactions
          .where((t) => !provider.hasExternalId(t.fingerprint))
          .toList();

      final transactions = fresh
          .map(
            (t) => Transaction(
              id: _uuid.v4(),
              title: t.merchant,
              amount: t.amount,
              type: t.transactionType,
              categoryId: t.categoryId,
              accountId: accountId,
              date: t.date,
              note: '${t.bank} ••${t.lastFour} · ${bankTransactionKindLabel(t.kind)}',
              source: TransactionSource.email,
              externalId: t.fingerprint,
            ),
          )
          .toList();

      if (transactions.isNotEmpty) {
        await provider.importTransactions(transactions);
      }

      var savedBalance = false;
      final balance = result.balance;
      if (balance != null) {
        final externalId =
            '${result.bank}|${result.lastFour}|${balance.label}|${balance.amount}';
        if (!provider.hasExternalId(externalId)) {
          await provider.addBalanceSnapshot(
            BalanceSnapshot(
              id: _uuid.v4(),
              accountId: accountId,
              balance: balance.amount,
              currency: balance.currency,
              label: balance.label,
              capturedAt: balance.capturedAt,
              externalId: externalId,
            ),
          );
          savedBalance = true;
        }
      }

      if (!mounted) return;
      _clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_savedMessage(transactions.length, savedBalance)),
          backgroundColor: AppColors.income,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Import failed: $e'), backgroundColor: AppColors.expense),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _savedMessage(int count, bool savedBalance) {
    if (count == 0 && !savedBalance) return 'Nothing new to save.';
    final parts = <String>[];
    if (count > 0) parts.add('$count transaction${count == 1 ? '' : 's'}');
    if (savedBalance) parts.add('1 balance');
    return 'Saved ${parts.join(' and ')}.';
  }
}

class _ResultSection extends StatelessWidget {
  const _ResultSection({
    required this.result,
    required this.provider,
    required this.selectedAccountId,
    required this.isSaving,
    required this.onAccountSelected,
    required this.onCreateAccount,
    required this.onSave,
  });

  final BankEmailResult result;
  final BudgetProvider provider;
  final String? selectedAccountId;
  final bool isSaving;
  final ValueChanged<String?> onAccountSelected;
  final Future<void> Function() onCreateAccount;
  final Future<void> Function() onSave;

  @override
  Widget build(BuildContext context) {
    final duplicates = result.transactions
        .where((t) => provider.hasExternalId(t.fingerprint))
        .length;
    final newCount = result.transactions.length - duplicates;
    final canSave = selectedAccountId != null &&
        (newCount > 0 || result.balance != null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (result.bank.isNotEmpty)
              _Chip(label: result.bank, color: AppColors.primary),
            if (result.lastFour != null)
              _Chip(label: '••${result.lastFour}', color: AppColors.textSecondary),
            _Chip(
              label: result.accountKind == BankAccountKind.credit ? 'Credit' : 'Debit',
              color: AppColors.secondary,
            ),
            if (newCount > 0)
              _Chip(
                label: '$newCount new',
                color: AppColors.income,
              ),
            if (duplicates > 0)
              _Chip(label: '$duplicates already saved', color: AppColors.warning),
          ],
        ),
        if (result.issue != null) ...[
          const SizedBox(height: 16),
          Card(
            color: AppColors.warning.withValues(alpha: 0.08),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: AppColors.warning),
                  const SizedBox(width: 12),
                  Expanded(child: Text(result.issue!)),
                ],
              ),
            ),
          ),
        ],
        if (result.lastFour != null) ...[
          const SizedBox(height: 16),
          _AccountPicker(
            result: result,
            accounts: provider.accounts,
            selectedAccountId: selectedAccountId,
            onAccountSelected: onAccountSelected,
            onCreateAccount: onCreateAccount,
          ),
        ],
        if (result.balance != null) ...[
          const SizedBox(height: 16),
          _BalanceCard(balance: result.balance!),
        ],
        if (result.transactions.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text(
            'Transactions found',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          ...result.transactions.map(
            (t) => _TransactionTile(
              transaction: t,
              isDuplicate: provider.hasExternalId(t.fingerprint),
            ),
          ),
        ],
        if (canSave) ...[
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: isSaving ? null : onSave,
            icon: isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: Text(isSaving ? 'Saving...' : 'Save to account'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ],
      ],
    );
  }
}

class _AccountPicker extends StatelessWidget {
  const _AccountPicker({
    required this.result,
    required this.accounts,
    required this.selectedAccountId,
    required this.onAccountSelected,
    required this.onCreateAccount,
  });

  final BankEmailResult result;
  final List<Account> accounts;
  final String? selectedAccountId;
  final ValueChanged<String?> onAccountSelected;
  final Future<void> Function() onCreateAccount;

  @override
  Widget build(BuildContext context) {
    final matched = selectedAccountId == null
        ? null
        : accounts.where((a) => a.id == selectedAccountId).firstOrNull;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Account', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              matched == null
                  ? 'No account is linked to ••${result.lastFour} yet.'
                  : 'Saving into ${matched.name}.',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: selectedAccountId,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Link to account'),
              items: accounts
                  .map(
                    (a) => DropdownMenuItem(
                      value: a.id,
                      child: Text(
                        a.lastFour == null ? a.name : '${a.name} (••${a.lastFour})',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: onAccountSelected,
            ),
            if (matched == null) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: onCreateAccount,
                icon: const Icon(Icons.add_card_outlined),
                label: Text(
                  'Create ${result.bank} '
                  '${result.accountKind == BankAccountKind.credit ? 'Credit' : 'Debit'} '
                  '••${result.lastFour}',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.balance});

  final BankBalance balance;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.primary.withValues(alpha: 0.06),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.account_balance_wallet_outlined, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    formatAmountWithCurrency(balance.amount, balance.currency),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${balance.label} · kept as history only',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.transaction, required this.isDuplicate});

  final BankTransaction transaction;
  final bool isDuplicate;

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.transactionType == TransactionType.income;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              (isIncome ? AppColors.income : AppColors.expense).withValues(alpha: 0.12),
          child: Icon(
            isIncome ? Icons.south_west_rounded : Icons.north_east_rounded,
            size: 18,
            color: isIncome ? AppColors.income : AppColors.expense,
          ),
        ),
        title: Text(transaction.merchant, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          '${bankTransactionKindLabel(transaction.kind)} · '
          '${formatDate(transaction.date)}',
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              formatAmountWithCurrency(transaction.amount, transaction.currency),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isIncome ? AppColors.income : AppColors.textPrimary,
              ),
            ),
            if (isDuplicate)
              const Text(
                'already saved',
                style: TextStyle(fontSize: 11, color: AppColors.warning),
              ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }
}
