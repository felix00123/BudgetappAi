import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../models/account.dart';
import '../models/ai_provider_settings.dart';
import '../models/balance_snapshot.dart';
import '../models/category.dart';
import '../models/chat_message.dart';
import '../models/loan.dart';
import '../models/month_summary.dart';
import '../models/recurring_transaction.dart';
import '../models/savings_goal.dart';
import '../models/transaction.dart';

class StorageService {
  static const _transactionsBox = 'transactions';
  static const _goalsBox = 'goals';
  static const _loansBox = 'loans';
  static const _recurringBox = 'recurring';
  static const _chatBox = 'chat';
  static const _settingsBox = 'settings';
  static const _categoriesBox = 'categories';
  static const _accountsBox = 'accounts';
  static const _balanceSnapshotsBox = 'balance_snapshots';
  static const _monthSummariesBox = 'month_summaries';
  static const _tombstonesBox = 'sync_tombstones';

  static const syncEntities = [
    'accounts',
    'categories',
    'transactions',
    'recurring_transactions',
    'savings_goals',
    'loans',
    'balance_snapshots',
    'chat_messages',
    'month_summaries',
  ];

  late Box<String> _transactions;
  late Box<String> _goals;
  late Box<String> _loans;
  late Box<String> _recurring;
  late Box<String> _chat;
  late Box _settings;
  late Box<String> _categories;
  late Box<String> _accounts;
  late Box<String> _balanceSnapshots;
  late Box<String> _monthSummaries;
  late Box<String> _tombstones;

  bool _muteChanges = false;
  void Function()? onLocalChange;

  Future<void> init() async {
    await Hive.initFlutter();
    _transactions = await Hive.openBox<String>(_transactionsBox);
    _goals = await Hive.openBox<String>(_goalsBox);
    _loans = await Hive.openBox<String>(_loansBox);
    _recurring = await Hive.openBox<String>(_recurringBox);
    _chat = await Hive.openBox<String>(_chatBox);
    _settings = await Hive.openBox(_settingsBox);
    _categories = await Hive.openBox<String>(_categoriesBox);
    _accounts = await Hive.openBox<String>(_accountsBox);
    _balanceSnapshots = await Hive.openBox<String>(_balanceSnapshotsBox);
    _monthSummaries = await Hive.openBox<String>(_monthSummariesBox);
    _tombstones = await Hive.openBox<String>(_tombstonesBox);

    await _seedDefaultsIfNeeded();
  }

  Future<void> _seedDefaultsIfNeeded() async {
    if (_categories.isEmpty) {
      for (final category in defaultCategories()) {
        await saveCategory(category);
      }
    }
    if (_accounts.isEmpty) {
      for (final account in defaultAccounts()) {
        await saveAccount(account);
      }
    }
  }

