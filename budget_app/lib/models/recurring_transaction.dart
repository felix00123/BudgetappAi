import 'package:intl/intl.dart';

import '../utils/formatters.dart';
import 'transaction.dart';

enum RecurrenceFrequency { monthly, weekly, yearly }

class RecurringTransaction {
  const RecurringTransaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.categoryId,
    required this.accountId,
    required this.frequency,
    required this.startDate,
    required this.createdAt,
    this.dayOfMonth = 1,
    this.dayOfWeek = DateTime.monday,
    this.monthOfYear = 1,
    this.endDate,
    this.isActive = true,
    this.lastGeneratedDate,
    this.note,
  });

  final String id;
  final String title;
  final double amount;
  final TransactionType type;
  final String categoryId;
  final String accountId;
  final RecurrenceFrequency frequency;
  final int dayOfMonth;
  final int dayOfWeek;
  final int monthOfYear;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isActive;
  final DateTime? lastGeneratedDate;
  final String? note;
  final DateTime createdAt;

  String get scheduleLabel => describeRecurrence(this);

  DateTime? get nextDueDate {
    final today = _dateOnly(DateTime.now());
    if (!isActive) return null;
    if (endDate != null && today.isAfter(_dateOnly(endDate!))) return null;

    final anchor = lastGeneratedDate ?? startDate.subtract(const Duration(days: 1));
    var next = nextDueAfter(anchor);
    while (next != null && next.isBefore(_dateOnly(startDate))) {
      next = nextDueAfter(next);
    }
    return next;
  }

  DateTime? nextDueAfter(DateTime after) {
    final anchor = _dateOnly(after);

    switch (frequency) {
      case RecurrenceFrequency.monthly:
        var year = anchor.year;
        var month = anchor.month + 1;
        if (month > 12) {
          month = 1;
          year++;
        }
        if (anchor.day < _clampDay(year, anchor.month, dayOfMonth)) {
          return _dateWithDay(year, anchor.month, dayOfMonth);
        }
        return _dateWithDay(year, month, dayOfMonth);
      case RecurrenceFrequency.weekly:
        var cursor = anchor.add(const Duration(days: 1));
        for (var i = 0; i < 7; i++) {
          if (cursor.weekday == dayOfWeek) return cursor;
          cursor = cursor.add(const Duration(days: 1));
        }
        return null;
      case RecurrenceFrequency.yearly:
        var year = anchor.year;
        var candidate = _dateWithDay(year, monthOfYear, dayOfMonth);
        if (!candidate.isAfter(anchor)) {
          candidate = _dateWithDay(year + 1, monthOfYear, dayOfMonth);
        }
        return candidate;
    }
  }

  DateTime? firstDueOnOrAfter(DateTime date) {
    final from = _dateOnly(date);

    switch (frequency) {
      case RecurrenceFrequency.monthly:
        var candidate = _dateWithDay(from.year, from.month, dayOfMonth);
        if (candidate.isBefore(from)) {
          var month = from.month + 1;
          var year = from.year;
          if (month > 12) {
            month = 1;
            year++;
          }
          candidate = _dateWithDay(year, month, dayOfMonth);
        }
        return candidate;
      case RecurrenceFrequency.weekly:
        var cursor = from;
        for (var i = 0; i < 7; i++) {
          if (cursor.weekday == dayOfWeek) return cursor;
          cursor = cursor.add(const Duration(days: 1));
        }
        return null;
      case RecurrenceFrequency.yearly:
        var candidate = _dateWithDay(from.year, monthOfYear, dayOfMonth);
        if (candidate.isBefore(from)) {
          candidate = _dateWithDay(from.year + 1, monthOfYear, dayOfMonth);
        }
        return candidate;
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'amount': amount,
        'type': type.name,
        'categoryId': categoryId,
        'accountId': accountId,
        'frequency': frequency.name,
        'dayOfMonth': dayOfMonth,
        'dayOfWeek': dayOfWeek,
        'monthOfYear': monthOfYear,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'isActive': isActive,
        'lastGeneratedDate': lastGeneratedDate?.toIso8601String(),
        'note': note,
        'createdAt': createdAt.toIso8601String(),
      };

  factory RecurringTransaction.fromJson(Map<String, dynamic> json) =>
      RecurringTransaction(
        id: json['id'] as String,
        title: json['title'] as String,
        amount: (json['amount'] as num).toDouble(),
        type: TransactionType.values.byName(json['type'] as String),
        categoryId: json['categoryId'] as String,
        accountId: json['accountId'] as String,
        frequency: RecurrenceFrequency.values.byName(json['frequency'] as String),
        dayOfMonth: json['dayOfMonth'] as int? ?? 1,
        dayOfWeek: json['dayOfWeek'] as int? ?? DateTime.monday,
        monthOfYear: json['monthOfYear'] as int? ?? 1,
        startDate: DateTime.parse(json['startDate'] as String),
        endDate: json['endDate'] != null
            ? DateTime.parse(json['endDate'] as String)
            : null,
        isActive: json['isActive'] as bool? ?? true,
        lastGeneratedDate: json['lastGeneratedDate'] != null
            ? DateTime.parse(json['lastGeneratedDate'] as String)
            : null,
        note: json['note'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  RecurringTransaction copyWith({
    String? title,
    double? amount,
    TransactionType? type,
    String? categoryId,
    String? accountId,
    RecurrenceFrequency? frequency,
    int? dayOfMonth,
    int? dayOfWeek,
    int? monthOfYear,
    DateTime? startDate,
    DateTime? endDate,
    bool clearEndDate = false,
    bool? isActive,
    DateTime? lastGeneratedDate,
    bool clearLastGeneratedDate = false,
    String? note,
  }) =>
      RecurringTransaction(
        id: id,
        title: title ?? this.title,
        amount: amount ?? this.amount,
        type: type ?? this.type,
        categoryId: categoryId ?? this.categoryId,
        accountId: accountId ?? this.accountId,
        frequency: frequency ?? this.frequency,
        dayOfMonth: dayOfMonth ?? this.dayOfMonth,
        dayOfWeek: dayOfWeek ?? this.dayOfWeek,
        monthOfYear: monthOfYear ?? this.monthOfYear,
        startDate: startDate ?? this.startDate,
        endDate: clearEndDate ? null : (endDate ?? this.endDate),
        isActive: isActive ?? this.isActive,
        lastGeneratedDate: clearLastGeneratedDate
            ? null
            : (lastGeneratedDate ?? this.lastGeneratedDate),
        note: note ?? this.note,
        createdAt: createdAt,
      );

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static int _clampDay(int year, int month, int day) {
    final lastDay = DateTime(year, month + 1, 0).day;
    return day.clamp(1, lastDay);
  }

  static DateTime _dateWithDay(int year, int month, int day) {
    final clamped = _clampDay(year, month, day);
    return DateTime(year, month, clamped);
  }
}

bool get _isEs =>
    (Intl.defaultLocale ?? 'en').toLowerCase().startsWith('es');

String describeRecurrence(RecurringTransaction recurring) {
  switch (recurring.frequency) {
    case RecurrenceFrequency.monthly:
      return _isEs
          ? 'Cada ${recurring.dayOfMonth} del mes'
          : 'Every ${ordinalDay(recurring.dayOfMonth)} of the month';
    case RecurrenceFrequency.weekly:
      return _isEs
          ? 'Cada ${_weekdayName(recurring.dayOfWeek)}'
          : 'Every ${_weekdayName(recurring.dayOfWeek)}';
    case RecurrenceFrequency.yearly:
      final month = formatMonthYear(
        DateTime(2000, recurring.monthOfYear, 1),
      ).split(' ').first;
      return _isEs
          ? 'Cada ${recurring.dayOfMonth} de $month'
          : 'Every $month ${ordinalDay(recurring.dayOfMonth)}';
  }
}

String ordinalDay(int day) {
  if (_isEs) return '$day';
  if (day >= 11 && day <= 13) return '${day}th';
  return switch (day % 10) {
    1 => '${day}st',
    2 => '${day}nd',
    3 => '${day}rd',
    _ => '${day}th',
  };
}

String _weekdayName(int weekday) {
  const en = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  const es = [
    'lunes',
    'martes',
    'miércoles',
    'jueves',
    'viernes',
    'sábado',
    'domingo',
  ];
  final names = _isEs ? es : en;
  return names[(weekday - 1).clamp(0, 6)];
}

String frequencyLabel(RecurrenceFrequency frequency) {
  return switch (frequency) {
    RecurrenceFrequency.monthly => _isEs ? 'Mensual' : 'Monthly',
    RecurrenceFrequency.weekly => _isEs ? 'Semanal' : 'Weekly',
    RecurrenceFrequency.yearly => _isEs ? 'Anual' : 'Yearly',
  };
}
