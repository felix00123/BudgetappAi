import 'package:flutter/material.dart';

import 'transaction.dart';

class BudgetCategory {
  final String id;
  final String name;
  final TransactionType type;
  final String icon;
  final int colorValue;

  BudgetCategory({
    required this.id,
    required this.name,
    required this.type,
    required this.icon,
    required this.colorValue,
  });

  Color get color => Color(colorValue);

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.name,
        'icon': icon,
        'colorValue': colorValue,
      };

  factory BudgetCategory.fromJson(Map<String, dynamic> json) => BudgetCategory(
        id: json['id'] as String,
        name: json['name'] as String,
        type: TransactionType.values.byName(json['type'] as String),
        icon: json['icon'] as String,
        colorValue: json['colorValue'] as int,
      );

  BudgetCategory copyWith({
    String? name,
    TransactionType? type,
    String? icon,
    int? colorValue,
  }) =>
      BudgetCategory(
        id: id,
        name: name ?? this.name,
        type: type ?? this.type,
        icon: icon ?? this.icon,
        colorValue: colorValue ?? this.colorValue,
      );
}

const categoryIconOptions = [
  'restaurant',
  'directions_car',
  'home',
  'movie',
  'favorite',
  'shopping_bag',
  'receipt_long',
  'school',
  'work',
  'laptop_mac',
  'trending_up',
  'card_giftcard',
  'account_balance_wallet',
  'local_gas_station',
  'fitness_center',
  'pets',
  'child_care',
  'flight',
  'phone',
  'wifi',
];

IconData categoryIconData(String iconName) {
  return switch (iconName) {
    'restaurant' => Icons.restaurant_rounded,
    'directions_car' => Icons.directions_car_rounded,
    'home' => Icons.home_rounded,
    'movie' => Icons.movie_rounded,
    'favorite' => Icons.favorite_rounded,
    'shopping_bag' => Icons.shopping_bag_rounded,
    'receipt_long' => Icons.receipt_long_rounded,
    'school' => Icons.school_rounded,
    'work' => Icons.work_rounded,
    'laptop_mac' => Icons.laptop_mac_rounded,
    'trending_up' => Icons.trending_up_rounded,
    'card_giftcard' => Icons.card_giftcard_rounded,
    'local_gas_station' => Icons.local_gas_station_rounded,
    'fitness_center' => Icons.fitness_center_rounded,
    'pets' => Icons.pets_rounded,
    'child_care' => Icons.child_care_rounded,
    'flight' => Icons.flight_rounded,
    'phone' => Icons.phone_rounded,
    'wifi' => Icons.wifi_rounded,
    _ => Icons.account_balance_wallet_rounded,
  };
}

List<BudgetCategory> defaultCategories() => [
      BudgetCategory(
        id: 'cat_salary',
        name: 'Salary',
        type: TransactionType.income,
        icon: 'work',
        colorValue: 0xFF22C55E,
      ),
      BudgetCategory(
        id: 'cat_freelance',
        name: 'Freelance',
        type: TransactionType.income,
        icon: 'laptop_mac',
        colorValue: 0xFF10B981,
      ),
      BudgetCategory(
        id: 'cat_investment',
        name: 'Investment',
        type: TransactionType.income,
        icon: 'trending_up',
        colorValue: 0xFF6366F1,
      ),
      BudgetCategory(
        id: 'cat_gift',
        name: 'Gift',
        type: TransactionType.income,
        icon: 'card_giftcard',
        colorValue: 0xFFEC4899,
      ),
      BudgetCategory(
        id: 'cat_income_other',
        name: 'Other',
        type: TransactionType.income,
        icon: 'account_balance_wallet',
        colorValue: 0xFF64748B,
      ),
      BudgetCategory(
        id: 'cat_food',
        name: 'Food',
        type: TransactionType.expense,
        icon: 'restaurant',
        colorValue: 0xFFEF4444,
      ),
      BudgetCategory(
        id: 'cat_transport',
        name: 'Transport',
        type: TransactionType.expense,
        icon: 'directions_car',
        colorValue: 0xFFF59E0B,
      ),
      BudgetCategory(
        id: 'cat_housing',
        name: 'Housing',
        type: TransactionType.expense,
        icon: 'home',
        colorValue: 0xFF8B5CF6,
      ),
      BudgetCategory(
        id: 'cat_entertainment',
        name: 'Entertainment',
        type: TransactionType.expense,
        icon: 'movie',
        colorValue: 0xFFEC4899,
      ),
      BudgetCategory(
        id: 'cat_health',
        name: 'Health',
        type: TransactionType.expense,
        icon: 'favorite',
        colorValue: 0xFF14B8A6,
      ),
      BudgetCategory(
        id: 'cat_shopping',
        name: 'Shopping',
        type: TransactionType.expense,
        icon: 'shopping_bag',
        colorValue: 0xFF3B82F6,
      ),
      BudgetCategory(
        id: 'cat_bills',
        name: 'Bills',
        type: TransactionType.expense,
        icon: 'receipt_long',
        colorValue: 0xFF64748B,
      ),
      BudgetCategory(
        id: 'cat_education',
        name: 'Education',
        type: TransactionType.expense,
        icon: 'school',
        colorValue: 0xFF6366F1,
      ),
      BudgetCategory(
        id: 'cat_expense_other',
        name: 'Other',
        type: TransactionType.expense,
        icon: 'account_balance_wallet',
        colorValue: 0xFF94A3B8,
      ),
    ];
