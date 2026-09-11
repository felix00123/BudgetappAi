import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/account.dart';
import '../models/ai_provider_settings.dart';
import '../models/balance_snapshot.dart';
import '../models/category.dart';
import '../models/chat_message.dart';
import '../models/expense_draft.dart';
import '../models/import_row.dart';
import '../models/loan.dart';
import '../models/parsed_bank_email.dart';
import '../models/recurring_transaction.dart';
import '../models/savings_goal.dart';
import '../models/transaction.dart';
import '../services/ai_advisor_service.dart';
import '../services/ai_capture_service.dart';
import '../services/bank_email_parser.dart';
import '../services/excel_service.dart';
import '../services/gmail_sync_service.dart';
import '../services/home_widget_service.dart';
import '../services/outlook_sync_service.dart';
import '../services/storage_service.dart';
import '../utils/formatters.dart';

/// Kept for call sites that still reference the Gmail-named type.
typedef GmailImportSummary = EmailImportSummary;

class BudgetProvider extends ChangeNotifier {
  BudgetProvider(this._storage);

  final StorageService _storage;
  final ExcelService _excelService = ExcelService();
  final AiAdvisorService _aiService = AiAdvisorService();
  final AiCaptureService _aiCapture = AiCaptureService();
  final _uuid = const Uuid();

  List<Transaction> _transactions = [];
  List<SavingsGoal> _goals = [];
  List<Loan> _loans = [];
  List<RecurringTransaction> _recurring = [];
  List<ChatMessage> _chatMessages = [];
  List<BudgetCategory> _categories = [];
  List<Account> _accounts = [];
  List<BalanceSnapshot> _balanceSnapshots = [];
  bool _isLoading = true;
  bool _isAiThinking = false;
  AiProviderSettings _aiSettings = const AiProviderSettings();
  String? _gmailAccountEmail;
  DateTime? _lastGmailSyncAt;
  String? _outlookAccountEmail;
  DateTime? _lastOutlookSyncAt;
  final GmailSyncService _gmailSync = GmailSyncService();
  late final OutlookSyncService _outlookSync = OutlookSyncService(
    readTokens: () async => OutlookTokenStore(
      accessToken: _storage.outlookAccessToken,
      refreshToken: _storage.outlookRefreshToken,
      expiresAt: _storage.outlookTokenExpiresAt,
      accountEmail: _storage.outlookAccountEmail,
    ),
    writeTokens: (tokens) async {
      await _storage.setOutlookTokens(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
        expiresAt: tokens.expiresAt,
        accountEmail: tokens.accountEmail,
      );
      _outlookAccountEmail = tokens.accountEmail;
      notifyListeners();
    },
  );

  List<Transaction> get transactions => _transactions;
  List<SavingsGoal> get goals => _goals;
  List<Loan> get loans => _loans;
  List<Loan> get activeLoans =>
      _loans.where((l) => !l.isPaidOff).toList();
  List<Loan> get paidOffLoans => _loans.where((l) => l.isPaidOff).toList();
  List<RecurringTransaction> get recurring => _recurring;
  List<RecurringTransaction> get activeRecurring =>
      _recurring.where((r) => r.isActive).toList();
  List<ChatMessage> get chatMessages => _chatMessages;
  List<BudgetCategory> get categories => _categories;
  List<Account> get accounts => _accounts;
  List<BalanceSnapshot> get balanceSnapshots => _balanceSnapshots;
  bool get isLoading => _isLoading;
  bool get isAiThinking => _isAiThinking;
  AiProviderSettings get aiSettings => _aiSettings;
  String? get openAiApiKey => _aiSettings.openAiApiKey;
  bool get isAiConfigured => _aiSettings.isConfigured;
  String get aiSetupHint => _aiSettings.setupHint;
  String? get gmailAccountEmail => _gmailAccountEmail;
  DateTime? get lastGmailSyncAt => _lastGmailSyncAt;
  GmailSyncService get gmailSync => _gmailSync;
  bool get isGmailConnected =>
      _gmailAccountEmail != null && _gmailAccountEmail!.isNotEmpty;

  String? get outlookAccountEmail => _outlookAccountEmail;
  DateTime? get lastOutlookSyncAt => _lastOutlookSyncAt;
  OutlookSyncService get outlookSync => _outlookSync;
  bool get isOutlookConnected =>
      _outlookAccountEmail != null && _outlookAccountEmail!.isNotEmpty;

