import 'package:budget_app/models/category.dart';
import 'package:budget_app/models/month_summary.dart';
import 'package:budget_app/models/transaction.dart';
import 'package:budget_app/services/month_summary_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('closed months with transactions are listed once', () {
    final transactions = [
      _tx(DateTime(2026, 7, 2), 100, TransactionType.expense),
      _tx(DateTime(2026, 8, 3), 50, TransactionType.income),
      _tx(DateTime(2026, 9, 24), 20, TransactionType.expense),
    ];

    final missing = MonthSummaryService.missingMonthIds(
      transactions: transactions,
      existingIds: {'2026-07'},
      now: DateTime(2026, 9, 24),
    );

    expect(missing, ['2026-08']);
  });

  test('facts use category names and savings', () {
    final summary = MonthSummaryService.factsFor(
      monthId: '2026-08',
      transactions: [
        _tx(DateTime(2026, 8, 1), 1000, TransactionType.income, 'cat_salary'),
        _tx(DateTime(2026, 8, 2), 200, TransactionType.expense, 'cat_food'),
        _tx(DateTime(2026, 8, 3), 50, TransactionType.expense, 'cat_food'),
      ],
      categories: [
        BudgetCategory(
          id: 'cat_food',
          name: 'Food',
          type: TransactionType.expense,
          icon: 'restaurant',
          colorValue: 1,
        ),
      ],
    );

    expect(summary.income, 1000);
    expect(summary.expenses, 250);
    expect(summary.savings, 750);
    expect(summary.topCategories.single.name, 'Food');
    expect(summary.toHistoryLine(), contains('2026-08'));
    expect(summary.toHistoryLine(), contains('Food'));
  });
}

Transaction _tx(
  DateTime date,
  double amount,
  TransactionType type, [
  String categoryId = 'cat_expense_other',
]) {
  return Transaction(
    id: '${date.millisecondsSinceEpoch}-$amount',
    title: 'Item',
    amount: amount,
    type: type,
    categoryId: categoryId,
    accountId: 'acc_cash',
    date: date,
  );
}
