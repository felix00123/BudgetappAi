import '../models/account.dart';
import '../models/category.dart';
import '../models/loan.dart';
import '../models/savings_goal.dart';
import '../models/transaction.dart';
import '../utils/formatters.dart';

/// Structured snapshot of the user's finances for the AI advisor.
class FinancialContext {
  FinancialContext({
    required this.monthlyIncome,
    required this.monthlyExpenses,
    required this.monthlySavings,
    required this.totalBalance,
    required this.goals,
    required this.loans,
    required this.recentIncome,
    required this.recentExpenses,
    required this.monthlyExpensesByCategory,
    required this.last30DaysExpenseTotal,
    required this.last30DaysIncomeTotal,
    required this.accounts,
    required this.totalTransactions,
  });

  final double monthlyIncome;
  final double monthlyExpenses;
  final double monthlySavings;
  final double totalBalance;
  final List<GoalContext> goals;
  final List<LoanContext> loans;
  final List<TransactionSummary> recentIncome;
  final List<TransactionSummary> recentExpenses;
  final Map<String, double> monthlyExpensesByCategory;
  final double last30DaysExpenseTotal;
  final double last30DaysIncomeTotal;
  final List<AccountContext> accounts;
  final int totalTransactions;

  double get savingsRate =>
      monthlyIncome > 0 ? monthlySavings / monthlyIncome * 100 : 0;

  String toPromptText() {
    final buffer = StringBuffer();

    buffer.writeln('=== MONTHLY SUMMARY ===');
    buffer.writeln('Income: ${formatCurrency(monthlyIncome)}');
    buffer.writeln('Expenses: ${formatCurrency(monthlyExpenses)}');
    buffer.writeln(
      'Savings: ${formatCurrency(monthlySavings)} (${savingsRate.toStringAsFixed(1)}% of income)',
    );
    buffer.writeln('Net balance (all time): ${formatCurrency(totalBalance)}');
    buffer.writeln('Total transactions logged: $totalTransactions');
    buffer.writeln();

    if (accounts.isNotEmpty) {
      buffer.writeln('=== ACCOUNTS ===');
      for (final a in accounts) {
        buffer.writeln('${a.name} (${a.type}): ${formatCurrency(a.balance)}');
      }
      buffer.writeln();
    }

    if (goals.isNotEmpty) {
      buffer.writeln('=== SAVINGS GOALS & PROGRESS ===');
      for (final g in goals) {
        buffer.writeln(
          '${g.icon ?? '🎯'} ${g.name}: ${formatCurrency(g.saved)} / ${formatCurrency(g.target)} '
          '(${g.progressPercent}% complete, ${formatCurrency(g.remaining)} remaining)',
        );
        if (g.monthsToGoal != null && g.monthsToGoal! > 0) {
          buffer.writeln('   Estimated time at current savings: ${formatDuration(g.monthsToGoal!)}');
        } else if (g.remaining <= 0) {
          buffer.writeln('   Status: GOAL REACHED');
        }
        if (g.note != null && g.note!.isNotEmpty) {
          buffer.writeln('   Note: ${g.note}');
        }
      }
      buffer.writeln();
    } else {
      buffer.writeln('=== SAVINGS GOALS ===');
      buffer.writeln('No savings goals configured yet.');
      buffer.writeln();
    }

    if (loans.isNotEmpty) {
      buffer.writeln('=== LOANS & AMORTIZATION ===');
      for (final l in loans) {
        buffer.writeln(
          '${l.icon ?? '🏦'} ${l.name}: ${formatCurrency(l.remaining)} remaining of '
          '${formatCurrency(l.principal)} (${l.progressPercent}% paid) • '
          '${formatCurrency(l.monthlyPayment)}/month at ${l.rate.toStringAsFixed(2)}% APR',
        );
        if (l.monthsRemaining != null && l.monthsRemaining! > 0) {
          buffer.writeln('   Payoff in ${formatDuration(l.monthsRemaining!)}');
        } else if (l.remaining <= 0.01) {
          buffer.writeln('   Status: PAID OFF');
        }
      }
      buffer.writeln();
    } else {
      buffer.writeln('=== LOANS ===');
      buffer.writeln('No loans tracked yet.');
      buffer.writeln();
    }

    buffer.writeln('=== RECENT INCOME (last 30 days: ${formatCurrency(last30DaysIncomeTotal)}) ===');
    if (recentIncome.isEmpty) {
      buffer.writeln('No income recorded in the last 30 days.');
    } else {
      for (final t in recentIncome.take(15)) {
        buffer.writeln(t.line);
      }
      if (recentIncome.length > 15) {
        buffer.writeln('... and ${recentIncome.length - 15} more');
      }
    }
    buffer.writeln();

    buffer.writeln('=== RECENT EXPENSES (last 30 days: ${formatCurrency(last30DaysExpenseTotal)}) ===');
    if (recentExpenses.isEmpty) {
      buffer.writeln('No expenses recorded in the last 30 days.');
    } else {
      for (final t in recentExpenses.take(15)) {
        buffer.writeln(t.line);
      }
      if (recentExpenses.length > 15) {
        buffer.writeln('... and ${recentExpenses.length - 15} more');
      }
    }
    buffer.writeln();

    if (monthlyExpensesByCategory.isNotEmpty) {
      buffer.writeln('=== TOP SPENDING CATEGORIES (this month) ===');
      final sorted = monthlyExpensesByCategory.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      for (final e in sorted.take(8)) {
        final pct = monthlyExpenses > 0
            ? (e.value / monthlyExpenses * 100).toStringAsFixed(0)
            : '0';
        buffer.writeln('${e.key}: ${formatCurrency(e.value)} ($pct%)');
      }
    }

    return buffer.toString();
  }

