import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/budget_provider.dart';
import '../theme/app_theme.dart';

/// Deletes imported bank-alert data so a test sync can run from scratch.
class ClearSyncedDataButton extends StatelessWidget {
  const ClearSyncedDataButton({this.busy = false, super.key});

  final bool busy;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: busy ? null : () => _confirm(context),
      icon: const Icon(Icons.delete_sweep_outlined),
      label: const Text('Clear synced data'),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        foregroundColor: AppColors.expense,
        side: const BorderSide(color: AppColors.expense),
      ),
    );
  }

  Future<void> _confirm(BuildContext context) async {
    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear synced data?'),
        content: const Text(
          'This deletes transactions, balances, and card accounts created '
          'from Gmail, Outlook, or pasted bank emails. Manual entries stay. '
          'Gmail and Outlook stay connected so you can sync again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.expense),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (shouldClear != true || !context.mounted) return;

    final message =
        await context.read<BudgetProvider>().clearSyncedEmailData();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