  Account? get defaultAccount =>
      _accounts.isNotEmpty ? _accounts.first : null;

  double get totalIncome => _transactions
      .where((t) => t.type == TransactionType.income)
      .fold(0.0, (sum, t) => sum + t.amount);

  double get totalExpenses => _transactions
      .where((t) => t.type == TransactionType.expense)
      .fold(0.0, (sum, t) => sum + t.amount);

  double get balance => totalIncome - totalExpenses;

  double get monthlyIncome => _monthlyTotal(TransactionType.income);
  double get monthlyExpenses => _monthlyTotal(TransactionType.expense);
  double get monthlySavings => monthlyIncome - monthlyExpenses;

  double get totalMonthlyDebtService => activeLoans.fold(
        0.0,
        (sum, loan) => sum + loan.totalMonthlyPayment,
      );

  double get totalRemainingDebt =>
      activeLoans.fold(0.0, (sum, loan) => sum + loan.remainingBalance);

  double get expectedMonthlyRecurringIncome => _expectedMonthlyRecurring(
        TransactionType.income,
      );

  double get expectedMonthlyRecurringExpenses => _expectedMonthlyRecurring(
        TransactionType.expense,
      );

  List<Transaction> get recentTransactions => _transactions.take(5).toList();

  Map<String, double> get expensesByCategory {
    final map = <String, double>{};
    for (final t in _transactions.where((t) => t.type == TransactionType.expense)) {
      final name = categoryName(t.categoryId);
      map[name] = (map[name] ?? 0) + t.amount;
    }
    return map;
  }

  /// Days with any transaction logged (yyyy-MM-dd keys).
  Map<String, int> get dailyActivityCounts => _countByDay(_transactions);

  Map<String, int> get dailyIncomeCounts =>
      _countByDay(_transactions.where((t) => t.type == TransactionType.income));

  Map<String, int> get dailyExpenseCounts =>
      _countByDay(_transactions.where((t) => t.type == TransactionType.expense));

  bool get loggedToday =>
      (dailyActivityCounts[dateKey(DateTime.now())] ?? 0) > 0;

  bool get loggedIncomeToday =>
      (dailyIncomeCounts[dateKey(DateTime.now())] ?? 0) > 0;

  bool get loggedExpenseToday =>
      (dailyExpenseCounts[dateKey(DateTime.now())] ?? 0) > 0;

  Map<String, int> _countByDay(Iterable<Transaction> items) {
    final map = <String, int>{};
    for (final t in items) {
      final key = dateKey(t.date);
      map[key] = (map[key] ?? 0) + 1;
    }
    return map;
  }

  List<BudgetCategory> categoriesForType(TransactionType type) =>
      _categories.where((c) => c.type == type).toList();

  BudgetCategory? categoryById(String id) {
    for (final c in _categories) {
      if (c.id == id) return c;
    }
    return null;
  }

  Account? accountById(String id) {
    for (final a in _accounts) {
      if (a.id == id) return a;
    }
    return null;
  }

  Account? accountByLastFour(String lastFour) {
    for (final a in _accounts) {
      if (a.lastFour == lastFour) return a;
    }
    return null;
  }

  /// Bank-reported balances for an account, oldest first.
  List<BalanceSnapshot> snapshotsForAccount(String accountId) =>
      _balanceSnapshots.where((s) => s.accountId == accountId).toList();

  BalanceSnapshot? latestSnapshot(String accountId) {
    BalanceSnapshot? latest;
    for (final s in _balanceSnapshots) {
      if (s.accountId != accountId) continue;
      if (latest == null || s.capturedAt.isAfter(latest.capturedAt)) latest = s;
    }
    return latest;
  }

  /// Accounts that have at least one bank-reported balance.
  List<Account> get accountsWithSnapshots => _accounts
      .where((a) => _balanceSnapshots.any((s) => s.accountId == a.id))
      .toList();

  String categoryName(String categoryId) =>
      categoryById(categoryId)?.name ?? 'Unknown';

  String accountName(String accountId) =>
      accountById(accountId)?.name ?? 'Unknown';

