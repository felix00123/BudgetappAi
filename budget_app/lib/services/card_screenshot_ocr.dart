import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import 'bank_email_parser.dart';

class CardScreenshotFields {
  const CardScreenshotFields({
    this.lastFour,
    this.balance,
    this.dueDate,
    this.cutoffDate,
  });

  final String? lastFour;
  final double? balance;
  final DateTime? dueDate;
  final DateTime? cutoffDate;

  bool get isEmpty =>
      lastFour == null && balance == null && dueDate == null && cutoffDate == null;
}

/// Reads last 4, available balance, cutoff date, and due date from a card screen.
class CardScreenshotOcr {
  Future<CardScreenshotFields> read(String imagePath) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final result = await recognizer.processImage(
        InputImage.fromFilePath(imagePath),
      );
      return parseCardScreenshotText(result.text);
    } finally {
      await recognizer.close();
    }
  }
}

CardScreenshotFields parseCardScreenshotText(String raw) {
  final text = raw.replaceAll('\u00a0', ' ');
  return CardScreenshotFields(
    lastFour: _lastFour(text),
    balance: _balance(text),
    cutoffDate: _labeledDate(text, _cutoffLabels),
    dueDate: _labeledDate(text, _dueLabels),
  );
}

const _cutoffLabels = [
  r'fecha\s+de\s+corte',
  r'd[ií]a\s+de\s+corte',
  r'corte\s+el',
  r'cutoff(?:\s+date)?',
];

const _dueLabels = [
  r'pagar\s+antes\s+de',
  r'fecha\s+de\s+vencimiento',
  r'fecha\s+de\s+pago',
  r'vencimiento',
  r'vence(?:\s+el)?',
  r'due\s+date',
  r'pay\s+before',
];

String? _lastFour(String text) {
  for (final pattern in [
    r'(?:terminad[ao](?:\s+en)?|ending(?:\s+in)?|últimos?\s*4)[^\d]{0,12}(\d{4})(?!\d)',
    r'(?:visa|mastercard|amex|tarjeta)[^\n]{0,48}?[•●·*.xX-]{2,}[\s•●·*.xX-]*(\d{4})(?!\d)',
    r'[•●·*.xX-]{3,}[\s•●·*.xX-]*(\d{4})(?!\d)',
  ]) {
    final match = RegExp(pattern, caseSensitive: false).firstMatch(text);
    final digits = match?.group(1);
    if (digits != null && !_looksLikeYear(digits)) return digits;
  }
  return null;
}

double? _balance(String text) {
  for (final label in [
    r'cr[eé]dito\s+disponible',
    r'available\s+credit',
    r'balance\s+a\s+la\s+fecha',
  ]) {
    final match = RegExp('$label[^\\d]{0,40}', caseSensitive: false).firstMatch(text);
    if (match == null) continue;
    final window = text.substring(match.end, (match.end + 40).clamp(0, text.length));
    final amount = parseBankAmount(window);
    if (amount != null) return amount;
  }
  return null;
}

DateTime? _labeledDate(String text, List<String> labels) {
  final labeled = RegExp(
    '(?:${labels.join('|')})[:\\s]*',
    caseSensitive: false,
  );
  final match = labeled.firstMatch(text);
  if (match == null) return null;
  final window = text.substring(match.end, (match.end + 80).clamp(0, text.length));
  return _dateIn(window) ?? _dateIn(text.substring(match.start, (match.start + 120).clamp(0, text.length)));
}

DateTime? _dateIn(String text) {
  final named = RegExp(
    r'(enero|febrero|marzo|abril|mayo|junio|julio|agosto|septiembre|setiembre|octubre|noviembre|diciembre|january|february|march|april|may|june|july|august|september|october|november|december)\s+(\d{1,2}),?\s+(\d{4})',
    caseSensitive: false,
  ).firstMatch(text);
  if (named != null) {
    final month = _monthNumber(named.group(1)!);
    final day = int.parse(named.group(2)!);
    final year = int.parse(named.group(3)!);
    if (month != null) return DateTime(year, month, day);
  }

  final dayFirst = RegExp(
    r'(\d{1,2})\s+de\s+(enero|febrero|marzo|abril|mayo|junio|julio|agosto|septiembre|setiembre|octubre|noviembre|diciembre)\s+(?:de\s+)?(\d{4})',
    caseSensitive: false,
  ).firstMatch(text);
  if (dayFirst != null) {
    final month = _monthNumber(dayFirst.group(2)!);
    final day = int.parse(dayFirst.group(1)!);
    final year = int.parse(dayFirst.group(3)!);
    if (month != null) return DateTime(year, month, day);
  }

  final numeric = RegExp(r'\b(\d{1,2})[/-](\d{1,2})[/-](\d{4})\b').firstMatch(text);
  if (numeric != null) {
    final first = int.parse(numeric.group(1)!);
    final second = int.parse(numeric.group(2)!);
    final year = int.parse(numeric.group(3)!);
    if (first > 12) return DateTime(year, second, first);
    return DateTime(year, first, second);
  }
  return null;
}

bool _looksLikeYear(String four) {
  final value = int.parse(four);
  return value >= 1990 && value <= 2090;
}

int? _monthNumber(String raw) {
  final month = raw.toLowerCase();
  const names = {
    'enero': 1,
    'january': 1,
    'febrero': 2,
    'february': 2,
    'marzo': 3,
    'march': 3,
    'abril': 4,
    'april': 4,
    'mayo': 5,
    'may': 5,
    'junio': 6,
    'june': 6,
    'julio': 7,
    'july': 7,
    'agosto': 8,
    'august': 8,
    'septiembre': 9,
    'setiembre': 9,
    'september': 9,
    'octubre': 10,
    'october': 10,
    'noviembre': 11,
    'november': 11,
    'diciembre': 12,
    'december': 12,
  };
  for (final entry in names.entries) {
    if (month.startsWith(entry.key)) return entry.value;
  }
  return null;
}
