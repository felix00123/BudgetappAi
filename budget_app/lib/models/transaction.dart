enum TransactionType { income, expense }

enum TransactionSource { manual, excel, email, ai }

class Transaction {
  final String id;
  final String title;
  final double amount;
  final TransactionType type;
  final String categoryId;
  final String accountId;
  final DateTime date;
  final String? note;
  final TransactionSource source;

  /// Stable id of the originating record, used to avoid importing twice.
  final String? externalId;

  Transaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.categoryId,
    required this.accountId,
    required this.date,
    this.note,
    this.source = TransactionSource.manual,
    this.externalId,
      });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'amount': amount,
        'type': type.name,
        'categoryId': categoryId,
        'accountId': accountId,
        'date': date.toIso8601String(),
        'note': note,
        'source': source.name,
        'externalId': externalId,
      };

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
        id: json['id'] as String,
        title: json['title'] as String,
        amount: (json['amount'] as num).toDouble(),
        type: TransactionType.values.byName(json['type'] as String),
        categoryId: json['categoryId'] as String? ??
            _legacyCategoryId(json['category'] as String?, json['type'] as String),
        accountId: json['accountId'] as String? ?? 'acc_cash',
        date: DateTime.parse(json['date'] as String),
        note: json['note'] as String?,
        source: _sourceFromJson(json['source'] as String?),
        externalId: json['externalId'] as String?,
      );

  static TransactionSource _sourceFromJson(String? value) {
    for (final source in TransactionSource.values) {
      if (source.name == value) return source;
    }
    return TransactionSource.manual;
  }

  static String _legacyCategoryId(String? name, String type) {
    if (name == null) {
      return type == 'income' ? 'cat_income_other' : 'cat_expense_other';
    }
    return switch (name) {
      'Salary' => 'cat_salary',
      'Freelance' => 'cat_freelance',
      'Investment' => 'cat_investment',
      'Gift' => 'cat_gift',
      'Food' => 'cat_food',
      'Transport' => 'cat_transport',
      'Housing' => 'cat_housing',
      'Entertainment' => 'cat_entertainment',
      'Health' => 'cat_health',
      'Shopping' => 'cat_shopping',
      'Bills' => 'cat_bills',
      'Education' => 'cat_education',
      _ => type == 'income' ? 'cat_income_other' : 'cat_expense_other',
    };
  }

  Transaction copyWith({
    String? title,
    double? amount,
    TransactionType? type,
    String? categoryId,
    String? accountId,
    DateTime? date,
    String? note,
    TransactionSource? source,
    String? externalId,
  }) =>
      Transaction(
        id: id,
        title: title ?? this.title,
        amount: amount ?? this.amount,
        type: type ?? this.type,
        categoryId: categoryId ?? this.categoryId,
        accountId: accountId ?? this.accountId,
        date: date ?? this.date,
        note: note ?? this.note,
        source: source ?? this.source,
        externalId: externalId ?? this.externalId,
      );
}