  double accountBalance(String accountId) {
    final account = accountById(accountId);
    if (account == null) return 0;

    var balance = account.initialBalance;
    for (final t in _transactions.where((t) => t.accountId == accountId)) {
      if (t.type == TransactionType.income) {
        balance += t.amount;
      } else {
        balance -= t.amount;
      }
    }
    return balance;
  }

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();
    _transactions = _storage.getTransactions();
    _goals = _storage.getGoals();
    _loans = _storage.getLoans();
    _recurring = _storage.getRecurring();
    _chatMessages = _storage.getChatHistory();
    _categories = _storage.getCategories();
    _accounts = _storage.getAccounts();
    _balanceSnapshots = _storage.getBalanceSnapshots();
    _aiSettings = _storage.aiProviderSettings;
    _gmailAccountEmail = _storage.gmailAccountEmail;
    _lastGmailSyncAt = _storage.lastGmailSyncAt;
    _outlookAccountEmail = _storage.outlookAccountEmail;
    _lastOutlookSyncAt = _storage.lastOutlookSyncAt;
    await _processDueRecurring();
    _isLoading = false;
    notifyListeners();
    await _syncHomeWidgets();
    // Restore Google session in the background; UI reads stored email meantime.
    unawaited(_restoreGmailSession());
  }

  Future<void> _restoreGmailSession() async {
    try {
      await _gmailSync.ensureInitialized();
      final email = await _gmailSync.connectedEmail();
      if (email != null && email != _gmailAccountEmail) {
        _gmailAccountEmail = email;
        await _storage.setGmailAccountEmail(email);
        notifyListeners();
      } else if (email == null && _gmailAccountEmail != null) {
        // Stored email but no Google session — keep the label until reconnect.
      }
    } catch (_) {
      // Sign-in restore is best-effort.
    }
  }

  Future<void> _syncHomeWidgets() async {
    await HomeWidgetService.sync(goals: _goals, loans: _loans);
  }

  Future<void> addTransaction(Transaction transaction) async {
    await _storage.saveTransaction(transaction);
    _transactions = _storage.getTransactions();
    notifyListeners();
  }

  Future<ExpenseDraft> draftFromReceipt(
    Uint8List bytes, {
    String mimeType = 'image/jpeg',
  }) async {
    if (!_aiSettings.isConfigured) {
      throw AiCaptureException(_aiSettings.setupHint);
    }
    return _aiCapture.extractFromReceipt(
      imageBytes: bytes,
      mimeType: mimeType,
      categories: _categories,
      accounts: _accounts,
      settings: _aiSettings,
    );
  }

  Future<ExpenseDraft> draftFromVoiceTranscript(String transcript) async {
    if (!_aiSettings.isConfigured) {
      throw AiCaptureException(_aiSettings.setupHint);
    }
    return _aiCapture.extractFromUtterance(
      transcript: transcript,
      categories: _categories,
      accounts: _accounts,
      settings: _aiSettings,
    );
  }

  Future<void> saveExpenseDraft(ExpenseDraft draft) async {
    final categoryId = draft.categoryId ??
        (draft.type == TransactionType.income
            ? 'cat_income_other'
            : 'cat_expense_other');
    final accountId = draft.accountId ?? defaultAccount?.id;
    if (accountId == null) {
      throw const AiCaptureException(
        'Create an account before saving an AI expense.',
      );
    }

    final kindLabel = draft.captureKind == 'voice' ? 'Voice' : 'Receipt';
    await addTransaction(
      Transaction(
        id: _uuid.v4(),
        title: draft.title,
        amount: draft.amount,
        type: draft.type,
        categoryId: categoryId,
        accountId: accountId,
        date: draft.date,
        note: draft.note ?? 'Captured via AI ($kindLabel)',
        source: TransactionSource.ai,
      ),
    );
  }

  Future<void> updateTransaction(Transaction transaction) async {
    await _storage.saveTransaction(transaction);
    _transactions = _storage.getTransactions();
    notifyListeners();
  }

  Future<void> deleteTransaction(String id) async {
    await _storage.deleteTransaction(id);
    _transactions = _storage.getTransactions();
    notifyListeners();
  }

  Future<void> addCategory(BudgetCategory category) async {
    await _storage.saveCategory(category);
    _categories = _storage.getCategories();
    notifyListeners();
  }

  Future<void> updateCategory(BudgetCategory category) async {
    await _storage.saveCategory(category);
    _categories = _storage.getCategories();
    notifyListeners();
  }

  Future<String?> deleteCategory(String id) async {
    if (_categories.length <= 1) {
      return 'You need at least one category';
    }
    final count = _storage.countTransactionsWithCategory(id);
    if (count > 0) {
      return 'Category is used in $count transaction${count == 1 ? '' : 's'}';
    }
    await _storage.deleteCategory(id);
    _categories = _storage.getCategories();
    notifyListeners();
    return null;
  }

  Future<void> addAccount(Account account) async {
    await _storage.saveAccount(account);
    _accounts = _storage.getAccounts();
    notifyListeners();
  }

  Future<void> updateAccount(Account account) async {
    await _storage.saveAccount(account);
    _accounts = _storage.getAccounts();
    notifyListeners();
  }

  Future<String?> deleteAccount(String id) async {
    if (_accounts.length <= 1) {
      return 'You need at least one account';
    }
    final count = _storage.countTransactionsWithAccount(id);
    if (count > 0) {
      return 'Account is used in $count transaction${count == 1 ? '' : 's'}';
    }
    await _storage.deleteAccount(id);
    _accounts = _storage.getAccounts();
    notifyListeners();
    return null;
  }

  Future<void> addGoal(SavingsGoal goal) async {
    await _storage.saveGoal(goal);
    _goals = _storage.getGoals();
    notifyListeners();
    await _syncHomeWidgets();
  }

  Future<void> updateGoal(SavingsGoal goal) async {
    await _storage.saveGoal(goal);
    _goals = _storage.getGoals();
    notifyListeners();
    await _syncHomeWidgets();
  }

  Future<void> deleteGoal(String id) async {
    await _storage.deleteGoal(id);
    _goals = _storage.getGoals();
    notifyListeners();
    await _syncHomeWidgets();
  }

  Future<void> addToGoal(String goalId, double amount) async {
    final goal = _goals.firstWhere((g) => g.id == goalId);
    await updateGoal(goal.copyWith(currentSaved: goal.currentSaved + amount));
  }

  Future<void> addLoan(Loan loan) async {
    await _storage.saveLoan(loan);
    _loans = _storage.getLoans();
    notifyListeners();
    await _syncHomeWidgets();
  }

  Future<void> updateLoan(Loan loan) async {
    await _storage.saveLoan(loan);
    _loans = _storage.getLoans();
    notifyListeners();
    await _syncHomeWidgets();
  }

  Future<void> deleteLoan(String id) async {
    await _storage.deleteLoan(id);
    _loans = _storage.getLoans();
    notifyListeners();
    await _syncHomeWidgets();
  }

  Future<void> recordLoanPayment(String loanId, double amount) async {
    final loan = _loans.firstWhere((l) => l.id == loanId);
    await updateLoan(applyPayment(loan, amount));
  }

  Future<void> addRecurring(RecurringTransaction recurring) async {
    await _storage.saveRecurring(recurring);
    _recurring = _storage.getRecurring();
    notifyListeners();
    await _processDueRecurring();
  }

  Future<void> updateRecurring(RecurringTransaction recurring) async {
    await _storage.saveRecurring(recurring);
    _recurring = _storage.getRecurring();
    notifyListeners();
    await _processDueRecurring();
  }

  Future<void> deleteRecurring(String id) async {
    await _storage.deleteRecurring(id);
    _recurring = _storage.getRecurring();
    notifyListeners();
  }

  Future<void> setRecurringActive(String id, bool isActive) async {
    final item = _recurring.firstWhere((r) => r.id == id);
    await updateRecurring(item.copyWith(isActive: isActive));
  }

  Future<int> _processDueRecurring() async {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    var created = 0;

    for (final item in List<RecurringTransaction>.from(_recurring)) {
      if (!item.isActive) continue;

      var nextDue = item.lastGeneratedDate == null
          ? item.firstDueOnOrAfter(item.startDate)
          : item.nextDueAfter(item.lastGeneratedDate!);
      var lastGenerated = item.lastGeneratedDate;

      while (nextDue != null && !nextDue.isAfter(todayDate)) {
        if (item.endDate != null &&
            nextDue.isAfter(
              DateTime(
                item.endDate!.year,
                item.endDate!.month,
                item.endDate!.day,
              ),
            )) {
          break;
        }

        final transaction = Transaction(
          id: _uuid.v4(),
          title: item.title,
          amount: item.amount,
          type: item.type,
          categoryId: item.categoryId,
          accountId: item.accountId,
          date: nextDue,
          note: _recurringNote(item, nextDue),
        );
        await _storage.saveTransaction(transaction);
        lastGenerated = nextDue;
        created++;
        nextDue = item.nextDueAfter(nextDue);
      }

      if (lastGenerated != item.lastGeneratedDate) {
        await _storage.saveRecurring(
          item.copyWith(lastGeneratedDate: lastGenerated),
        );
      }
    }

    if (created > 0) {
      _transactions = _storage.getTransactions();
      _recurring = _storage.getRecurring();
      notifyListeners();
    }

    return created;
  }

  String? _recurringNote(RecurringTransaction item, DateTime dueDate) {
    final base = item.note;
    final marker = 'Auto: recurring';
    if (base == null || base.isEmpty) return marker;
    return '$base ($marker)';
  }

  double _expectedMonthlyRecurring(TransactionType type) {
    return activeRecurring
        .where((r) => r.type == type)
        .fold(0.0, (sum, r) => sum + _monthlyEquivalent(r));
  }

  double _monthlyEquivalent(RecurringTransaction recurring) {
    switch (recurring.frequency) {
      case RecurrenceFrequency.monthly:
        return recurring.amount;
      case RecurrenceFrequency.weekly:
        return recurring.amount * 52 / 12;
      case RecurrenceFrequency.yearly:
        return recurring.amount / 12;
    }
  }

  List<Transaction> getTransactionsForMonth(DateTime month) {
    return _transactions.where((t) {
      return t.date.year == month.year && t.date.month == month.month;
    }).toList();
  }

  List<Transaction> filterTransactions({
    TransactionType? type,
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
    String? accountId,
  }) {
    return _transactions.where((t) {
      if (type != null && t.type != type) return false;
      if (categoryId != null && t.categoryId != categoryId) return false;
      if (accountId != null && t.accountId != accountId) return false;
      if (startDate != null && t.date.isBefore(startDate)) return false;
      if (endDate != null && t.date.isAfter(endDate)) return false;
      return true;
    }).toList();
  }

  Future<String> exportToExcel({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return _excelService.exportTransactions(
      transactions: _transactions,
      categories: _categories,
      accounts: _accounts,
      startDate: startDate,
      endDate: endDate,
    );
  }

  Future<void> shareExportedFile(String path) async {
    await _excelService.shareFile(path);
  }

  Future<String> generateImportTemplate() async {
    return _excelService.generateImportTemplate(
      categories: _categories,
      accounts: _accounts,
    );
  }

  ImportResult previewImport({required List<int> bytes, required String fileName}) {
    return _excelService.parseImportFile(
      bytes: bytes,
      fileName: fileName,
      categories: _categories,
      accounts: _accounts,
    );
  }

  Future<int> importTransactions(List<Transaction> transactions) async {
    for (final t in transactions) {
      await _storage.saveTransaction(t);
    }
    _transactions = _storage.getTransactions();
    notifyListeners();
    return transactions.length;
  }

  Future<void> addBalanceSnapshot(BalanceSnapshot snapshot) async {
    await _storage.saveBalanceSnapshot(snapshot);
    _balanceSnapshots = _storage.getBalanceSnapshots();
    notifyListeners();
  }

  Future<void> deleteBalanceSnapshot(String id) async {
    await _storage.deleteBalanceSnapshot(id);
    _balanceSnapshots = _storage.getBalanceSnapshots();
    notifyListeners();
  }

  /// True when an external id was already imported, so it is not stored twice.
  bool hasExternalId(String externalId) =>
      _transactions.any((t) => t.externalId == externalId) ||
      _balanceSnapshots.any((s) => s.externalId == externalId);

  Future<String> connectGmail() async {
    final email = await _gmailSync.connect();
    _gmailAccountEmail = email;
    await _storage.setGmailAccountEmail(email);
    notifyListeners();
    return email;
  }

  Future<void> disconnectGmail() async {
    await _gmailSync.disconnect();
    _gmailAccountEmail = null;
    await _storage.setGmailAccountEmail(null);
    notifyListeners();
  }

  /// Fetches bank alerts from Gmail and imports new transactions / balances.
  Future<EmailImportSummary> syncGmail({
    DateTime? since,
    DateTime? until,
    bool createMissingAccounts = true,
  }) async {
    final lookbackSince = since ??
        (_lastGmailSyncAt?.subtract(const Duration(days: 3)) ??
            DateTime.now().subtract(const Duration(days: 30)));

    final fetch = await _gmailSync.syncBankEmails(
      since: lookbackSince,
      until: until,
    );

    if (fetch.accountEmail != null) {
      _gmailAccountEmail = fetch.accountEmail;
      await _storage.setGmailAccountEmail(fetch.accountEmail);
    }

    final summary = await importParsedBankEmails(
      fetch.emails,
      messagesChecked: fetch.messagesChecked,
      createMissingAccounts: createMissingAccounts,
    );

    _lastGmailSyncAt = DateTime.now();
    await _storage.setLastGmailSyncAt(_lastGmailSyncAt);
    notifyListeners();
    return summary;
  }

  Future<String> connectOutlook() async {
    final email = await _outlookSync.connect();
    _outlookAccountEmail = email;
    notifyListeners();
    return email;
  }

  Future<void> disconnectOutlook() async {
    await _outlookSync.disconnect();
    _outlookAccountEmail = null;
    _lastOutlookSyncAt = null;
    await _storage.setLastOutlookSyncAt(null);
    notifyListeners();
  }

  Future<EmailImportSummary> syncOutlook({
    DateTime? since,
    DateTime? until,
    bool createMissingAccounts = true,
  }) async {
    final lookbackSince = since ??
        (_lastOutlookSyncAt?.subtract(const Duration(days: 3)) ??
            DateTime.now().subtract(const Duration(days: 30)));

    final fetch = await _outlookSync.syncBankEmails(
      since: lookbackSince,
      until: until,
    );

    if (fetch.accountEmail != null) {
      _outlookAccountEmail = fetch.accountEmail;
      await _storage.setOutlookAccountEmail(fetch.accountEmail);
    }

    final summary = await importParsedBankEmails(
      fetch.emails,
      messagesChecked: fetch.messagesChecked,
      createMissingAccounts: createMissingAccounts,
    );

    _lastOutlookSyncAt = DateTime.now();
    await _storage.setLastOutlookSyncAt(_lastOutlookSyncAt);
    notifyListeners();
    return summary;
  }

  /// Shared import path for Gmail and Outlook parsed bank alerts.
  Future<EmailImportSummary> importParsedBankEmails(
    List<ParsedBankEmail> emails, {
    required int messagesChecked,
    bool createMissingAccounts = true,
  }) async {
    var transactionsSaved = 0;
    var balancesSaved = 0;
    var accountsCreated = 0;
    final pendingTransactions = <Transaction>[];
    final seenExternalIds = <String>{
      for (final t in _transactions)
        if (t.externalId != null) t.externalId!,
      for (final s in _balanceSnapshots)
        if (s.externalId != null) s.externalId!,
    };

    for (final email in emails) {
      final result = email.result;
      final lastFour = result.lastFour;
      if (lastFour == null) continue;

      var account = accountByLastFour(lastFour);
      if (account == null) {
        if (!createMissingAccounts) continue;
        account = _accountFromBankResult(result, lastFour);
        await _storage.saveAccount(account);
        _accounts = [..._accounts, account];
        accountsCreated++;
      }

      for (final t in result.transactions) {
        if (seenExternalIds.contains(t.fingerprint)) continue;
        seenExternalIds.add(t.fingerprint);
        pendingTransactions.add(
          Transaction(
            id: _uuid.v4(),
            title: t.merchant,
            amount: t.amount,
            type: t.transactionType,
            categoryId: t.categoryId,
            accountId: account.id,
            date: t.date,
            note:
                '${t.bank} ••${t.lastFour} · ${bankTransactionKindLabel(t.kind)}',
            source: TransactionSource.email,
            externalId: t.fingerprint,
          ),
        );
      }

      final balance = result.balance;
      if (balance != null) {
        final externalId =
            '${result.bank}|$lastFour|${balance.label}|${balance.amount}';
        if (!seenExternalIds.contains(externalId)) {
          seenExternalIds.add(externalId);
          await _storage.saveBalanceSnapshot(
            BalanceSnapshot(
              id: _uuid.v4(),
              accountId: account.id,
              balance: balance.amount,
              currency: balance.currency,
              label: balance.label,
              capturedAt: balance.capturedAt,
              externalId: externalId,
            ),
          );
          balancesSaved++;
        }
      }
    }

    if (pendingTransactions.isNotEmpty) {
      for (final t in pendingTransactions) {
        await _storage.saveTransaction(t);
      }
      transactionsSaved = pendingTransactions.length;
    }

    if (accountsCreated > 0 ||
        transactionsSaved > 0 ||
        balancesSaved > 0) {
      _accounts = _storage.getAccounts();
      _transactions = _storage.getTransactions();
      _balanceSnapshots = _storage.getBalanceSnapshots();
      notifyListeners();
    }

    final parts = <String>[];
    if (transactionsSaved > 0) {
      parts.add(
        '$transactionsSaved transaction${transactionsSaved == 1 ? '' : 's'}',
      );
    }
    if (balancesSaved > 0) {
      parts.add('$balancesSaved balance${balancesSaved == 1 ? '' : 's'}');
    }
    if (accountsCreated > 0) {
      parts.add(
        '$accountsCreated account${accountsCreated == 1 ? '' : 's'} created',
      );
    }

    return EmailImportSummary(
      messagesChecked: messagesChecked,
      emailsParsed: emails.length,
      transactionsSaved: transactionsSaved,
      balancesSaved: balancesSaved,
      accountsCreated: accountsCreated,
      message: parts.isEmpty
          ? 'Checked $messagesChecked emails. Nothing new to import.'
          : 'Imported ${parts.join(', ')} from ${emails.length} emails.',
    );
  }

  Account _accountFromBankResult(BankEmailResult result, String lastFour) {
    final isCredit = result.accountKind == BankAccountKind.credit;
    return Account(
      id: 'acc_${result.bank.toLowerCase()}_$lastFour',
      name: '${result.bank} ${isCredit ? 'Credit' : 'Debit'} ••$lastFour',
      type: accountTypeFor(result.accountKind),
      colorValue: accountColorOptions[
          lastFour.hashCode.abs() % accountColorOptions.length],
      bank: result.bank,
      lastFour: lastFour,
    );
  }

  Future<void> sendChatMessage(String content) async {
    if (content.trim().isEmpty) return;

    final userMsg = ChatMessage(
      id: _uuid.v4(),
      content: content.trim(),
      role: MessageRole.user,
      timestamp: DateTime.now(),
    );
    await _storage.saveChatMessage(userMsg);
    _chatMessages = _storage.getChatHistory();
    _isAiThinking = true;
    notifyListeners();

    try {
      final financialContext = _aiService.buildContext(
        transactions: _transactions,
        goals: _goals,
        loans: _loans,
        categories: _categories,
        accounts: _accounts,
        monthlyIncome: monthlyIncome,
        monthlyExpenses: monthlyExpenses,
        monthlySavings: monthlySavings,
        accountBalance: accountBalance,
      );

      final response = await _aiService.getAdvice(
        userMessage: content,
        context: financialContext,
        goals: _goals,
        categories: _categories,
        transactions: _transactions,
        aiSettings: _aiSettings,
      );

      final assistantMsg = ChatMessage(
        id: _uuid.v4(),
        content: response,
        role: MessageRole.assistant,
        timestamp: DateTime.now(),
      );
      await _storage.saveChatMessage(assistantMsg);
      _chatMessages = _storage.getChatHistory();
    } finally {
      _isAiThinking = false;
      notifyListeners();
    }
  }

  Future<void> clearChat() async {
    await _storage.clearChatHistory();
    _chatMessages = [];
    notifyListeners();
  }

  Future<void> setOpenAiApiKey(String? key) async {
    await _storage.setOpenAiApiKey(key);
    _aiSettings = _storage.aiProviderSettings;
    notifyListeners();
  }

  Future<void> setAiSettings(AiProviderSettings settings) async {
    await _storage.setAiProviderSettings(settings);
    _aiSettings = settings;
    notifyListeners();
  }

  double _monthlyTotal(TransactionType type) {
    final now = DateTime.now();
    return _transactions
        .where((t) =>
            t.type == type &&
            t.date.year == now.year &&
            t.date.month == now.month)
        .fold(0.0, (sum, t) => sum + t.amount);
  }
}
