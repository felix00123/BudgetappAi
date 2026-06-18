import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../models/account.dart';
import '../models/category.dart';
import '../models/chat_message.dart';
import '../models/loan.dart';
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

  late Box<String> _transactions;
  late Box<String> _goals;
  late Box<String> _loans;
  late Box<String> _recurring;
  late Box<String> _chat;
  late Box _settings;
  late Box<String> _categories;
  late Box<String> _accounts;

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

  Future<void> saveTransaction(Transaction transaction) async {
    await _transactions.put(transaction.id, jsonEncode(transaction.toJson()));
  }

  Future<void> deleteTransaction(String id) async {
    await _transactions.delete(id);
  }

  List<BudgetCategory> getCategories() {
    return _categories.values
        .map((e) => BudgetCategory.fromJson(jsonDecode(e) as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  Future<void> saveCategory(BudgetCategory category) async {
    await _categories.put(category.id, jsonEncode(category.toJson()));
  }

  Future<void> deleteCategory(String id) async {
    await _categories.delete(id);
  }

  List<Account> getAccounts() {
    return _accounts.values
        .map((e) => Account.fromJson(jsonDecode(e) as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  Future<void> saveAccount(Account account) async {
    await _accounts.put(account.id, jsonEncode(account.toJson()));
  }

  Future<void> deleteAccount(String id) async {
    await _accounts.delete(id);
  }

  List<SavingsGoal> getGoals() {
    return _goals.values
        .map((e) => SavingsGoal.fromJson(jsonDecode(e) as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> saveGoal(SavingsGoal goal) async {
    await _goals.put(goal.id, jsonEncode(goal.toJson()));
  }

  Future<void> deleteGoal(String id) async {
    await _goals.delete(id);
  }

  List<Loan> getLoans() {
    return _loans.values
        .map((e) => Loan.fromJson(jsonDecode(e) as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> saveLoan(Loan loan) async {
    await _loans.put(loan.id, jsonEncode(loan.toJson()));
  }

  Future<void> deleteLoan(String id) async {
    await _loans.delete(id);
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

  Future<void> saveRecurring(RecurringTransaction recurring) async {
    await _recurring.put(recurring.id, jsonEncode(recurring.toJson()));
  }

  Future<void> deleteRecurring(String id) async {
    await _recurring.delete(id);
  }

  List<ChatMessage> getChatHistory() {
    return _chat.values
        .map((e) => ChatMessage.fromJson(jsonDecode(e) as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  Future<void> saveChatMessage(ChatMessage message) async {
    await _chat.put(message.id, jsonEncode(message.toJson()));
  }

  Future<void> clearChatHistory() async {
    await _chat.clear();
  }

  String? get openAiApiKey => _settings.get('openAiApiKey') as String?;

  Future<void> setOpenAiApiKey(String? key) async {
    if (key == null || key.isEmpty) {
      await _settings.delete('openAiApiKey');
    } else {
      await _settings.put('openAiApiKey', key);
    }
  }

  int countTransactionsWithCategory(String categoryId) {
    return getTransactions().where((t) => t.categoryId == categoryId).length;
  }

  int countTransactionsWithAccount(String accountId) {
    return getTransactions().where((t) => t.accountId == accountId).length;
  }
}
