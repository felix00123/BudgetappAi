import 'dart:io';

import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

import '../models/account.dart' show Account, accountTypeLabel;
import '../models/category.dart';
import '../models/import_row.dart';
import '../models/transaction.dart';
import '../utils/formatters.dart';

class ExcelService {
  static const _importHeaders = [
    'Date',
    'Type',
    'Account',
    'Category',
    'Title',
    'Amount',
    'Note',
  ];

  Future<String> exportTransactions({
    required List<Transaction> transactions,
    required List<BudgetCategory> categories,
    required List<Account> accounts,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final filtered = transactions.where((t) {
      if (startDate != null && t.date.isBefore(_startOfDay(startDate))) {
        return false;
      }
      if (endDate != null && t.date.isAfter(_endOfDay(endDate))) {
        return false;
      }
      return true;
    }).toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    final excel = Excel.createExcel();
    final sheet = excel['Budget Report'];
    excel.delete('Sheet1');

    _writeHeader(sheet);
    _writeSummary(sheet, filtered);

    final categoryNames = {for (final c in categories) c.id: c.name};
    final accountNames = {for (final a in accounts) a.id: a.name};

    var row = 6;
    for (var col = 0; col < _importHeaders.length; col++) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row))
          .value = TextCellValue(_importHeaders[col]);
    }
    row++;

    for (final t in filtered) {
      _writeImportRow(sheet, row, [
        fileDateFormat.format(t.date),
        t.type.name.toUpperCase(),
        accountNames[t.accountId] ?? 'Unknown',
        categoryNames[t.categoryId] ?? 'Unknown',
        t.title,
        t.amount.toStringAsFixed(2),
        t.note ?? '',
      ]);
      row++;
    }

    _writeDailySummary(sheet, filtered, row + 2);

    return _saveWorkbook(excel, 'budget_report_${_rangeLabel(startDate, endDate)}.xlsx');
  }

  Future<String> generateImportTemplate({
    required List<BudgetCategory> categories,
    required List<Account> accounts,
  }) async {
    final excel = Excel.createExcel();
    excel.delete('Sheet1');

    _writeInstructionsSheet(excel['Instructions']);
    _writeTransactionsTemplateSheet(excel['Transactions']);
    _writeCategoriesReferenceSheet(excel['Categories'], categories);
    _writeAccountsReferenceSheet(excel['Accounts'], accounts);

    return _saveWorkbook(excel, 'budget_import_template.xlsx');
  }

  ImportResult parseImportFile({
    required List<int> bytes,
    required String fileName,
    required List<BudgetCategory> categories,
    required List<Account> accounts,
  }) {
    final excel = Excel.decodeBytes(bytes);
    final sheet = _findTransactionsSheet(excel);
    if (sheet == null) {
      return ImportResult(
        fileName: fileName,
        rows: [
          ImportRow(
            rowNumber: 0,
            error:
                'Could not find a Transactions sheet or valid header row. '
                'Use the import template.',
          ),
        ],
      );
    }

    final headerRow = _findHeaderRow(sheet);
    if (headerRow == null) {
      return ImportResult(
        fileName: fileName,
        rows: [
          ImportRow(
            rowNumber: 0,
            error: 'Missing header row. Expected columns: ${_importHeaders.join(', ')}',
          ),
        ],
      );
    }

    final columnMap = _mapColumns(sheet, headerRow);
    final missing = _importHeaders.where((h) => !columnMap.containsKey(h)).toList();
    if (missing.isNotEmpty) {
      return ImportResult(
        fileName: fileName,
        rows: [
          ImportRow(
            rowNumber: headerRow + 1,
            error: 'Missing required columns: ${missing.join(', ')}',
          ),
        ],
      );
    }

    final categoryByName = {
      for (final c in categories) c.name.toLowerCase(): c,
    };
    final accountByName = {
      for (final a in accounts) a.name.toLowerCase(): a,
    };
    final defaultAccount = accounts.isNotEmpty ? accounts.first : null;
    final incomeFallback = categories.firstWhere(
      (c) => c.type == TransactionType.income,
      orElse: () => categories.first,
    );
    final expenseFallback = categories.firstWhere(
      (c) => c.type == TransactionType.expense,
      orElse: () => categories.first,
    );

    final rows = <ImportRow>[];
    var emptyStreak = 0;
    for (var r = headerRow + 1; r < headerRow + 5001; r++) {
      final rawDate = _cellText(sheet, r, columnMap['Date']!);
      final rawType = _cellText(sheet, r, columnMap['Type']!);
      final rawAccount = _cellText(sheet, r, columnMap['Account']!);
      final rawCategory = _cellText(sheet, r, columnMap['Category']!);
      final rawTitle = _cellText(sheet, r, columnMap['Title']!);
      final rawAmount = _cellText(sheet, r, columnMap['Amount']!);
      final rawNote = columnMap.containsKey('Note')
          ? _cellText(sheet, r, columnMap['Note']!)
          : null;

      if (_isEmptyRow(rawDate, rawType, rawTitle, rawAmount)) {
        emptyStreak++;
        if (emptyStreak >= 10) break;
        continue;
      }
      emptyStreak = 0;

      final parsed = _parseRow(
        rowNumber: r + 1,
        rawDate: rawDate,
        rawType: rawType,
        rawAccount: rawAccount,
        rawCategory: rawCategory,
        rawTitle: rawTitle,
        rawAmount: rawAmount,
        rawNote: rawNote,
        categoryByName: categoryByName,
        accountByName: accountByName,
        defaultAccount: defaultAccount,
        incomeFallback: incomeFallback,
        expenseFallback: expenseFallback,
      );
      rows.add(parsed);
    }

    if (rows.isEmpty) {
      return ImportResult(
        fileName: fileName,
        rows: [
          ImportRow(
            rowNumber: 0,
            error: 'No transaction rows found. Add data below the header row.',
          ),
        ],
      );
    }

    return ImportResult(fileName: fileName, rows: rows);
  }

  Future<void> shareFile(String filePath, {String? text}) async {
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(filePath)],
        text: text ?? 'Budget file',
      ),
    );
  }

  void _writeInstructionsSheet(Sheet sheet) {
    const lines = [
      'Budget App — Import Template',
      '',
      'HOW TO USE',
      '1. Fill in your transactions on the "Transactions" sheet.',
      '2. Check "Categories" and "Accounts" sheets for valid names.',
      '3. Save the file and import it in the Budget App.',
      '',
      'COLUMN RULES',
      '• Date: YYYY-MM-DD (example: 2026-06-15)',
      '• Type: INCOME or EXPENSE',
      '• Account: Must match a name from the Accounts sheet',
      '• Category: Must match a name from the Categories sheet',
      '• Title: Short description of the transaction',
      '• Amount: Positive number only (example: 45.50)',
      '• Note: Optional extra detail',
      '',
      'TIPS',
      '• Do not change the header row on the Transactions sheet.',
      '• Delete the sample rows before importing your real data.',
      '• Type and Account/Category names are not case-sensitive.',
    ];

    for (var i = 0; i < lines.length; i++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: i)).value =
          TextCellValue(lines[i]);
    }
  }

  void _writeTransactionsTemplateSheet(Sheet sheet) {
    for (var col = 0; col < _importHeaders.length; col++) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0))
          .value = TextCellValue(_importHeaders[col]);
    }

    final samples = [
      ['2026-06-01', 'INCOME', 'Bank Account', 'Salary', 'Monthly salary', '3000.00', ''],
      ['2026-06-02', 'EXPENSE', 'Cash', 'Food', 'Groceries', '45.50', 'Weekly shop'],
      ['2026-06-03', 'EXPENSE', 'Bank Account', 'Transport', 'Gas', '35.00', ''],
    ];

    for (var r = 0; r < samples.length; r++) {
      _writeImportRow(sheet, r + 1, samples[r]);
    }
  }

  void _writeCategoriesReferenceSheet(Sheet sheet, List<BudgetCategory> categories) {
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).value =
        TextCellValue('Type');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 0)).value =
        TextCellValue('Category Name');

    var row = 1;
    for (final c in categories) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row)).value =
          TextCellValue(c.type.name.toUpperCase());
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row)).value =
          TextCellValue(c.name);
      row++;
    }
  }

  void _writeAccountsReferenceSheet(Sheet sheet, List<Account> accounts) {
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).value =
        TextCellValue('Account Name');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 0)).value =
        TextCellValue('Type');

    var row = 1;
    for (final a in accounts) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row)).value =
          TextCellValue(a.name);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row)).value =
          TextCellValue(accountTypeLabel(a.type));
      row++;
    }
  }

  void _writeImportRow(Sheet sheet, int row, List<String> values) {
    for (var col = 0; col < values.length; col++) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row))
          .value = TextCellValue(values[col]);
    }
  }

  Sheet? _findTransactionsSheet(Excel excel) {
    if (excel.tables.containsKey('Transactions')) {
      return excel.tables['Transactions'];
    }

    for (final entry in excel.tables.entries) {
      if (_findHeaderRow(entry.value) != null) return entry.value;
    }
    return null;
  }

  int? _findHeaderRow(Sheet sheet) {
    final rowCount = sheet.rows.length;
    for (var r = 0; r < rowCount && r < 30; r++) {
      final headers = <String>[];
      for (var c = 0; c < 10; c++) {
        final text = _cellText(sheet, r, c);
        if (text != null && text.isNotEmpty) headers.add(text.trim());
      }
      final normalized = headers.map((h) => h.toLowerCase()).toList();
      if (normalized.contains('date') &&
          normalized.contains('type') &&
          normalized.contains('amount')) {
        return r;
      }
    }
    return null;
  }

  Map<String, int> _mapColumns(Sheet sheet, int headerRow) {
    final map = <String, int>{};
    for (var c = 0; c < 15; c++) {
      final text = _cellText(sheet, headerRow, c);
      if (text == null || text.isEmpty) continue;
      final key = _normalizeHeader(text);
      if (key != null) map[key] = c;
    }
    return map;
  }

  String? _normalizeHeader(String header) {
    final h = header.trim().toLowerCase();
    return switch (h) {
      'date' => 'Date',
      'type' => 'Type',
      'account' => 'Account',
      'category' => 'Category',
      'title' => 'Title',
      'amount' => 'Amount',
      'note' => 'Note',
      'notes' => 'Note',
      _ => null,
    };
  }

  ImportRow _parseRow({
    required int rowNumber,
    required String? rawDate,
    required String? rawType,
    required String? rawAccount,
    required String? rawCategory,
    required String? rawTitle,
    required String? rawAmount,
    required String? rawNote,
    required Map<String, BudgetCategory> categoryByName,
    required Map<String, Account> accountByName,
    required Account? defaultAccount,
    required BudgetCategory incomeFallback,
    required BudgetCategory expenseFallback,
  }) {
    final errors = <String>[];

    final date = _parseDate(rawDate);
    if (date == null) errors.add('Invalid date "${rawDate ?? ''}"');

    final type = _parseType(rawType);
    if (type == null) errors.add('Type must be INCOME or EXPENSE');

    final amount = _parseAmount(rawAmount);
    if (amount == null || amount <= 0) {
      errors.add('Amount must be a positive number');
    }

    if (rawTitle == null || rawTitle.trim().isEmpty) {
      errors.add('Title is required');
    }

    Account? account;
    if (rawAccount != null && rawAccount.trim().isNotEmpty) {
      account = accountByName[rawAccount.trim().toLowerCase()];
      if (account == null) errors.add('Unknown account "$rawAccount"');
    } else {
      account = defaultAccount;
      if (account == null) errors.add('No account specified and no default available');
    }

    BudgetCategory? category;
    if (rawCategory != null && rawCategory.trim().isNotEmpty) {
      category = categoryByName[rawCategory.trim().toLowerCase()];
      if (category == null) {
        errors.add('Unknown category "$rawCategory"');
      } else if (type != null && category.type != type) {
        errors.add('Category "$rawCategory" does not match type ${type.name}');
      }
    } else if (type != null) {
      category = type == TransactionType.income ? incomeFallback : expenseFallback;
    }

    if (errors.isNotEmpty) {
      return ImportRow(
        rowNumber: rowNumber,
        error: errors.join('; '),
        rawDate: rawDate,
        rawType: rawType,
        rawAccount: rawAccount,
        rawCategory: rawCategory,
        rawTitle: rawTitle,
        rawAmount: rawAmount,
        rawNote: rawNote,
      );
    }

    return ImportRow(
      rowNumber: rowNumber,
      transaction: Transaction(
        id: const Uuid().v4(),
        title: rawTitle!.trim(),
        amount: amount!,
        type: type!,
        categoryId: category!.id,
        accountId: account!.id,
        date: date!,
        note: rawNote?.trim().isEmpty ?? true ? null : rawNote!.trim(),
      ),
      rawDate: rawDate,
      rawType: rawType,
      rawAccount: rawAccount,
      rawCategory: rawCategory,
      rawTitle: rawTitle,
      rawAmount: rawAmount,
      rawNote: rawNote,
    );
  }

  DateTime? _parseDate(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final trimmed = value.trim();

    final iso = DateTime.tryParse(trimmed);
    if (iso != null) return DateTime(iso.year, iso.month, iso.day);

    final parts = trimmed.split(RegExp(r'[/.-]'));
    if (parts.length == 3) {
      final a = int.tryParse(parts[0]);
      final b = int.tryParse(parts[1]);
      final c = int.tryParse(parts[2]);
      if (a != null && b != null && c != null) {
        if (a > 31) return DateTime(a, b, c);
        if (c > 31) return DateTime(c, b, a);
        return DateTime(c, b, a);
      }
    }

    final excelNumber = double.tryParse(trimmed);
    if (excelNumber != null) {
      final base = DateTime(1899, 12, 30);
      return base.add(Duration(days: excelNumber.floor()));
    }

    return null;
  }

  TransactionType? _parseType(String? value) {
    if (value == null) return null;
    final v = value.trim().toLowerCase();
    if (v == 'income' || v == 'inc') return TransactionType.income;
    if (v == 'expense' || v == 'exp') return TransactionType.expense;
    return null;
  }

  double? _parseAmount(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final cleaned = value.replaceAll(RegExp(r'[^\d.-]'), '');
    return double.tryParse(cleaned);
  }

  bool _isEmptyRow(String? date, String? type, String? title, String? amount) {
    return (date == null || date.isEmpty) &&
        (type == null || type.isEmpty) &&
        (title == null || title.isEmpty) &&
        (amount == null || amount.isEmpty);
  }

  String? _cellText(Sheet sheet, int row, int col) {
    final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
    final value = cell.value;
    if (value == null) return null;

    if (value is TextCellValue) {
      return value.value.text ?? value.value.toString();
    }
    if (value is DoubleCellValue) {
      final d = value.value;
      if (d == d.roundToDouble()) return d.toInt().toString();
      return d.toString();
    }
    if (value is IntCellValue) return value.value.toString();
    if (value is DateCellValue) {
      return fileDateFormat.format(value.asDateTimeLocal());
    }
    return value.toString();
  }

  Future<String> _saveWorkbook(Excel excel, String fileName) async {
    final bytes = excel.encode();
    if (bytes == null) throw Exception('Failed to generate Excel file');

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes);
    return file.path;
  }

  void _writeHeader(Sheet sheet) {
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).value =
        TextCellValue('Budget App - Financial Report');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1)).value =
        TextCellValue('Generated: ${fileDateFormat.format(DateTime.now())}');
  }

  void _writeSummary(Sheet sheet, List<Transaction> transactions) {
    final income = transactions
        .where((t) => t.type == TransactionType.income)
        .fold<double>(0, (sum, t) => sum + t.amount);
    final expense = transactions
        .where((t) => t.type == TransactionType.expense)
        .fold<double>(0, (sum, t) => sum + t.amount);

    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 3)).value =
        TextCellValue('Total Income');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 3)).value =
        DoubleCellValue(income);
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 4)).value =
        TextCellValue('Total Expenses');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 4)).value =
        DoubleCellValue(expense);
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 5)).value =
        TextCellValue('Net Balance');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 5)).value =
        DoubleCellValue(income - expense);
  }

  void _writeDailySummary(Sheet sheet, List<Transaction> transactions, int startRow) {
    final dailyTotals = <String, Map<String, double>>{};

    for (final t in transactions) {
      final key = fileDateFormat.format(t.date);
      dailyTotals.putIfAbsent(key, () => {'income': 0, 'expense': 0});
      if (t.type == TransactionType.income) {
        dailyTotals[key]!['income'] = dailyTotals[key]!['income']! + t.amount;
      } else {
        dailyTotals[key]!['expense'] = dailyTotals[key]!['expense']! + t.amount;
      }
    }

    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: startRow)).value =
        TextCellValue('Daily Summary');
    startRow++;
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: startRow)).value =
        TextCellValue('Date');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: startRow)).value =
        TextCellValue('Income');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: startRow)).value =
        TextCellValue('Expenses');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: startRow)).value =
        TextCellValue('Net');
    startRow++;

    for (final entry in dailyTotals.entries) {
      final net = entry.value['income']! - entry.value['expense']!;
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: startRow)).value =
          TextCellValue(entry.key);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: startRow)).value =
          DoubleCellValue(entry.value['income']!);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: startRow)).value =
          DoubleCellValue(entry.value['expense']!);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: startRow)).value =
          DoubleCellValue(net);
      startRow++;
    }
  }

  String _rangeLabel(DateTime? start, DateTime? end) {
    if (start != null && end != null) {
      return '${fileDateFormat.format(start)}_to_${fileDateFormat.format(end)}';
    }
    if (start != null) return 'from_${fileDateFormat.format(start)}';
    if (end != null) return 'until_${fileDateFormat.format(end)}';
    return 'all_time';
  }

  DateTime _startOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  DateTime _endOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day, 23, 59, 59);
}
