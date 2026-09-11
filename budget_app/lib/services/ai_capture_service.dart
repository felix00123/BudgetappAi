import 'dart:convert';
import 'dart:typed_data';

import '../models/account.dart';
import '../models/ai_provider_settings.dart';
import '../models/category.dart';
import '../models/expense_draft.dart';
import '../models/transaction.dart';
import 'ai_llm_client.dart';

class AiCaptureException implements Exception {
  const AiCaptureException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Turns a receipt photo or a spoken expense into an [ExpenseDraft] via LLM.
class AiCaptureService {
  AiCaptureService({AiLlmClient? llm}) : _llm = llm ?? AiLlmClient();

  final AiLlmClient _llm;

  Future<ExpenseDraft> extractFromReceipt({
    required Uint8List imageBytes,
    required String mimeType,
    required List<BudgetCategory> categories,
    required List<Account> accounts,
    required AiProviderSettings settings,
  }) async {
    _requireConfigured(settings);
    try {
      final raw = await _llm.completeWithImage(
        settings: settings,
        systemPrompt: _systemPrompt,
        userPrompt: _instructions(
          categories: categories,
          accounts: accounts,
          sourceHint:
              'Read this receipt or purchase photo. Extract the merchant, '
              'total amount, date if visible, and best matching category.',
        ),
        imageBytes: imageBytes,
        mimeType: mimeType,
        temperature: 0.1,
        maxTokens: 400,
      );
      return parseExpenseDraftJson(
        raw,
        captureKind: 'photo',
        categories: categories,
        accounts: accounts,
      );
    } on AiLlmException catch (e) {
      throw AiCaptureException(e.message);
    }
  }

  Future<ExpenseDraft> extractFromUtterance({
    required String transcript,
    required List<BudgetCategory> categories,
    required List<Account> accounts,
    required AiProviderSettings settings,
  }) async {
    _requireConfigured(settings);
    final trimmed = transcript.trim();
    if (trimmed.isEmpty) {
      throw const AiCaptureException('Nothing was heard. Try speaking again.');
    }

    try {
      final raw = await _llm.completeText(
        settings: settings,
        systemPrompt: _systemPrompt,
        userPrompt: _instructions(
          categories: categories,
          accounts: accounts,
          sourceHint:
              'The user said this expense out loud. Parse amount, merchant '
              'or title, type (expense or income), and best category.\n\n'
              'Utterance: "$trimmed"',
        ),
        temperature: 0.1,
        maxTokens: 400,
      );
      return parseExpenseDraftJson(
        raw,
        captureKind: 'voice',
        categories: categories,
        accounts: accounts,
      );
    } on AiLlmException catch (e) {
      throw AiCaptureException(e.message);
    }
  }

  /// Parses model output into an [ExpenseDraft]. Exposed for unit tests.
  static ExpenseDraft parseExpenseDraftJson(
    String raw, {
    required String captureKind,
    required List<BudgetCategory> categories,
    required List<Account> accounts,
  }) {
    final map = decodeModelJson(raw);
    final amount = _readAmount(map['amount']);
    if (amount == null || amount <= 0) {
      throw const AiCaptureException(
        'Could not find a valid amount. Try again or enter it manually.',
      );
    }

    final title = (map['title'] as String?)?.trim();
    if (title == null || title.isEmpty) {
      throw const AiCaptureException(
        'Could not find a merchant or title. Try again or enter it manually.',
      );
    }

    final typeName = (map['type'] as String?)?.toLowerCase().trim();
    final type = typeName == 'income'
        ? TransactionType.income
        : TransactionType.expense;

    final categoryIds = {
      for (final c in categories.where((c) => c.type == type)) c.id,
    };
    var categoryId = map['categoryId'] as String?;
    if (categoryId == null || !categoryIds.contains(categoryId)) {
      categoryId = categoryIds.isNotEmpty
          ? (type == TransactionType.income
              ? (categoryIds.contains('cat_income_other')
                  ? 'cat_income_other'
                  : categoryIds.first)
              : (categoryIds.contains('cat_expense_other')
                  ? 'cat_expense_other'
                  : categoryIds.first))
          : null;
    }

    var accountId = map['accountId'] as String?;
    final accountIds = {for (final a in accounts) a.id};
    if (accountId == null || !accountIds.contains(accountId)) {
      accountId = accounts.isNotEmpty ? accounts.first.id : null;
    }

    final date = _readDate(map['date']) ?? DateTime.now();
    final note = (map['note'] as String?)?.trim();
    final confidence = (map['confidence'] as num?)?.toDouble();

    return ExpenseDraft(
      title: title,
      amount: amount,
      type: type,
      categoryId: categoryId,
      accountId: accountId,
      date: date,
      note: (note == null || note.isEmpty) ? null : note,
      captureKind: captureKind,
      confidence: confidence,
    );
  }

  /// Strips markdown fences and decodes the first JSON object in [raw].
  static Map<String, dynamic> decodeModelJson(String raw) {
    var text = raw.trim();
    if (text.startsWith('```')) {
      text = text.replaceFirst(RegExp(r'^```(?:json)?\s*', caseSensitive: false), '');
      text = text.replaceFirst(RegExp(r'\s*```$'), '');
      text = text.trim();
    }

    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start < 0 || end <= start) {
      throw const AiCaptureException(
        'The AI response was not valid. Try again.',
      );
    }

    try {
      final decoded = jsonDecode(text.substring(start, end + 1));
      if (decoded is! Map<String, dynamic>) {
        throw const AiCaptureException(
          'The AI response was not valid. Try again.',
        );
      }
      return decoded;
    } on FormatException {
      throw const AiCaptureException(
        'The AI response was not valid. Try again.',
      );
    }
  }

  void _requireConfigured(AiProviderSettings settings) {
    if (!settings.isConfigured) {
      throw AiCaptureException(settings.setupHint);
    }
  }

  static const _systemPrompt =
      'You extract structured budget transactions from receipts or spoken '
      'expenses. Reply with ONLY a JSON object, no markdown, no commentary.';

  String _instructions({
    required List<BudgetCategory> categories,
    required List<Account> accounts,
    required String sourceHint,
  }) {
    final categoryLines = categories
        .map((c) => '- ${c.id}: ${c.name} (${c.type.name})')
        .join('\n');
    final accountLines = accounts
        .map((a) => '- ${a.id}: ${a.name} (${a.type.name})')
        .join('\n');

    return '''
$sourceHint

Return JSON with these keys:
{
  "title": "merchant or short description",
  "amount": 0.00,
  "type": "expense" or "income",
  "categoryId": "one of the category ids below",
  "accountId": "one of the account ids below or null",
  "date": "YYYY-MM-DD or null if unknown",
  "note": "optional short note or null",
  "confidence": 0.0 to 1.0
}

Rules:
- amount must be a positive number (no currency symbols).
- categoryId MUST be one of the listed ids for the chosen type.
- Prefer expense unless the user clearly describes income.
- If the date is missing, use null.

Categories:
$categoryLines

Accounts:
$accountLines
''';
  }

  static double? _readAmount(Object? value) {
    if (value is num) return value.toDouble();
    if (value is String) {
      final cleaned = value
          .replaceAll(RegExp(r'[^\d,.\-]'), '')
          .replaceAll(',', '');
      return double.tryParse(cleaned);
    }
    return null;
  }

  static DateTime? _readDate(Object? value) {
    if (value == null) return null;
    if (value is String && value.trim().isNotEmpty) {
      return DateTime.tryParse(value.trim());
    }
    return null;
  }
}
