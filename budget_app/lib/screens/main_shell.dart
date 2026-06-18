import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_navigation.dart';
import 'ai_advisor_screen.dart';
import 'goals_screen.dart';
import 'home_screen.dart';
import 'loans_screen.dart';
import 'transactions_screen.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key});

  static const _screens = [
    HomeScreen(),
    TransactionsScreen(),
    GoalsScreen(),
    LoansScreen(),
    AiAdvisorScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final navigation = context.watch<AppNavigation>();

    return Scaffold(
      body: IndexedStack(
        index: navigation.currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigation.currentIndex,
        onDestinationSelected: navigation.navigateTo,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard_rounded),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long_rounded),
              label: 'Transactions',
            ),
            NavigationDestination(
              icon: Icon(Icons.flag_outlined),
              selectedIcon: Icon(Icons.flag_rounded),
              label: 'Goals',
            ),
            NavigationDestination(
              icon: Icon(Icons.account_balance_outlined),
              selectedIcon: Icon(Icons.account_balance_rounded),
              label: 'Loans',
            ),
            NavigationDestination(
              icon: Icon(Icons.psychology_outlined),
              selectedIcon: Icon(Icons.psychology_rounded),
              label: 'AI Advisor',
            ),
          ],
        ),
    );
  }
}
