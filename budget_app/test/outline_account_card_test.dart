import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budget_app/models/account.dart';
import 'package:budget_app/widgets/outline_account_card.dart';

void main() {
  testWidgets('OutlineAccountCard shows screenshot fields', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OutlineAccountCard(
            account: Account(
              id: '1',
              name: 'Card ••4281',
              type: AccountType.credit,
              colorValue: 0xFF6366F1,
              lastFour: '4281',
              initialBalance: 19681.25,
              cutoffDate: DateTime(2026, 9, 2),
              dueDate: DateTime(2026, 9, 17),
            ),
            balance: 19681.25,
          ),
        ),
      ),
    );

    expect(find.text('Card ••4281'), findsOneWidget);
    expect(find.textContaining('4281'), findsWidgets);
    expect(find.textContaining('19,681.25'), findsOneWidget);
  });
}
