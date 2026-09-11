import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budget_app/models/balance_snapshot.dart';
import 'package:budget_app/models/category.dart';
import 'package:budget_app/widgets/balance_history_chart.dart';
import 'package:budget_app/widgets/category_breakdown_chart.dart';
import 'package:budget_app/widgets/monthly_spending_chart.dart';

Future<void> pump(WidgetTester tester, Widget child) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );
}

BalanceSnapshot snapshot(double balance, DateTime at) => BalanceSnapshot(
      id: 'b-${at.millisecondsSinceEpoch}',
      accountId: 'acc_bhd_9675',
      balance: balance,
      currency: 'DOP',
      label: 'Balance disponible',
      capturedAt: at,
    );

void main() {
  final categories = defaultCategories();

  group('CategoryBreakdownChart', () {
    testWidgets('renders a row per category with its name', (tester) async {
      await pump(
        tester,
        CategoryBreakdownChart(
          totals: const {'cat_food': 300, 'cat_transport': 120},
          categories: categories,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Food'), findsOneWidget);
      expect(find.text('Transport'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsNWidgets(2));
    });

    testWidgets('caps the number of rows shown', (tester) async {
      await pump(
        tester,
        CategoryBreakdownChart(
          totals: const {
            'cat_food': 700,
            'cat_transport': 600,
            'cat_bills': 500,
            'cat_health': 400,
            'cat_shopping': 300,
            'cat_housing': 200,
            'cat_education': 100,
          },
          categories: categories,
          maxEntries: 3,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LinearProgressIndicator), findsNWidgets(3));
    });

    testWidgets('shows an empty state with no spending', (tester) async {
      await pump(
        tester,
        CategoryBreakdownChart(totals: const {}, categories: categories),
      );

      expect(find.text('No categorized spending yet'), findsOneWidget);
    });
  });

  group('MonthlySpendingChart', () {
    testWidgets('labels every month in the window', (tester) async {
      await pump(
        tester,
        MonthlySpendingChart(
          values: {
            DateTime(2026, 4): 100,
            DateTime(2026, 5): 0,
            DateTime(2026, 6): 250,
          },
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Apr'), findsOneWidget);
      expect(find.text('May'), findsOneWidget);
      expect(find.text('Jun'), findsOneWidget);
    });

    testWidgets('renders with all months at zero', (tester) async {
      await pump(
        tester,
        MonthlySpendingChart(
          values: {DateTime(2026, 4): 0, DateTime(2026, 5): 0},
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  group('BalanceHistoryChart', () {
    testWidgets('draws nothing without snapshots', (tester) async {
      await pump(tester, const BalanceHistoryChart(snapshots: []));

      expect(find.byType(SizedBox), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('explains that one reading is not a trend yet', (tester) async {
      await pump(
        tester,
        BalanceHistoryChart(snapshots: [snapshot(1000, DateTime(2026, 9, 1))]),
      );

      expect(find.textContaining('Import another email'), findsOneWidget);
    });

    testWidgets('renders a line once there are several readings', (tester) async {
      await pump(
        tester,
        BalanceHistoryChart(
          snapshots: [
            snapshot(65397.38, DateTime(2026, 9, 1)),
            snapshot(61000.00, DateTime(2026, 9, 8)),
            snapshot(58250.10, DateTime(2026, 9, 15)),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.textContaining('Import another email'), findsNothing);
    });

    testWidgets('handles a flat history without dividing by zero', (tester) async {
      await pump(
        tester,
        BalanceHistoryChart(
          snapshots: [
            snapshot(500, DateTime(2026, 9, 1)),
            snapshot(500, DateTime(2026, 9, 2)),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
