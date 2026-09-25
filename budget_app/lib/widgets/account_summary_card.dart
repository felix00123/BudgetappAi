import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/account.dart';
import '../providers/budget_provider.dart';
import '../providers/locale_controller.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../screens/manage_screen.dart';

/// Horizontal strip of account balances, swipeable when there are several.
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
            Text(
              context.l10n.accounts,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ManageScreen()),
              ),
              child: Text(context.l10n.manage),
            ),
          ],
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 136,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            padding: EdgeInsets.zero,
            itemCount: provider.accounts.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final account = provider.accounts[index];
              return _AccountTile(
                account: account,
                balance: provider.accountBalance(account.id),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _AccountTile extends StatelessWidget {
  const _AccountTile({required this.account, required this.balance});

  final Account account;
  final double balance;

  @override
  Widget build(BuildContext context) {
    final subtitle = account.lastFour == null
        ? accountTypeLabel(account.type)
        : '${accountTypeLabel(account.type)} ··${account.lastFour}';

    return Container(
      width: 168,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: account.color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(
                  accountTypeIcon(account.type),
                  color: account.color,
                  size: 17,
                ),
              ),
              const Spacer(),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: account.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.bottomLeft,
                  child: SizedBox(
                    width: constraints.maxWidth,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          account.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13.5,
                            height: 1.2,
                          ),
                        ),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11.5,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            formatCurrency(balance),
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 17,
                              height: 1.15,
                              letterSpacing: -0.5,
                              color: balance < 0
                                  ? AppColors.expense
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