  List<Transaction> getTransactions() {
    return _transactions.values
        .map((e) => Transaction.fromJson(jsonDecode(e) as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  Future<void> saveTransaction(Transaction transaction, {String? updatedAt}) async {
    await _put(_transactions, 'transactions', transaction.id, transaction.toJson(), updatedAt);
  }

  Future<void> deleteTransaction(String id, {bool tombstone = true}) async {
    await _remove(_transactions, 'transactions', id, tombstone: tombstone);
  }

  List<BudgetCategory> getCategories() {
    return _categories.values
        .map((e) => BudgetCategory.fromJson(jsonDecode(e) as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  Future<void> saveCategory(BudgetCategory category, {String? updatedAt}) async {
    await _put(_categories, 'categories', category.id, category.toJson(), updatedAt);
  }

  Future<void> deleteCategory(String id, {bool tombstone = true}) async {
    await _remove(_categories, 'categories', id, tombstone: tombstone);
  }

  List<Account> getAccounts() {
    return _accounts.values
        .map((e) => Account.fromJson(jsonDecode(e) as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  Future<void> saveAccount(Account account, {String? updatedAt}) async {
    await _put(_accounts, 'accounts', account.id, account.toJson(), updatedAt);
  }

  Future<void> deleteAccount(String id, {bool tombstone = true}) async {
    await _remove(_accounts, 'accounts', id, tombstone: tombstone);
  }

  List<BalanceSnapshot> getBalanceSnapshots() {
    return _balanceSnapshots.values
        .map((e) => BalanceSnapshot.fromJson(jsonDecode(e) as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.capturedAt.compareTo(b.capturedAt));
  }

  Future<void> saveBalanceSnapshot(BalanceSnapshot snapshot, {String? updatedAt}) async {
    await _put(_balanceSnapshots, 'balance_snapshots', snapshot.id, snapshot.toJson(), updatedAt);
  }

  Future<void> deleteBalanceSnapshot(String id, {bool tombstone = true}) async {
    await _remove(_balanceSnapshots, 'balance_snapshots', id, tombstone: tombstone);
  }

  List<SavingsGoal> getGoals() {
    return _goals.values
        .map((e) => SavingsGoal.fromJson(jsonDecode(e) as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> saveGoal(SavingsGoal goal, {String? updatedAt}) async {
    await _put(_goals, 'savings_goals', goal.id, goal.toJson(), updatedAt);
  }

  Future<void> deleteGoal(String id, {bool tombstone = true}) async {
    await _remove(_goals, 'savings_goals', id, tombstone: tombstone);
  }

  List<Loan> getLoans() {
    return _loans.values
        .map((e) => Loan.fromJson(jsonDecode(e) as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> saveLoan(Loan loan, {String? updatedAt}) async {
    await _put(_loans, 'loans', loan.id, loan.toJson(), updatedAt);
  }

  Future<void> deleteLoan(String id, {bool tombstone = true}) async {
    await _remove(_loans, 'loans', id, tombstone: tombstone);
  }

  List<RecurringTransaction> getRecurring() {
    return _recurring.values
        .map(
          (e) => RecurringTransaction.fromJson(
            jsonDecode(e) as Map<String, dynamic>,
          ),
        )
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> saveRecurring(RecurringTransaction recurring, {String? updatedAt}) async {
    await _put(_recurring, 'recurring_transactions', recurring.id, recurring.toJson(), updatedAt);
  }

  Future<void> deleteRecurring(String id, {bool tombstone = true}) async {
    await _remove(_recurring, 'recurring_transactions', id, tombstone: tombstone);
  }

  List<ChatMessage> getChatHistory() {
    return _chat.values
        .map((e) => ChatMessage.fromJson(jsonDecode(e) as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  Future<void> saveChatMessage(ChatMessage message, {String? updatedAt}) async {
    await _put(_chat, 'chat_messages', message.id, message.toJson(), updatedAt);
  }

  Future<void> clearChatHistory() async {
    final ids = _chat.keys.map((key) => key.toString()).toList();
    await _chat.clear();
    for (final id in ids) {
      await _rememberTombstone('chat_messages', id);
    }
    _notifyChange();
  }

  List<MonthSummary> getMonthSummaries() {
    return _monthSummaries.values
        .map((e) => MonthSummary.fromJson(jsonDecode(e) as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.id.compareTo(a.id));
  }

  Future<void> saveMonthSummary(MonthSummary summary, {String? updatedAt}) async {
    await _put(
      _monthSummaries,
      'month_summaries',
      summary.id,
      summary.toJson(),
      updatedAt,
    );
  }

  String? get openAiApiKey => aiProviderSettings.openAiApiKey;

  Future<void> setOpenAiApiKey(String? key) async {
    final current = aiProviderSettings;
    await setAiProviderSettings(
      current.copyWith(
        openAiApiKey: key,
        clearOpenAiKey: key == null || key.isEmpty,
        kind: AiProviderKind.openAi,
      ),
    );
  }

  AiProviderSettings get aiProviderSettings {
    final raw = _settings.get('aiProviderSettings') as String?;
    if (raw != null && raw.isNotEmpty) {
      try {
        return AiProviderSettings.fromJson(
          jsonDecode(raw) as Map<String, dynamic>,
        );
      } catch (_) {
        // Fall through to legacy key.
      }
    }
    final legacy = _settings.get('openAiApiKey') as String?;
    if (legacy != null && legacy.isNotEmpty) {
      return AiProviderSettings(openAiApiKey: legacy);
    }
    return const AiProviderSettings();
  }

  Future<void> setAiProviderSettings(AiProviderSettings settings) async {
    await _settings.put(
      'aiProviderSettings',
      jsonEncode(settings.toJson()),
    );
    // Keep legacy key in sync for older code paths.
    if (settings.openAiApiKey == null || settings.openAiApiKey!.isEmpty) {
      await _settings.delete('openAiApiKey');
    } else {
      await _settings.put('openAiApiKey', settings.openAiApiKey);
    }
  }

  String? get gmailAccountEmail =>
      _settings.get('gmailAccountEmail') as String?;

  Future<void> setGmailAccountEmail(String? email) async {
    if (email == null || email.isEmpty) {
      await _settings.delete('gmailAccountEmail');
    } else {
      await _settings.put('gmailAccountEmail', email);
    }
  }

  DateTime? get lastGmailSyncAt {
    final raw = _settings.get('lastGmailSyncAt') as String?;
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  Future<void> setLastGmailSyncAt(DateTime? at) async {
    if (at == null) {
      await _settings.delete('lastGmailSyncAt');
    } else {
      await _settings.put('lastGmailSyncAt', at.toIso8601String());
    }
  }

  String? get outlookAccountEmail =>
      _settings.get('outlookAccountEmail') as String?;

  Future<void> setOutlookAccountEmail(String? email) async {
    if (email == null || email.isEmpty) {
      await _settings.delete('outlookAccountEmail');
    } else {
      await _settings.put('outlookAccountEmail', email);
    }
  }

  DateTime? get lastOutlookSyncAt {
    final raw = _settings.get('lastOutlookSyncAt') as String?;
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  Future<void> setLastOutlookSyncAt(DateTime? at) async {
    if (at == null) {
      await _settings.delete('lastOutlookSyncAt');
    } else {
      await _settings.put('lastOutlookSyncAt', at.toIso8601String());
    }
  }

  String? get outlookAccessToken =>
      _settings.get('outlookAccessToken') as String?;

  String? get outlookRefreshToken =>
      _settings.get('outlookRefreshToken') as String?;

  DateTime? get outlookTokenExpiresAt {
    final raw = _settings.get('outlookTokenExpiresAt') as String?;
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  Future<void> setOutlookTokens({
    String? accessToken,
    String? refreshToken,
    DateTime? expiresAt,
    String? accountEmail,
  }) async {
    if (accessToken == null || accessToken.isEmpty) {
      await _settings.delete('outlookAccessToken');
    } else {
      await _settings.put('outlookAccessToken', accessToken);
    }
    if (refreshToken == null || refreshToken.isEmpty) {
      await _settings.delete('outlookRefreshToken');
    } else {
      await _settings.put('outlookRefreshToken', refreshToken);
    }
    if (expiresAt == null) {
      await _settings.delete('outlookTokenExpiresAt');
    } else {
      await _settings.put('outlookTokenExpiresAt', expiresAt.toIso8601String());
    }
    await setOutlookAccountEmail(accountEmail);
  }

  bool get onboardingCompleted =>
      _settings.get('onboardingCompleted') == true;

  Future<void> setOnboardingCompleted(bool value) async {
    await _settings.put('onboardingCompleted', value);
  }

  String? get localeCode => _settings.get('localeCode') as String?;

  Future<void> setLocaleCode(String code) async {
    await _settings.put('localeCode', code);
  }

  int countTransactionsWithCategory(String categoryId) {
    return getTransactions().where((t) => t.categoryId == categoryId).length;
  }

  int countTransactionsWithAccount(String accountId) {
    return getTransactions().where((t) => t.accountId == accountId).length;
  }

  String? get syncCursor => _settings.get('syncCursor') as String?;

  Future<void> setSyncCursor(String? cursor) async {
    if (cursor == null || cursor.isEmpty) {
      await _settings.delete('syncCursor');
    } else {
      await _settings.put('syncCursor', cursor);
    }
  }

  Future<Map<String, List<Map<String, dynamic>>>> pendingSyncPayload() async {
    final payload = <String, List<Map<String, dynamic>>>{};
    for (final entity in syncEntities) {
      final box = _boxFor(entity);
      final records = <Map<String, dynamic>>[];
      for (final key in box.keys) {
        final record = jsonDecode(box.get(key)!) as Map<String, dynamic>;
        if (record['updatedAt'] == null) {
          record['updatedAt'] = DateTime.now().toUtc().toIso8601String();
          await box.put(key, jsonEncode(record));
        }
        records.add(record);
      }
      final deleted = _tombstones.values
          .map((raw) => jsonDecode(raw) as Map<String, dynamic>)
          .where((row) => row['entity'] == entity)
          .map(
            (row) => {
              'id': row['id'],
              'updatedAt': row['updatedAt'],
              'deleted': true,
            },
          );
      payload[entity] = [...records, ...deleted];
    }
    return payload;
  }

  Future<void> applyRemote(Map<String, dynamic> pull) async {
    _muteChanges = true;
    try {
      for (final entity in syncEntities) {
        final rows = pull[entity];
        if (rows is! List) continue;
        for (final row in rows) {
          if (row is! Map) continue;
          final record = Map<String, dynamic>.from(row);
          final id = record['id'] as String?;
          if (id == null || id.isEmpty) continue;
          final updatedAt = record['updatedAt'] as String?;
          if (record['deletedAt'] != null) {
            await _remove(_boxFor(entity), entity, id, tombstone: false);
            continue;
          }
          record.remove('deletedAt');
          await _putDecoded(_boxFor(entity), entity, id, record, updatedAt);
        }
      }
    } finally {
      _muteChanges = false;
    }
  }

  Future<void> clearPushedTombstones(Map<String, dynamic> pushed) async {
    for (final entity in syncEntities) {
      final rows = pushed[entity];
      if (rows is! List) continue;
      for (final row in rows) {
        if (row is! Map || row['deleted'] != true) continue;
        await _tombstones.delete(_tombstoneKey(entity, row['id'] as String));
      }
    }
  }

  Box<String> _boxFor(String entity) => switch (entity) {
        'accounts' => _accounts,
        'categories' => _categories,
        'transactions' => _transactions,
        'recurring_transactions' => _recurring,
        'savings_goals' => _goals,
        'loans' => _loans,
        'balance_snapshots' => _balanceSnapshots,
        'chat_messages' => _chat,
        'month_summaries' => _monthSummaries,
        _ => throw ArgumentError(entity),
      };

  Future<void> _put(
    Box<String> box,
    String entity,
    String id,
    Map<String, dynamic> json,
    String? updatedAt,
  ) async {
    json['updatedAt'] = updatedAt ?? DateTime.now().toUtc().toIso8601String();
    json.remove('deletedAt');
    await box.put(id, jsonEncode(json));
    await _tombstones.delete(_tombstoneKey(entity, id));
    _notifyChange();
  }

  Future<void> _putDecoded(
    Box<String> box,
    String entity,
    String id,
    Map<String, dynamic> json,
    String? updatedAt,
  ) async {
    await _put(box, entity, id, json, updatedAt);
  }

  Future<void> _remove(
    Box<String> box,
    String entity,
    String id, {
    required bool tombstone,
  }) async {
    await box.delete(id);
    if (tombstone) {
      await _rememberTombstone(entity, id);
    } else {
      await _tombstones.delete(_tombstoneKey(entity, id));
    }
    _notifyChange();
  }

  Future<void> _rememberTombstone(String entity, String id) async {
    await _tombstones.put(
      _tombstoneKey(entity, id),
      jsonEncode({
        'entity': entity,
        'id': id,
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
      }),
    );
  }

  String _tombstoneKey(String entity, String id) => '$entity::$id';

  void _notifyChange() {
    if (_muteChanges) return;
    onLocalChange?.call();
  }
}
