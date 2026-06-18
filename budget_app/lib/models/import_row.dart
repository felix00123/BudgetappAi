import '../models/transaction.dart';

class ImportRow {
  ImportRow({
    required this.rowNumber,
    this.transaction,
    this.error,
    this.rawDate,
    this.rawType,
    this.rawAccount,
    this.rawCategory,
    this.rawTitle,
    this.rawAmount,
    this.rawNote,
  });

  final int rowNumber;
  final Transaction? transaction;
  final String? error;
  final String? rawDate;
  final String? rawType;
  final String? rawAccount;
  final String? rawCategory;
  final String? rawTitle;
  final String? rawAmount;
  final String? rawNote;

  bool get isValid => error == null && transaction != null;
}

class ImportResult {
  ImportResult({
    required this.rows,
    required this.fileName,
  });

  final List<ImportRow> rows;
  final String fileName;

  List<ImportRow> get validRows => rows.where((r) => r.isValid).toList();
  List<ImportRow> get invalidRows => rows.where((r) => !r.isValid).toList();
  int get validCount => validRows.length;
  int get invalidCount => invalidRows.length;
  bool get hasValidRows => validCount > 0;
}
