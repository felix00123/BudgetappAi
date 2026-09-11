import 'package:flutter_test/flutter_test.dart';

import 'package:budget_app/models/account.dart';
import 'package:budget_app/models/balance_snapshot.dart';
import 'package:budget_app/models/transaction.dart';
import 'package:budget_app/services/finance_insights.dart';

Transaction expense({
  required double amount,
  required String categoryId,
  required DateTime date,
  String title = 'Shop',
}) =>
    Transaction(
      id: '$title-$amount-${date.millisecondsSinceEpoch}',
      title: title,
      amount: amount,
      type: TransactionType.expense,
      categoryId: categoryId,
      accountId: 'acc_cash',
      date: date,
    );

void main() {
  final now = DateTime(2026, 9, 15);

  group('buildAnalytics', () {
    test('separates spending from income', () {
      final analytics = buildAnalytics(
        [
          expense(amount: 100, categoryId: 'cat_food', date: now),
          Transaction(
            id: 'i1',
            title: 'Paycheck',
            amount: 5000,
            type: TransactionType.income,
            categoryId: 'cat_salary',
            accountId: 'acc_bank',
            date: now,
          ),
        ],
        now: now,
      );

      expect(analytics.spending, 100);
      expect(analytics.income, 5000);
      expect(analytics.savings, 4900);
      expect(analytics.transactionCount, 2);
    });

    test('ranks categories from highest to lowest', () {
      final analytics = buildAnalytics(
        [
          expense(amount: 50, categoryId: 'cat_food', date: now),
          expense(amount: 300, categoryId: 'cat_bills', date: now),
          expense(amount: 120, categoryId: 'cat_transport', date: now),
          expense(amount: 80, categoryId: 'cat_food', date: now),
        ],
        now: now,
      );

      // Food wins second place on its combined total, not on a single charge.
      expect(analytics.categoryTotals.keys.toList(), [
        'cat_bills',
        'cat_food',
        'cat_transport',
      ]);
      expect(analytics.categoryTotals['cat_food'], 130);
    });

    test('keeps a full window of months including empty ones', () {
      final analytics = buildAnalytics(
        [expense(amount: 200, categoryId: 'cat_food', date: now)],
        months: 6,
        now: now,
      );

      expect(analytics.monthlyTotals, hasLength(6));
      expect(analytics.monthlyTotals[DateTime(2026, 9)], 200);
      expect(analytics.monthlyTotals[DateTime(2026, 4)], 0);
    });

    test('ignores transactions older than the window', () {
      final analytics = buildAnalytics(
        [
          expense(amount: 999, categoryId: 'cat_food', date: DateTime(2024, 1, 1)),
          expense(amount: 10, categoryId: 'cat_food', date: now),
        ],
        months: 6,
        now: now,
      );

      expect(analytics.spending, 10);
      expect(analytics.transactionCount, 1);
    });

    test('reports the merchant with the highest total, not the highest single charge', () {
      final analytics = buildAnalytics(
        [
          expense(amount: 400, categoryId: 'cat_shopping', date: now, title: 'One Big'),
          expense(amount: 300, categoryId: 'cat_food', date: now, title: 'Cafe'),
          expense(amount: 300, categoryId: 'cat_food', date: now, title: 'Cafe'),
        ],
        now: now,
      );

      expect(analytics.topMerchant, 'Cafe');
    });

    test('is empty with no transactions', () {
      final analytics = buildAnalytics([], now: now);

      expect(analytics.isEmpty, isTrue);
      expect(analytics.topMerchant, isNull);
      expect(analytics.categoryTotals, isEmpty);
    });
  });

  group('model round-trips', () {
    test('BalanceSnapshot survives serialization', () {
      final snapshot = BalanceSnapshot(
        id: 'b1',
        accountId: 'acc_bhd_9675',
        balance: 65397.38,
        currency: 'DOP',
        label: 'Balance disponible',
        capturedAt: DateTime(2026, 9, 2),
        externalId: 'BHD|9675|Balance disponible|65397.38',
      );

      final restored = BalanceSnapshot.fromJson(snapshot.toJson());

      expect(restored.balance, 65397.38);
      expect(restored.currency, 'DOP');
      expect(restored.label, 'Balance disponible');
      expect(restored.externalId, snapshot.externalId);
    });

    test('Account keeps bank and last four', () {
      final account = Account(
        id: 'acc_bhd_9675',
        name: 'BHD Credit ••9675',
        type: AccountType.credit,
        colorValue: 0xFF6366F1,
        bank: 'BHD',
        lastFour: '9675',
      );

      final restored = Account.fromJson(account.toJson());

      expect(restored.bank, 'BHD');
      expect(restored.lastFour, '9675');
    });

    test('Account without bank fields still loads', () {
      final restored = Account.fromJson({
        'id': 'acc_cash',
        'name': 'Cash',
        'type': 'cash',
        'colorValue': 0xFF22C55E,
      });

      expect(restored.bank, isNull);
      expect(restored.lastFour, isNull);
    });

    test('Transaction keeps its import source and external id', () {
      final transaction = Transaction(
        id: 't1',
        title: 'SUPERMERCADO FORTUNA',
        amount: 369,
        type: TransactionType.expense,
        categoryId: 'cat_food',
        accountId: 'acc_bhd_9675',
        date: DateTime(2026, 9, 9),
        source: TransactionSource.email,
        externalId: 'BHD|9675|2026-09-09|369.00',
      );

      final restored = Transaction.fromJson(transaction.toJson());

      expect(restored.source, TransactionSource.email);
      expect(restored.externalId, 'BHD|9675|2026-09-09|369.00');
    });

    test('Transaction from an older build defaults to manual', () {
      final restored = Transaction.fromJson({
        'id': 't1',
        'title': 'Lunch',
        'amount': 12.5,
        'type': 'expense',
        'categoryId': 'cat_food',
        'accountId': 'acc_cash',
        'date': '2026-06-01T00:00:00.000',
      });

      expect(restored.source, TransactionSource.manual);
      expect(restored.externalId, isNull);
    });
  });
}
