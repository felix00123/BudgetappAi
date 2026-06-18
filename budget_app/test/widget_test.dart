import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budget_app/models/account.dart';
import 'package:budget_app/models/category.dart';
import 'package:budget_app/models/savings_goal.dart';
import 'package:budget_app/models/transaction.dart';
import 'package:budget_app/services/excel_service.dart';

void main() {
  final categories = defaultCategories();
  final accounts = defaultAccounts();
  final excelService = ExcelService();

  test('SavingsGoal calculates months to reach', () {
    final goal = SavingsGoal(
      id: '1',
      name: 'Car',
      targetAmount: 10000,
      currentSaved: 2000,
      createdAt: DateTime.now(),
    );

    expect(goal.monthsToReach(500), 16);
    expect(goal.remaining, 8000);
  });

  test('Transaction serializes correctly', () {
    final transaction = Transaction(
      id: '1',
      title: 'Salary',
      amount: 3000,
      type: TransactionType.income,
      categoryId: 'cat_salary',
      accountId: 'acc_bank',
      date: DateTime(2026, 6, 1),
    );

    final json = transaction.toJson();
    final restored = Transaction.fromJson(json);

    expect(restored.title, 'Salary');
    expect(restored.amount, 3000);
    expect(restored.type, TransactionType.income);
    expect(restored.categoryId, 'cat_salary');
    expect(restored.accountId, 'acc_bank');
  });

  test('Transaction migrates legacy category field', () {
    final json = {
      'id': '1',
      'title': 'Groceries',
      'amount': 50,
      'type': 'expense',
      'category': 'Food',
      'date': '2026-06-01T00:00:00.000',
    };

    final restored = Transaction.fromJson(json);
    expect(restored.categoryId, 'cat_food');
    expect(restored.accountId, 'acc_cash');
  });

  test('Import parser reads valid transaction rows', () {
    final excel = Excel.createExcel();
    excel.delete('Sheet1');
    final sheet = excel['Transactions'];

    const headers = ['Date', 'Type', 'Account', 'Category', 'Title', 'Amount', 'Note'];
    for (var c = 0; c < headers.length; c++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 0)).value =
          TextCellValue(headers[c]);
    }

    final rows = [
      ['2026-06-01', 'INCOME', 'Bank Account', 'Salary', 'Paycheck', '2500', ''],
      ['2026-06-02', 'EXPENSE', 'Cash', 'Food', 'Lunch', '12.50', ''],
    ];

    for (var r = 0; r < rows.length; r++) {
      for (var c = 0; c < rows[r].length; c++) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r + 1)).value =
            TextCellValue(rows[r][c]);
      }
    }

    final bytes = excel.encode();
    expect(bytes, isNotNull);

    final result = excelService.parseImportFile(
      bytes: bytes!,
      fileName: 'test.xlsx',
      categories: categories,
      accounts: accounts,
    );

    expect(result.validCount, 2);
    expect(result.invalidCount, 0);
  });
}