  /// Shorter summary for local advisor welcome / overview responses.
  String toUserSummary({bool inSpanish = false}) {
    if (inSpanish) {
      return _spanishSummary();
    }
    return _englishSummary();
  }

  String _englishSummary() {
    final buffer = StringBuffer();
    buffer.writeln('📊 Monthly: ${formatCurrency(monthlyIncome)} in | '
        '${formatCurrency(monthlyExpenses)} out | '
        '${formatCurrency(monthlySavings)} saved');
    if (goals.isNotEmpty) {
      buffer.writeln('\n🎯 Your goals:');
      for (final g in goals.take(3)) {
        buffer.writeln('• ${g.icon ?? '🎯'} ${g.name}: ${g.progressPercent}% '
            '(${formatCurrency(g.saved)}/${formatCurrency(g.target)})');
      }
    }
    if (loans.isNotEmpty) {
      buffer.writeln('\n🏦 Your loans:');
      for (final l in loans.take(3)) {
        buffer.writeln('• ${l.icon ?? '🏦'} ${l.name}: ${formatCurrency(l.remaining)} left '
            '(${l.progressPercent}% paid)');
      }
    }
    if (recentExpenses.isNotEmpty) {
      buffer.writeln('\n💸 Recent spending:');
      for (final t in recentExpenses.take(5)) {
        buffer.writeln('• ${t.shortLine}');
      }
    }
    if (recentIncome.isNotEmpty) {
      buffer.writeln('\n💵 Recent income:');
      for (final t in recentIncome.take(5)) {
        buffer.writeln('• ${t.shortLine}');
      }
    }
    return buffer.toString();
  }

  String _spanishSummary() {
    final buffer = StringBuffer();
    buffer.writeln('📊 Este mes: ${formatCurrency(monthlyIncome)} ingresos | '
        '${formatCurrency(monthlyExpenses)} gastos | '
        '${formatCurrency(monthlySavings)} ahorro');
    if (goals.isNotEmpty) {
      buffer.writeln('\n🎯 Tus metas:');
      for (final g in goals.take(3)) {
        buffer.writeln('• ${g.icon ?? '🎯'} ${g.name}: ${g.progressPercent}% '
            '(${formatCurrency(g.saved)} de ${formatCurrency(g.target)})');
      }
    }
    if (loans.isNotEmpty) {
      buffer.writeln('\n🏦 Tus préstamos:');
      for (final l in loans.take(3)) {
        buffer.writeln('• ${l.icon ?? '🏦'} ${l.name}: ${formatCurrency(l.remaining)} pendiente '
            '(${l.progressPercent}% pagado)');
      }
    }
    if (recentExpenses.isNotEmpty) {
      buffer.writeln('\n💸 Gastos recientes:');
      for (final t in recentExpenses.take(5)) {
        buffer.writeln('• ${t.shortLineSpanish}');
      }
    }
    if (recentIncome.isNotEmpty) {
      buffer.writeln('\n💵 Ingresos recientes:');
      for (final t in recentIncome.take(5)) {
        buffer.writeln('• ${t.shortLineSpanish}');
      }
    }
    return buffer.toString();
  }
}

class GoalContext {
  GoalContext({
    required this.name,
    required this.saved,
    required this.target,
    required this.remaining,
    required this.progressPercent,
    this.icon,
    this.note,
    this.monthsToGoal,
  });

  final String name;
  final double saved;
  final double target;
  final double remaining;
  final int progressPercent;
  final String? icon;
  final String? note;
  final int? monthsToGoal;
}

