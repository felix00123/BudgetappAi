import 'package:intl/intl.dart';

final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
final compactCurrencyFormat = NumberFormat.compactCurrency(symbol: '\$');
final dateFormat = DateFormat('MMM d, yyyy');
final shortDateFormat = DateFormat('MMM d');
final monthYearFormat = DateFormat('MMMM yyyy');
final fileDateFormat = DateFormat('yyyy-MM-dd');

String formatCurrency(double amount) => currencyFormat.format(amount);

/// Formats an amount that came from a bank in its own currency.
String formatAmountWithCurrency(double amount, String currency) {
  final symbol = currency == 'USD' ? 'US\$' : 'RD\$';
  return NumberFormat.currency(symbol: symbol, decimalDigits: 2).format(amount);
}

String formatCompactCurrency(double amount) => compactCurrencyFormat.format(amount);
String formatDate(DateTime date) => dateFormat.format(date);
String formatShortDate(DateTime date) => shortDateFormat.format(date);
String formatMonthYear(DateTime date) => monthYearFormat.format(date);

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
  if (months <= 0) return 'Already reached!';
  if (months < 12) return '$months month${months == 1 ? '' : 's'}';
  final years = months ~/ 12;
  final remainingMonths = months % 12;
  if (remainingMonths == 0) {
    return '$years year${years == 1 ? '' : 's'}';
  }
  return '$years year${years == 1 ? '' : 's'}, $remainingMonths month${remainingMonths == 1 ? '' : 's'}';
}
