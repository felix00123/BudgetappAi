import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_navigation.dart';
import '../widgets/ambient_background.dart';
import '../widgets/app_nav_bar.dart';
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

  static const _navItems = [
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

  @override
  Widget build(BuildContext context) {
    final navigation = context.watch<AppNavigation>();

    return Scaffold(
      // Content slides under the floating bar so the frost has something to pick up.
      extendBody: true,
      backgroundColor: Colors.transparent,
      body: AmbientBackground(
        child: IndexedStack(
          index: navigation.currentIndex,
          children: _screens,
        ),
      ),
      bottomNavigationBar: AppNavBar(
        currentIndex: navigation.currentIndex,
        onSelected: navigation.navigateTo,
        items: _navItems,
      ),
    );
  }
}
