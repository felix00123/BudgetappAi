import '../models/ai_provider_settings.dart';
import '../models/category.dart';
import '../models/month_summary.dart';
import '../models/transaction.dart';
import 'ai_llm_client.dart';

class MonthSummaryService {
  MonthSummaryService({AiLlmClient? llm}) : _llm = llm ?? AiLlmClient();

  final AiLlmClient _llm;

  static String monthId(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    return '${date.year}-$month';
  }

  /// Closed months that have transactions and still need a stored summary.
  static List<String> missingMonthIds({
    required List<Transaction> transactions,
    required Set<String> existingIds,
    DateTime? now,
  }) {
    final today = now ?? DateTime.now();
    final current = monthId(today);
    final months = <String>{};
    for (final transaction in transactions) {
      final id = monthId(transaction.date);
      if (id.compareTo(current) < 0) months.add(id);
    }
    final missing = months.where((id) => !existingIds.contains(id)).toList()
      ..sort();
    return missing;
  }

  static MonthSummary factsFor({
    required String monthId,
    required List<Transaction> transactions,
    required List<BudgetCategory> categories,
  }) {
    final monthTransactions =
        transactions.where((t) => monthId == MonthSummaryService.monthId(t.date));
    var income = 0.0;
    var expenses = 0.0;
    final byCategory = <String, double>{};
    for (final transaction in monthTransactions) {
      if (transaction.type == TransactionType.income) {
        income += transaction.amount;
      } else {
        expenses += transaction.amount;
        byCategory.update(
          transaction.categoryId,
          (value) => value + transaction.amount,
          ifAbsent: () => transaction.amount,
        );
      }
    }
    final names = {for (final category in categories) category.id: category.name};
    final top = byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return MonthSummary(
      id: monthId,
      income: income,
      expenses: expenses,
      savings: income - expenses,
      topCategories: top
          .take(5)
          .map(
            (entry) => MonthCategoryTotal(
              name: names[entry.key] ?? entry.key,
              amount: entry.value,
            ),
          )
          .toList(),
    );
  }

  Future<String?> narrativeFor({
    required MonthSummary facts,
    required AiProviderSettings settings,
    required bool spanish,
  }) async {
    if (!settings.isConfigured) return null;
    final lang = spanish ? 'Spanish' : 'English';
    final factsText = facts.toHistoryLine();
    try {
      return await _llm.completeText(
        settings: settings,
        systemPrompt:
            'You write a private memory note for a budget advisor. '
            'Use only the facts given. Do not invent amounts, categories, or events. '
            'Write one short paragraph, under 120 words, in $lang. '
            'Describe what happened that month. No bullet list and no advice.',
        userPrompt: factsText,
        temperature: 0.3,
        maxTokens: 220,
      );
    } catch (_) {
      return null;
    }
  }
}