class LoanContext {
  LoanContext({
    required this.name,
    required this.principal,
    required this.remaining,
    required this.monthlyPayment,
    required this.rate,
    required this.progressPercent,
    this.icon,
    this.monthsRemaining,
  });

  final String name;
  final double principal;
  final double remaining;
  final double monthlyPayment;
  final double rate;
  final int progressPercent;
  final String? icon;
  final int? monthsRemaining;
}

class TransactionSummary {
  TransactionSummary({
    required this.date,
    required this.title,
    required this.category,
    required this.amount,
    required this.account,
  });

  final DateTime date;
  final String title;
  final String category;
  final double amount;
  final String account;

  String get line =>
      '${formatShortDate(date)} | $category | $title | ${formatCurrency(amount)} ($account)';

  String get shortLine =>
      '${formatShortDate(date)} — $title (${formatCurrency(amount)}, $category)';

  String get shortLineSpanish =>
      '${formatShortDate(date)} — $title (${formatCurrency(amount)}, $category)';
}

class AccountContext {
  AccountContext({
    required this.name,
    required this.type,
    required this.balance,
  });

  final String name;
  final String type;
  final double balance;
}

class FinancialContextBuilder {
  FinancialContext build({
    required List<Transaction> transactions,
    required List<SavingsGoal> goals,
    required List<Loan> loans,
    required List<BudgetCategory> categories,
    required List<Account> accounts,
    required double monthlyIncome,
    required double monthlyExpenses,
    required double monthlySavings,
    required double Function(String accountId) accountBalance,
  }) {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final last30 = now.subtract(const Duration(days: 30));

    String catName(String id) {
      for (final c in categories) {
        if (c.id == id) return c.name;
      }
      return 'Unknown';
    }

    String accName(String id) {
      for (final a in accounts) {
        if (a.id == id) return a.name;
      }
      return 'Unknown';
    }

    final recentIncome = transactions
        .where((t) =>
            t.type == TransactionType.income && !t.date.isBefore(last30))
        .map(
          (t) => TransactionSummary(
            date: t.date,
            title: t.title,
            category: catName(t.categoryId),
            amount: t.amount,
            account: accName(t.accountId),
          ),
        )
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    final recentExpenses = transactions
        .where((t) =>
            t.type == TransactionType.expense && !t.date.isBefore(last30))
        .map(
          (t) => TransactionSummary(
            date: t.date,
            title: t.title,
            category: catName(t.categoryId),
            amount: t.amount,
            account: accName(t.accountId),
          ),
        )
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    final monthlyExpensesByCategory = <String, double>{};
    for (final t in transactions.where(
      (t) =>
          t.type == TransactionType.expense &&
          !t.date.isBefore(monthStart) &&
          t.date.isBefore(now.add(const Duration(days: 1))),
    )) {
      final name = catName(t.categoryId);
      monthlyExpensesByCategory[name] =
          (monthlyExpensesByCategory[name] ?? 0) + t.amount;
    }

    final goalContexts = goals
        .map(
          (g) => GoalContext(
            name: g.name,
            saved: g.currentSaved,
            target: g.targetAmount,
            remaining: g.remaining,
            progressPercent: (g.progress * 100).round(),
            icon: g.icon,
            note: g.note,
            monthsToGoal: g.monthsToReach(monthlySavings),
          ),
        )
        .toList();

    final loanContexts = loans
        .map(
          (l) => LoanContext(
            name: l.name,
            principal: l.principal,
            remaining: l.remainingBalance,
            monthlyPayment: l.totalMonthlyPayment,
            rate: l.annualInterestRate,
            progressPercent: (l.progress * 100).round(),
            icon: l.icon,
            monthsRemaining: l.monthsRemaining,
          ),
        )
        .toList();

    final accountContexts = accounts
        .map(
          (a) => AccountContext(
            name: a.name,
            type: accountTypeLabel(a.type),
            balance: accountBalance(a.id),
          ),
        )
        .toList();

    final totalIncome = transactions
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (s, t) => s + t.amount);
    final totalExpenses = transactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (s, t) => s + t.amount);

    return FinancialContext(
      monthlyIncome: monthlyIncome,
      monthlyExpenses: monthlyExpenses,
      monthlySavings: monthlySavings,
      totalBalance: totalIncome - totalExpenses,
      goals: goalContexts,
      loans: loanContexts,
      recentIncome: recentIncome,
      recentExpenses: recentExpenses,
      monthlyExpensesByCategory: monthlyExpensesByCategory,
      last30DaysExpenseTotal:
          recentExpenses.fold(0.0, (s, t) => s + t.amount),
      last30DaysIncomeTotal:
          recentIncome.fold(0.0, (s, t) => s + t.amount),
      accounts: accountContexts,
      totalTransactions: transactions.length,
    );
  }
}
