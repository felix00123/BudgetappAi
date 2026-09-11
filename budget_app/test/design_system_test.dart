import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:budget_app/theme/app_theme.dart';
import 'package:budget_app/widgets/ambient_background.dart';
import 'package:budget_app/widgets/app_nav_bar.dart';
import 'package:budget_app/widgets/balance_card.dart';
import 'package:budget_app/widgets/stat_card.dart';

const _navItems = [
  AppNavItem(
    icon: Icons.dashboard_outlined,
    selectedIcon: Icons.dashboard_rounded,
    label: 'Home',
  ),
  AppNavItem(
    icon: Icons.receipt_long_outlined,
    selectedIcon: Icons.receipt_long_rounded,
    label: 'Activity',
  ),
  AppNavItem(
    icon: Icons.flag_outlined,
    selectedIcon: Icons.flag_rounded,
    label: 'Goals',
  ),
  AppNavItem(
    icon: Icons.account_balance_outlined,
    selectedIcon: Icons.account_balance_rounded,
    label: 'Loans',
  ),
  AppNavItem(
    icon: Icons.auto_awesome_outlined,
    selectedIcon: Icons.auto_awesome_rounded,
    label: 'Advisor',
  ),
];

Future<void> pump(WidgetTester tester, Widget child) {
  return tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(),
      home: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );
}

void main() {
  setUpAll(() {
    // Tests have no network; fall back to the bundled font instead of fetching.
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  // buildAppTheme resolves a Google font, which needs the widget binding, so
  // these run as widget tests even though they only inspect the theme.
  group('theme', () {
    testWidgets('exposes a coherent light scheme', (tester) async {
      final theme = buildAppTheme();

      expect(theme.colorScheme.brightness, Brightness.light);
      expect(theme.colorScheme.primary, AppColors.primary);
      expect(theme.scaffoldBackgroundColor, AppColors.surface);
    });

    testWidgets('app bars are transparent so the ambient wash shows through', (
      tester,
    ) async {
      final theme = buildAppTheme();

      expect(theme.appBarTheme.backgroundColor, Colors.transparent);
      expect(theme.appBarTheme.elevation, 0);
    });

    testWidgets('cards are flat with a hairline border', (tester) async {
      final cardTheme = buildAppTheme().cardTheme;
      final shape = cardTheme.shape as RoundedRectangleBorder;

      expect(cardTheme.elevation, 0);
      expect(shape.side.color, AppColors.border);
    });
  });

  group('AppNavBar', () {
    testWidgets('renders every destination', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: Scaffold(
            extendBody: true,
            body: const SizedBox.expand(),
            bottomNavigationBar: AppNavBar(
              currentIndex: 0,
              onSelected: (_) {},
              items: _navItems,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      for (final item in _navItems) {
        expect(find.text(item.label), findsOneWidget);
      }
    });

    testWidgets('reports the tapped destination', (tester) async {
      var tapped = -1;

      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: Scaffold(
            extendBody: true,
            body: const SizedBox.expand(),
            bottomNavigationBar: AppNavBar(
              currentIndex: 0,
              onSelected: (index) => tapped = index,
              items: _navItems,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Goals'));

      expect(tapped, 2);
    });

    testWidgets('shows the filled icon only for the selected destination', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: Scaffold(
            extendBody: true,
            body: const SizedBox.expand(),
            bottomNavigationBar: AppNavBar(
              currentIndex: 1,
              onSelected: (_) {},
              items: _navItems,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.receipt_long_rounded), findsOneWidget);
      expect(find.byIcon(Icons.receipt_long_outlined), findsNothing);
      expect(find.byIcon(Icons.dashboard_outlined), findsOneWidget);
    });

    testWidgets('reserves enough room for content to clear it', (tester) async {
      late double inset;
      late double reserved;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              inset = AppNavBar.contentInset(context);
              reserved = AppNavBar.reservedHeight(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(reserved, greaterThanOrEqualTo(AppNavBar.barHeight));
      expect(inset, greaterThan(reserved));
    });
  });

  group('AmbientBackground', () {
    testWidgets('paints behind its child without stealing taps', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: AmbientBackground(
            child: Center(
              child: GestureDetector(
                onTap: () => tapped = true,
                child: const Text('tap me'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('tap me'));

      expect(tapped, isTrue);
    });
  });

  group('cards', () {
    testWidgets('BalanceCard shows the balance, income and expenses', (
      tester,
    ) async {
      await pump(
        tester,
        const BalanceCard(balance: 1500, income: 3000, expenses: 1500),
      );
      await tester.pumpAndSettle();

      expect(find.text('Total Balance'), findsOneWidget);
      expect(find.text('Income'), findsOneWidget);
      expect(find.text('Expenses'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('BalanceCard survives a very large balance', (tester) async {
      await pump(
        tester,
        const BalanceCard(
          balance: 987654321.99,
          income: 987654321.99,
          expenses: 123456789.01,
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('StatCard renders its title', (tester) async {
      await pump(
        tester,
        const SizedBox(
          width: 180,
          child: StatCard(
            title: 'Monthly Income',
            value: 4200,
            icon: Icons.trending_up_rounded,
            color: AppColors.income,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Monthly Income'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
