import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:budget_app/models/account.dart';
import 'package:budget_app/models/ai_provider_settings.dart';
import 'package:budget_app/models/category.dart';
import 'package:budget_app/models/transaction.dart';
import 'package:budget_app/services/ai_capture_service.dart';

void main() {
  final categories = defaultCategories();
  final accounts = [
    Account(
      id: 'acc_cash',
      name: 'Cash',
      type: AccountType.cash,
      colorValue: 0xFF22C55E,
    ),
  ];

  group('decodeModelJson', () {
    test('strips markdown fences', () {
      final map = AiCaptureService.decodeModelJson('''
```json
{"title": "Uber", "amount": 350}
```
''');
      expect(map['title'], 'Uber');
      expect(map['amount'], 350);
    });

    test('throws when there is no JSON object', () {
      expect(
        () => AiCaptureService.decodeModelJson('no json here'),
        throwsA(isA<AiCaptureException>()),
      );
    });
  });

  group('parseExpenseDraftJson', () {
    test('maps a valid expense payload', () {
      final draft = AiCaptureService.parseExpenseDraftJson(
        '''
{
  "title": "Uber",
  "amount": 350.5,
  "type": "expense",
  "categoryId": "cat_transport",
  "accountId": "acc_cash",
  "date": "2026-09-10",
  "note": "Airport",
  "confidence": 0.91
}
''',
        captureKind: 'voice',
        categories: categories,
        accounts: accounts,
      );

      expect(draft.title, 'Uber');
      expect(draft.amount, 350.5);
      expect(draft.type, TransactionType.expense);
      expect(draft.categoryId, 'cat_transport');
      expect(draft.accountId, 'acc_cash');
      expect(draft.date.year, 2026);
      expect(draft.date.month, 9);
      expect(draft.date.day, 10);
      expect(draft.note, 'Airport');
      expect(draft.captureKind, 'voice');
      expect(draft.confidence, 0.91);
    });

    test('falls back when categoryId is unknown', () {
      final draft = AiCaptureService.parseExpenseDraftJson(
        '{"title":"Lunch","amount":120,"type":"expense","categoryId":"cat_fake"}',
        captureKind: 'photo',
        categories: categories,
        accounts: accounts,
      );

      expect(draft.categoryId, 'cat_expense_other');
      expect(draft.captureKind, 'photo');
    });

    test('parses amount from a string with currency noise', () {
      final draft = AiCaptureService.parseExpenseDraftJson(
        '{"title":"Light bill","amount":"RD\$1,200.00","type":"expense","categoryId":"cat_bills"}',
        captureKind: 'voice',
        categories: categories,
        accounts: accounts,
      );

      expect(draft.amount, 1200);
      expect(draft.categoryId, 'cat_bills');
    });

    test('rejects missing amount', () {
      expect(
        () => AiCaptureService.parseExpenseDraftJson(
          '{"title":"Uber","amount":0}',
          captureKind: 'voice',
          categories: categories,
          accounts: accounts,
        ),
        throwsA(
          isA<AiCaptureException>().having(
            (e) => e.message,
            'message',
            contains('amount'),
          ),
        ),
      );
    });

    test('rejects missing title', () {
      expect(
        () => AiCaptureService.parseExpenseDraftJson(
          '{"title":"  ","amount":50}',
          captureKind: 'photo',
          categories: categories,
          accounts: accounts,
        ),
        throwsA(isA<AiCaptureException>()),
      );
    });
  });

  group('provider config guard', () {
    test('extractFromUtterance requires configured settings', () async {
      final service = AiCaptureService();
      expect(
        () => service.extractFromUtterance(
          transcript: 'gasté 100 en comida',
          categories: categories,
          accounts: accounts,
          settings: const AiProviderSettings(),
        ),
        throwsA(
          isA<AiCaptureException>().having(
            (e) => e.message,
            'message',
            contains('OpenAI API key'),
          ),
        ),
      );
    });

    test('extractFromReceipt requires configured settings', () async {
      final service = AiCaptureService();
      expect(
        () => service.extractFromReceipt(
          imageBytes: Uint8List(0),
          mimeType: 'image/jpeg',
          categories: categories,
          accounts: accounts,
          settings: const AiProviderSettings(
            kind: AiProviderKind.gemini,
          ),
        ),
        throwsA(
          isA<AiCaptureException>().having(
            (e) => e.message,
            'message',
            contains('Gemini'),
          ),
        ),
      );
    });
  });
}
