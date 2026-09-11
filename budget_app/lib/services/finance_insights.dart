import '../models/transaction.dart';

/// Spending rollups used by the insights screen.
class AnalyticsSnapshot {
  const AnalyticsSnapshot({
    required this.spending,
    required this.income,
    required this.categoryTotals,
    required this.monthlyTotals,
    required this.topMerchant,
    required this.transactionCount,
  });

  final double spending;
  final double income;

  /// Expense totals per category id, highest first.
  final Map<String, double> categoryTotals;

  /// Expense totals per month, oldest first. Empty months are kept at zero so
  /// the bar chart always shows a full window.
  final Map<DateTime, double> monthlyTotals;

  final String? topMerchant;
  final int transactionCount;

  double get savings => income - spending;

  bool get isEmpty => transactionCount == 0;
}

AnalyticsSnapshot buildAnalytics(
  List<Transaction> transactions, {
  int months = 6,
  DateTime? now,
}) {
  final today = now ?? DateTime.now();
  final start = DateTime(today.year, today.month - months + 1);
  final inRange = transactions.where((t) => !t.date.isBefore(start));

  final categories = <String, double>{};
  final monthTotals = <DateTime, double>{
    for (var index = months - 1; index >= 0; index--)
      DateTime(today.year, today.month - index): 0,
  };
  final merchants = <String, double>{};
  var spending = 0.0;
  var income = 0.0;
  var count = 0;

  for (final item in inRange) {
    count++;
    if (item.type == TransactionType.income) {
      income += item.amount;
      continue;
    }

    spending += item.amount;
    categories[item.categoryId] = (categories[item.categoryId] ?? 0) + item.amount;

    final month = DateTime(item.date.year, item.date.month);
    if (monthTotals.containsKey(month)) {
      monthTotals[month] = monthTotals[month]! + item.amount;
    }
    merchants[item.title] = (merchants[item.title] ?? 0) + item.amount;
  }

  final sortedCategories = categories.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  final sortedMerchants = merchants.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  return AnalyticsSnapshot(
    spending: spending,
    income: income,
    categoryTotals: Map.fromEntries(sortedCategories),
    monthlyTotals: monthTotals,
    topMerchant: sortedMerchants.isEmpty ? null : sortedMerchants.first.key,
    transactionCount: count,
  );
}
