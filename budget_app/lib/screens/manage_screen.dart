import 'package:flutter/material.dart';

import '../models/transaction.dart';
import 'manage_accounts_screen.dart';
import 'manage_categories_screen.dart';

class ManageScreen extends StatelessWidget {
  const ManageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Categories & Accounts'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Categories', icon: Icon(Icons.category_outlined)),
              Tab(text: 'Accounts', icon: Icon(Icons.account_balance_wallet_outlined)),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            ManageCategoriesScreen(),
            ManageAccountsScreen(),
          ],
        ),
        floatingActionButton: Builder(
          builder: (context) {
            final controller = DefaultTabController.of(context);
            return AnimatedBuilder(
              animation: controller,
              builder: (context, _) {
                final isAccounts = controller.index == 1;
                return FloatingActionButton(
                  onPressed: () {
                    if (isAccounts) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AccountEditorScreen(),
                        ),
                      );
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CategoryEditorScreen(
                            type: TransactionType.expense,
                          ),
                        ),
                      );
                    }
                  },
                  child: const Icon(Icons.add),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
