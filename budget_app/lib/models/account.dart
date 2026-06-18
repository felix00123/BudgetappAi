import 'package:flutter/material.dart';

enum AccountType { cash, bank, credit, savings, other }

class Account {
  final String id;
  final String name;
  final AccountType type;
  final double initialBalance;
  final int colorValue;

  Account({
    required this.id,
    required this.name,
    required this.type,
    this.initialBalance = 0,
    required this.colorValue,
  });

  Color get color => Color(colorValue);

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.name,
        'initialBalance': initialBalance,
        'colorValue': colorValue,
      };

  factory Account.fromJson(Map<String, dynamic> json) => Account(
        id: json['id'] as String,
        name: json['name'] as String,
        type: AccountType.values.byName(json['type'] as String),
        initialBalance: (json['initialBalance'] as num?)?.toDouble() ?? 0,
        colorValue: json['colorValue'] as int,
      );

  Account copyWith({
    String? name,
    AccountType? type,
    double? initialBalance,
    int? colorValue,
  }) =>
      Account(
        id: id,
        name: name ?? this.name,
        type: type ?? this.type,
        initialBalance: initialBalance ?? this.initialBalance,
        colorValue: colorValue ?? this.colorValue,
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
  return switch (type) {
    AccountType.cash => 'Cash',
    AccountType.bank => 'Bank',
    AccountType.credit => 'Credit Card',
    AccountType.savings => 'Savings',
    AccountType.other => 'Other',
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
