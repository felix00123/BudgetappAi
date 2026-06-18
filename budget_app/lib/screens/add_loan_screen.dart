import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/loan.dart';
import '../providers/budget_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

class AddLoanScreen extends StatefulWidget {
  const AddLoanScreen({super.key, this.existing});

  final Loan? existing;

  @override
  State<AddLoanScreen> createState() => _AddLoanScreenState();
}

class _AddLoanScreenState extends State<AddLoanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _principalController = TextEditingController();
  final _rateController = TextEditingController();
  final _termController = TextEditingController();
  final _balanceController = TextEditingController();
  final _extraPaymentController = TextEditingController();
  final _paymentOverrideController = TextEditingController();
  final _noteController = TextEditingController();

  String _selectedIcon = loanIcons.first;
  DateTime _startDate = DateTime.now();
  bool _useCustomPayment = false;
  bool get isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _nameController.text = existing.name;
      _principalController.text = existing.principal.toString();
      _rateController.text = existing.annualInterestRate.toString();
      _termController.text = existing.termMonths.toString();
      _balanceController.text = existing.remainingBalance.toString();
      _extraPaymentController.text = existing.extraMonthlyPayment > 0
          ? existing.extraMonthlyPayment.toString()
          : '';
      _noteController.text = existing.note ?? '';
      _selectedIcon = existing.icon ?? loanIcons.first;
      _startDate = existing.startDate;
      _useCustomPayment = existing.monthlyPaymentOverride != null;
      if (existing.monthlyPaymentOverride != null) {
        _paymentOverrideController.text =
            existing.monthlyPaymentOverride!.toString();
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _principalController.dispose();
    _rateController.dispose();
    _termController.dispose();
    _balanceController.dispose();
    _extraPaymentController.dispose();
    _paymentOverrideController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  double? get _principal => double.tryParse(_principalController.text);
  double? get _rate => double.tryParse(_rateController.text);
  int? get _term => int.tryParse(_termController.text);

  double? get _calculatedPayment {
    final p = _principal;
    final r = _rate;
    final t = _term;
    if (p == null || r == null || t == null || p <= 0 || t <= 0) return null;
    return calculateMonthlyPayment(p, r, t);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Loan' : 'New Loan'),
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
              children: loanIcons.map((icon) {
                final selected = icon == _selectedIcon;
                return GestureDetector(
                  onTap: () => setState(() => _selectedIcon = icon),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.warning.withValues(alpha: 0.15)
                          : AppColors.border.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: selected
                          ? Border.all(color: AppColors.warning, width: 2)
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
                labelText: 'Loan Name',
                hintText: 'e.g. Car loan, Mortgage',
              ),
              textCapitalization: TextCapitalization.sentences,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Enter a loan name' : null,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _principalController,
              decoration: const InputDecoration(
                labelText: 'Original Principal',
                prefixText: '\$ ',
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              validator: (v) {
                if (v == null || v.isEmpty) return 'Enter principal amount';
                final amount = double.tryParse(v);
                if (amount == null || amount <= 0) return 'Enter a valid amount';
                return null;
              },
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _balanceController,
              decoration: const InputDecoration(
                labelText: 'Current Balance',
                prefixText: '\$ ',
                helperText: 'Outstanding balance today',
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              validator: (v) {
                if (v == null || v.isEmpty) return 'Enter current balance';
                final amount = double.tryParse(v);
                if (amount == null || amount < 0) return 'Enter a valid balance';
                return null;
              },
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _rateController,
                    decoration: const InputDecoration(
                      labelText: 'Annual Rate',
                      suffixText: '%',
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d{0,3}'),
                      ),
                    ],
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      final rate = double.tryParse(v);
                      if (rate == null || rate < 0) return 'Invalid rate';
                      return null;
                    },
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _termController,
                    decoration: const InputDecoration(
                      labelText: 'Term (months)',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      final months = int.tryParse(v);
                      if (months == null || months <= 0) return 'Invalid term';
                      return null;
                    },
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Start Date'),
              subtitle: Text(formatDate(_startDate)),
              trailing: const Icon(Icons.calendar_today_outlined),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _startDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) {
                  setState(() => _startDate = picked);
                }
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _extraPaymentController,
              decoration: const InputDecoration(
                labelText: 'Extra Monthly Payment (optional)',
                prefixText: '\$ ',
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Custom monthly payment'),
              subtitle: const Text('Override calculated payment'),
              value: _useCustomPayment,
              onChanged: (v) => setState(() => _useCustomPayment = v),
            ),
            if (_useCustomPayment) ...[
              TextFormField(
                controller: _paymentOverrideController,
                decoration: const InputDecoration(
                  labelText: 'Monthly Payment',
                  prefixText: '\$ ',
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                validator: (v) {
                  if (!_useCustomPayment) return null;
                  if (v == null || v.isEmpty) return 'Enter payment amount';
                  final amount = double.tryParse(v);
                  if (amount == null || amount <= 0) return 'Invalid amount';
                  return null;
                },
                onChanged: (_) => setState(() {}),
              ),
            ],
            const SizedBox(height: 16),
            TextFormField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
              ),
              maxLines: 2,
            ),
            if (_calculatedPayment != null) ...[
              const SizedBox(height: 24),
              _PaymentPreview(
                monthlyPayment: _useCustomPayment
                    ? double.tryParse(_paymentOverrideController.text) ??
                        _calculatedPayment!
                    : _calculatedPayment!,
                extraPayment: double.tryParse(_extraPaymentController.text) ?? 0,
                balance: double.tryParse(_balanceController.text) ?? 0,
                rate: _rate ?? 0,
              ),
            ],
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: AppColors.warning,
              ),
              child: Text(
                isEditing ? 'Update Loan' : 'Add Loan',
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
    final principal = double.parse(_principalController.text);
    final balance = double.tryParse(_balanceController.text) ?? principal;

    final loan = Loan(
      id: widget.existing?.id ?? const Uuid().v4(),
      name: _nameController.text.trim(),
      principal: principal,
      annualInterestRate: double.parse(_rateController.text),
      termMonths: int.parse(_termController.text),
      startDate: _startDate,
      remainingBalance: balance,
      extraMonthlyPayment: double.tryParse(_extraPaymentController.text) ?? 0,
      monthlyPaymentOverride: _useCustomPayment
          ? double.tryParse(_paymentOverrideController.text)
          : null,
      totalInterestPaid: widget.existing?.totalInterestPaid ?? 0,
      paymentsMade: widget.existing?.paymentsMade ?? 0,
      createdAt: widget.existing?.createdAt ?? DateTime.now(),
      icon: _selectedIcon,
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
    );

    if (isEditing) {
      await provider.updateLoan(loan);
    } else {
      await provider.addLoan(loan);
    }

    if (mounted) Navigator.pop(context);
  }
}

