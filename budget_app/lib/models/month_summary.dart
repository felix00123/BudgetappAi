class MonthCategoryTotal {
  const MonthCategoryTotal({required this.name, required this.amount});

  final String name;
  final double amount;

  Map<String, dynamic> toJson() => {'name': name, 'amount': amount};

  factory MonthCategoryTotal.fromJson(Map<String, dynamic> json) {
    return MonthCategoryTotal(
      name: json['name'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// Compressed memory of one closed calendar month for the AI advisor.
class MonthSummary {
  const MonthSummary({
    required this.id,
    required this.income,
    required this.expenses,
    required this.savings,
    required this.topCategories,
    this.narrative,
  });

  /// `YYYY-MM`.
  final String id;
  final double income;
  final double expenses;
  final double savings;
  final List<MonthCategoryTotal> topCategories;
  final String? narrative;

  Map<String, dynamic> toJson() => {
        'id': id,
        'income': income,
        'expenses': expenses,
        'savings': savings,
        'topCategories': topCategories.map((c) => c.toJson()).toList(),
        'narrative': narrative,
      };

  factory MonthSummary.fromJson(Map<String, dynamic> json) {
    final raw = json['topCategories'];
    final categories = raw is List
        ? raw
            .whereType<Map>()
            .map((e) => MonthCategoryTotal.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : <MonthCategoryTotal>[];
    return MonthSummary(
      id: json['id'] as String,
      income: (json['income'] as num?)?.toDouble() ?? 0,
      expenses: (json['expenses'] as num?)?.toDouble() ?? 0,
      savings: (json['savings'] as num?)?.toDouble() ?? 0,
      topCategories: categories,
      narrative: json['narrative'] as String?,
    );
  }

  String toHistoryLine() {
    final cats = topCategories
        .take(5)
        .map((c) => '${c.name} ${c.amount.toStringAsFixed(0)}')
        .join(', ');
    final note = (narrative == null || narrative!.trim().isEmpty)
        ? ''
        : '\n${narrative!.trim()}';
    return '$id income ${income.toStringAsFixed(0)}, '
        'expenses ${expenses.toStringAsFixed(0)}, '
        'savings ${savings.toStringAsFixed(0)}'
        '${cats.isEmpty ? '' : '. Top expenses: $cats.'}'
        '$note';
  }
}
