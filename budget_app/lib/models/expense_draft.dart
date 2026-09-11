import 'transaction.dart';

/// Temporary draft produced by AI from a receipt photo or a voice utterance.
/// Not persisted to Hive; the user confirms it before it becomes a Transaction.
class ExpenseDraft {
  const ExpenseDraft({
    required this.title,
    required this.amount,
    this.type = TransactionType.expense,
    this.categoryId,
    this.accountId,
    required this.date,
    this.note,
    required this.captureKind,
    this.confidence,
  });

  final String title;
  final double amount;
  final TransactionType type;
  final String? categoryId;
  final String? accountId;
  final DateTime date;
  final String? note;

  /// `photo` or `voice`.
  final String captureKind;
  final double? confidence;

  ExpenseDraft copyWith({
    String? title,
    double? amount,
    TransactionType? type,
    String? categoryId,
    String? accountId,
    DateTime? date,
    String? note,
    String? captureKind,
    double? confidence,
  }) =>
      ExpenseDraft(
        title: title ?? this.title,
        amount: amount ?? this.amount,
        type: type ?? this.type,
        categoryId: categoryId ?? this.categoryId,
        accountId: accountId ?? this.accountId,
        date: date ?? this.date,
        note: note ?? this.note,
        captureKind: captureKind ?? this.captureKind,
        confidence: confidence ?? this.confidence,
      );
}