class _PaymentPreview extends StatelessWidget {
  const _PaymentPreview({
    required this.monthlyPayment,
    required this.extraPayment,
    required this.balance,
    required this.rate,
  });

  final double monthlyPayment;
  final double extraPayment;
  final double balance;
  final double rate;

  @override
  Widget build(BuildContext context) {
    final total = monthlyPayment + extraPayment;
    final months = estimateMonthsRemaining(
      balance: balance,
      annualRate: rate,
      monthlyPayment: total,
    );
    final payoff = months != null
        ? DateTime.now().add(Duration(days: months * 30))
        : null;

    return Card(
      color: AppColors.warning.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.calculate_outlined,
                    color: AppColors.warning, size: 20),
                SizedBox(width: 8),
                Text(
                  'Payment Preview',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Monthly: ${formatCurrency(monthlyPayment)}'
              '${extraPayment > 0 ? ' + ${formatCurrency(extraPayment)} extra' : ''}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            if (months != null && payoff != null) ...[
              const SizedBox(height: 8),
              Text(
                'Payoff in ${formatDuration(months)} • ${formatDate(payoff)}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ] else if (balance > 0)
              const Text(
                'Payment may not cover interest',
                style: TextStyle(color: AppColors.expense, fontSize: 13),
              ),
          ],
        ),
      ),
    );
  }
}
