import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'package:budget_app/models/parsed_bank_email.dart';
import 'package:budget_app/models/transaction.dart';
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

  test('skips a second sync of the same spend with a different fingerprint',
      () async {
    final first = await provider.importParsedBankEmails(
      [
        ParsedBankEmail(
          messageId: 'gmail-1',
          result: BankEmailResult(
            bank: 'Gmail',
            lastFour: '5949',
            transactions: [
              BankTransaction(
                lastFour: '5949',
                bank: 'Gmail',
                amount: 1000,
                currency: 'DOP',
                merchant: 'BANCO POPULAR ESTACION AM D',
                date: DateTime(2026, 9, 10, 8),
              ),
            ],
          ),
        ),
      ],
      messagesChecked: 1,
    );
    expect(first.transactionsSaved, 1);

    final second = await provider.importParsedBankEmails(
      [
        ParsedBankEmail(
          messageId: 'outlook-1',
          result: BankEmailResult(
            bank: 'Banreservas',
            lastFour: '5949',
            transactions: [
              BankTransaction(
                lastFour: '5949',
                bank: 'Banreservas',
                amount: 1000,
                currency: 'DOP',
                merchant: 'BANCO POPULAR ESTACION AM DOMINGO',
                date: DateTime(2026, 9, 10, 21, 5),
              ),
            ],
          ),
        ),
      ],
      messagesChecked: 1,
    );
    expect(second.transactionsSaved, 0);
    expect(provider.transactions, hasLength(1));
  });

  test('clearSyncedEmailData removes imported txs so a later sync is fresh',
      () async {
    await provider.importParsedBankEmails(
      [
        ParsedBankEmail(
          messageId: '1',
          result: BankEmailResult(
            bank: 'BHD',
            lastFour: '9675',
            transactions: [
              BankTransaction(
                lastFour: '9675',
                bank: 'BHD',
                amount: 100,
                currency: 'DOP',
                merchant: 'Uber',
                date: DateTime(2026, 9, 1),
              ),
            ],
          ),
        ),
      ],
      messagesChecked: 1,
    );
    expect(provider.accountByLastFour('9675'), isNotNull);

    final message = await provider.clearSyncedEmailData();
    expect(message, contains('Cleared'));
    expect(
      provider.transactions.where((t) => t.source == TransactionSource.email),
      isEmpty,
    );
    expect(provider.accountByLastFour('9675'), isNull);

    final again = await provider.importParsedBankEmails(
      [
        ParsedBankEmail(
          messageId: '1',
          result: BankEmailResult(
            bank: 'BHD',
            lastFour: '9675',
            transactions: [
              BankTransaction(
                lastFour: '9675',
                bank: 'BHD',
                amount: 100,
                currency: 'DOP',
                merchant: 'Uber',
                date: DateTime(2026, 9, 1),
              ),
            ],
          ),
        ),
      ],
      messagesChecked: 1,
    );
    expect(again.transactionsSaved, 1);
  });
}
