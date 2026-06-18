import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/account.dart';
import '../providers/budget_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../screens/manage_screen.dart';

class AccountSummaryCard extends StatelessWidget {
  const AccountSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BudgetProvider>();

    if (provider.accounts.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Accounts',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ManageScreen()),
              ),
              child: const Text('Manage'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...provider.accounts.map((account) {
          final balance = provider.accountBalance(account.id);
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: account.color.withValues(alpha: 0.15),
                child: Icon(
                  accountTypeIcon(account.type),
                  color: account.color,
                  size: 20,
                ),
              ),
              title: Text(account.name),
              subtitle: Text(accountTypeLabel(account.type)),
              trailing: Text(
                formatCurrency(balance),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: balance >= 0 ? AppColors.income : AppColors.expense,
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
