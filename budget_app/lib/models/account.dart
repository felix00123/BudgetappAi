import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum AccountType { cash, bank, credit, savings, other }

class Account {
  final String id;
  final String name;
  final AccountType type;
  final double initialBalance;
  final int colorValue;

  /// Issuer shown on bank alert emails, e.g. BHD or Banco Santa Cruz.
  final String? bank;

  /// Last four digits used to match bank alert emails to this account.
  final String? lastFour;

  /// Payment due date from a card screenshot (fecha de vencimiento).
  final DateTime? dueDate;

  /// Statement cutoff date from a card screenshot (fecha de corte).
  final DateTime? cutoffDate;

  Account({
    required this.id,
    required this.name,
    required this.type,
    this.initialBalance = 0,
    required this.colorValue,
    this.bank,
    this.lastFour,
    this.dueDate,
    this.cutoffDate,
  });

  Color get color => Color(colorValue);

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.name,
        'initialBalance': initialBalance,
        'colorValue': colorValue,
        'bank': bank,
        'lastFour': lastFour,
        'dueDate': dueDate?.toIso8601String(),
        'cutoffDate': cutoffDate?.toIso8601String(),
      };

  factory Account.fromJson(Map<String, dynamic> json) => Account(
        id: json['id'] as String,
        name: json['name'] as String,
        type: AccountType.values.byName(json['type'] as String),
        initialBalance: (json['initialBalance'] as num?)?.toDouble() ?? 0,
        colorValue: json['colorValue'] as int,
        bank: json['bank'] as String?,
        lastFour: json['lastFour'] as String?,
        dueDate: DateTime.tryParse(json['dueDate'] as String? ?? ''),
        cutoffDate: DateTime.tryParse(json['cutoffDate'] as String? ?? ''),
      );

  Account copyWith({
    String? name,
    AccountType? type,
    double? initialBalance,
    int? colorValue,
    String? bank,
    String? lastFour,
    DateTime? dueDate,
    DateTime? cutoffDate,
  }) =>
      Account(
        id: id,
        name: name ?? this.name,
        type: type ?? this.type,
        initialBalance: initialBalance ?? this.initialBalance,
        colorValue: colorValue ?? this.colorValue,
        bank: bank ?? this.bank,
        lastFour: lastFour ?? this.lastFour,
        dueDate: dueDate ?? this.dueDate,
        cutoffDate: cutoffDate ?? this.cutoffDate,
      );
}

IconData accountTypeIcon(AccountType type) {
  return switch (type) {
    AccountType.cash => Icons.payments_rounded,
    AccountType.bank => Icons.account_balance_rounded,
    AccountType.credit => Icons.credit_card_rounded,
    AccountType.savings => Icons.savings_rounded,
    AccountType.other => Icons.wallet_rounded,
  };
}

String accountTypeLabel(AccountType type) {
  final es = (Intl.defaultLocale ?? 'en').toLowerCase().startsWith('es');
  return switch (type) {
    AccountType.cash => es ? 'Efectivo' : 'Cash',
    AccountType.bank => es ? 'Banco' : 'Bank',
    AccountType.credit => es ? 'Tarjeta de crédito' : 'Credit Card',
    AccountType.savings => es ? 'Ahorros' : 'Savings',
    AccountType.other => es ? 'Otro' : 'Other',
  };
}

const accountColorOptions = [
  0xFF6366F1,
  0xFF22C55E,
  0xFF3B82F6,
  0xFFF59E0B,
  0xFFEF4444,
  0xFF8B5CF6,
  0xFF14B8A6,
  0xFFEC4899,
];

List<Account> defaultAccounts() => [
      Account(
        id: 'acc_cash',
        name: 'Cash',
        type: AccountType.cash,
        colorValue: 0xFF22C55E,
      ),
      Account(
        id: 'acc_bank',
        name: 'Bank Account',
        type: AccountType.bank,
        initialBalance: 0,
        colorValue: 0xFF6366F1,
      ),
    ];
