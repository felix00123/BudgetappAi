import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'package:budget_app/models/parsed_bank_email.dart';
import 'package:budget_app/providers/budget_provider.dart';
import 'package:budget_app/services/bank_email_parser.dart';
import 'package:budget_app/services/storage_service.dart';

class _FakePathProvider extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  _FakePathProvider(this.root);

  final Directory root;

  @override
  Future<String?> getApplicationDocumentsPath() async => root.path;

  @override
  Future<String?> getTemporaryPath() async => root.path;
}

void main() {
  late Directory tempDir;
  late StorageService storage;
  late BudgetProvider provider;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    tempDir = await Directory.systemTemp.createTemp('budget_outlook_');
    PathProviderPlatform.instance = _FakePathProvider(tempDir);
    Hive.init(tempDir.path);
    storage = StorageService();
    await storage.init();
    provider = BudgetProvider(storage);
    await provider.init();
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('importParsedBankEmails saves new txs and skips duplicates', () async {
    final result = BankEmailResult(
      bank: 'BHD',
      lastFour: '9675',
      accountKind: BankAccountKind.credit,
      transactions: [
        BankTransaction(
          lastFour: '9675',
          bank: 'BHD',
          amount: 100,
          currency: 'DOP',
          merchant: 'Uber',
          date: DateTime(2026, 9, 1),
          kind: BankTransactionKind.purchase,
          categoryId: 'cat_transport',
        ),
      ],
    );

    final emails = [
      ParsedBankEmail(messageId: '1', result: result),
    ];

    final first = await provider.importParsedBankEmails(
      emails,
      messagesChecked: 1,
    );
    expect(first.transactionsSaved, 1);
    expect(first.accountsCreated, 1);

    final second = await provider.importParsedBankEmails(
      emails,
      messagesChecked: 1,
    );
    expect(second.transactionsSaved, 0);
    expect(provider.transactions.where((t) => t.title == 'Uber').length, 1);
  });
}
