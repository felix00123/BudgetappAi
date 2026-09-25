import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/loan.dart';
import '../providers/budget_provider.dart';
import '../providers/locale_controller.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/app_nav_bar.dart';
import '../widgets/empty_state.dart';
import '../widgets/loan_card.dart';
import 'add_loan_screen.dart';
import 'loan_amortization_screen.dart';
import 'progress_widget_setup_screen.dart';

class LoansScreen extends StatelessWidget {
  const LoansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(l10n.loans),
        actions: [
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ProgressWidgetSetupScreen(),
              ),
            ),
            icon: const Icon(Icons.widgets_outlined),
            tooltip: l10n.homeScreenWidget,
          ),
        ],
      ),
      body: Consumer<BudgetProvider>(
        builder: (context, provider, _) {
          if (provider.loans.isEmpty) {
            return EmptyState(
              icon: Icons.account_balance_outlined,
              title: l10n.noLoansYet,
              subtitle: l10n.noLoansYetBody,
              action: FilledButton.icon(
                onPressed: () => _openAddLoan(context),
                icon: const Icon(Icons.add),
                label: Text(l10n.addLoan),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.warning,
                ),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _DebtOverview(provider: provider),
              const SizedBox(height: 20),
              ...provider.activeLoans.map(
                (loan) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: LoanCard(
                    loan: loan,
                    onTap: () => _showLoanDetails(context, loan, provider),
                  ),
                ),
              ),
              if (provider.paidOffLoans.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  context.l10n.paidOff,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                ...provider.paidOffLoans.map(
                  (loan) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: LoanCard(
                      loan: loan,
                      onTap: () => _showLoanDetails(context, loan, provider),
                    ),
                  ),
                ),
              ],
              SizedBox(height: AppNavBar.contentInset(context)),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'loans-fab',
        onPressed: () => _openAddLoan(context),
        backgroundColor: AppColors.warning,
        icon: const Icon(Icons.add),
        label: Text(context.l10n.newLoan),
      ),
    );
  }

  void _openAddLoan(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddLoanScreen()),
    );
  }

  void _showLoanDetails(
    BuildContext context,
    Loan loan,
    BudgetProvider provider,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.of(ctx).padding.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(loan.icon ?? '🏦', style: const TextStyle(fontSize: 36)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    loan.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _DetailRow('Principal', formatCurrency(loan.principal)),
            _DetailRow('Balance', formatCurrency(loan.remainingBalance)),
            _DetailRow('Paid off', formatCurrency(loan.amountPaidOff)),
            _DetailRow('Progress', '${(loan.progress * 100).toStringAsFixed(0)}%'),
            _DetailRow('Rate', '${loan.annualInterestRate.toStringAsFixed(2)}% APR'),
            _DetailRow('Term', '${loan.termMonths} months'),
            _DetailRow('Monthly payment', formatCurrency(loan.monthlyPayment)),
            if (loan.extraMonthlyPayment > 0)
              _DetailRow(
                'Extra payment',
                formatCurrency(loan.extraMonthlyPayment),
              ),
            _DetailRow(
              'Total monthly',
              formatCurrency(loan.totalMonthlyPayment),
            ),
            _DetailRow('Interest paid', formatCurrency(loan.totalInterestPaid)),
            if (loan.monthsRemaining != null && !loan.isPaidOff) ...[
              _DetailRow('Remaining', formatDuration(loan.monthsRemaining!)),
              if (loan.estimatedPayoffDate != null)
                _DetailRow(
                  'Payoff date',
                  formatDate(loan.estimatedPayoffDate!),
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
                          builder: (_) => LoanAmortizationScreen(loan: loan),
                        ),
                      );
                    },
                    icon: const Icon(Icons.table_chart_outlined),
                    label: const Text('Schedule'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddLoanScreen(existing: loan),
                        ),
                      );
                    },
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit'),
                  ),
                ),
              ],
            ),
            if (!loan.isPaidOff) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _showRecordPaymentDialog(context, loan, provider);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.warning,
                  ),
                  icon: const Icon(Icons.payments_outlined),
                  label: const Text('Record Payment'),
                ),
              ),
            ],
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await provider.deleteLoan(loan.id);
                },
                style: TextButton.styleFrom(foregroundColor: AppColors.expense),
                child: const Text('Delete Loan'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRecordPaymentDialog(
    BuildContext context,
    Loan loan,
    BudgetProvider provider,
  ) {
    final controller = TextEditingController(
      text: loan.totalMonthlyPayment.toStringAsFixed(2),
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Payment for ${loan.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Balance: ${formatCurrency(loan.remainingBalance)}',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              decoration: const InputDecoration(
                labelText: 'Payment amount',
                prefixText: '\$ ',
              ),
              autofocus: true,
            ),
          ],
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
                await provider.recordLoanPayment(loan.id, amount);
                if (context.mounted) Navigator.pop(ctx);
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.warning,
            ),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }
}

class _DebtOverview extends StatelessWidget {
  const _DebtOverview({required this.provider});

  final BudgetProvider provider;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.warning,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total Debt Service',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              formatCurrency(provider.totalMonthlyDebtService),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Outstanding',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        formatCurrency(provider.totalRemainingDebt),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Active loans',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '${provider.activeLoans.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
