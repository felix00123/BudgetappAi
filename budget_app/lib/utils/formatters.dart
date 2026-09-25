import 'package:intl/intl.dart';

String get _locale {
  final value = Intl.defaultLocale ?? 'en';
  return value.startsWith('es') ? 'es' : 'en';
}

bool get _isEs => _locale == 'es';

DateFormat _dateFormat(String pattern) {
  try {
    return DateFormat(pattern, _locale);
  } catch (_) {
    return DateFormat(pattern);
  }
}

final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
final compactCurrencyFormat = NumberFormat.compactCurrency(symbol: '\$');
final fileDateFormat = DateFormat('yyyy-MM-dd');

String formatCurrency(double amount) => currencyFormat.format(amount);

/// Formats an amount that came from a bank in its own currency.
String formatAmountWithCurrency(double amount, String currency) {
  final symbol = currency == 'USD' ? 'US\$' : 'RD\$';
  return NumberFormat.currency(symbol: symbol, decimalDigits: 2).format(amount);
}

String formatCompactCurrency(double amount) => compactCurrencyFormat.format(amount);

String formatDate(DateTime date) {
  return _dateFormat(_isEs ? 'd MMM yyyy' : 'MMM d, yyyy').format(date);
}

String formatShortDate(DateTime date) {
  return _dateFormat(_isEs ? 'd MMM' : 'MMM d').format(date);
}

String formatMonthYear(DateTime date) {
  return _dateFormat('MMMM yyyy').format(date);
}

/// Stable yyyy-MM-dd key for maps and storage lookups.
String dateKey(DateTime date) =>
    fileDateFormat.format(DateTime(date.year, date.month, date.day));

DateTime parseDateKey(String key) {
  final parts = key.split('-');
  return DateTime(
    int.parse(parts[0]),
    int.parse(parts[1]),
    int.parse(parts[2]),
  );
}

String formatDuration(int months) {
  if (months <= 0) return _isEs ? '¡Ya alcanzado!' : 'Already reached!';
  if (months < 12) {
    if (_isEs) return months == 1 ? '1 mes' : '$months meses';
    return '$months month${months == 1 ? '' : 's'}';
  }
  final years = months ~/ 12;
  final remainingMonths = months % 12;
  if (_isEs) {
    final yearPart = years == 1 ? '1 año' : '$years años';
    if (remainingMonths == 0) return yearPart;
    final monthPart = remainingMonths == 1 ? '1 mes' : '$remainingMonths meses';
    return '$yearPart, $monthPart';
  }
  if (remainingMonths == 0) {
    return '$years year${years == 1 ? '' : 's'}';
  }
  return '$years year${years == 1 ? '' : 's'}, $remainingMonths month${remainingMonths == 1 ? '' : 's'}';
}
