import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/transaction.dart';
import '../providers/budget_provider.dart';
import '../providers/locale_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/app_nav_bar.dart';
import '../widgets/empty_state.dart';
import '../widgets/transaction_tile.dart';
import 'add_transaction_screen.dart';
import 'recurring_screen.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(l10n.transactions),
        actions: [
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RecurringScreen()),
            ),
            icon: const Icon(Icons.event_repeat_rounded),
            tooltip: l10n.recurring,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: l10n.all),
            Tab(text: l10n.income),
            Tab(text: l10n.expenses),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: l10n.searchTransactions,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => _searchQuery = ''),
                      )
                    : null,
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
          Expanded(
            child: Consumer<BudgetProvider>(
              builder: (context, provider, _) {
                return TabBarView(
                  controller: _tabController,
                  children: [
                    _TransactionList(
                      transactions: _filter(provider.transactions, provider),
                      onDelete: provider.deleteTransaction,
                    ),
                    _TransactionList(
                      transactions: _filter(
                        provider.transactions
                            .where((t) => t.type == TransactionType.income)
                            .toList(),
                        provider,
                      ),
                      onDelete: provider.deleteTransaction,
                    ),
                    _TransactionList(
                      transactions: _filter(
                        provider.transactions
                            .where((t) => t.type == TransactionType.expense)
                            .toList(),
                        provider,
                      ),
                      onDelete: provider.deleteTransaction,
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'transactions-fab',
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }

  List<Transaction> _filter(List<Transaction> transactions, BudgetProvider provider) {
    if (_searchQuery.isEmpty) return transactions;
    final q = _searchQuery.toLowerCase();
    return transactions
        .where((t) =>
            t.title.toLowerCase().contains(q) ||
            provider.categoryName(t.categoryId).toLowerCase().contains(q) ||
            provider.accountName(t.accountId).toLowerCase().contains(q) ||
            (t.note?.toLowerCase().contains(q) ?? false))
        .toList();
  }
}

class _TransactionList extends StatelessWidget {
  const _TransactionList({
    required this.transactions,
    required this.onDelete,
  });

  final List<Transaction> transactions;
  final Future<void> Function(String id) onDelete;

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return EmptyState(
        icon: Icons.receipt_long_outlined,
        title: context.l10n.noTransactionsFound,
        subtitle: context.l10n.tapToAddTransaction,
      );
    }

    final grouped = <String, List<Transaction>>{};
    for (final t in transactions) {
      final key = '${t.date.year}-${t.date.month}-${t.date.day}';
      grouped.putIfAbsent(key, () => []).add(t);
    }

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(16, 0, 16, AppNavBar.contentInset(context)),
      itemCount: grouped.length,
      itemBuilder: (context, index) {
        final dateKey = grouped.keys.elementAt(index);
        final items = grouped[dateKey]!;
        final date = items.first.date;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                _formatGroupDate(date),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ),
            ...items.map(
              (t) => TransactionTile(
                transaction: t,
                onDelete: () => onDelete(t.id),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddTransactionScreen(existing: t),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatGroupDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);

    if (d == today) return 'Today';
    if (d == today.subtract(const Duration(days: 1))) return 'Yesterday';
    return '${date.day}/${date.month}/${date.year}';
  }
}
