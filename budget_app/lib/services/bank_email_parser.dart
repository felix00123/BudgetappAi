import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;

import '../models/account.dart';
import '../models/transaction.dart';

/// Parses bank card-alert emails into transactions plus, when the email states
/// one, the balance the bank reported.
///
/// Extraction is by field shape (amount, merchant, date, status, last-four),
/// not a template per bank. Known senders only supply a nicer bank name.
/// The same code serves pasted text, Gmail, and Outlook.

enum BankAccountKind { credit, debit }

enum BankTransactionKind { purchase, withdrawal, cardPayment, income, refund }

class BankTransaction {
  const BankTransaction({
    required this.lastFour,
    required this.bank,
    required this.amount,
    required this.currency,
    required this.merchant,
    required this.date,
    this.accountKind = BankAccountKind.credit,
    this.kind = BankTransactionKind.purchase,
    this.categoryId = 'cat_expense_other',
  });

  final String lastFour;
  final String bank;
  final double amount;
  final String currency;
  final String merchant;
  final DateTime date;
  final BankAccountKind accountKind;
  final BankTransactionKind kind;
  final String categoryId;

  TransactionType get transactionType =>
      kind == BankTransactionKind.income || kind == BankTransactionKind.refund
          ? TransactionType.income
          : TransactionType.expense;

  /// Stable identity of this transaction, used to avoid importing it twice.
  String get fingerprint => [
        bank,
        lastFour,
        date.toIso8601String(),
        amount.toStringAsFixed(2),
        _normalize(merchant),
      ].join('|');
}

/// A balance the email stated, e.g. "Balance disponible: RD$65,397.38".
class BankBalance {
  const BankBalance({
    required this.amount,
    required this.currency,
    required this.label,
    required this.capturedAt,
  });

  final double amount;
  final String currency;
  final String label;
  final DateTime capturedAt;
}

class BankEmailResult {
  const BankEmailResult({
    this.bank = '',
    this.lastFour,
    this.accountKind = BankAccountKind.credit,
    this.transactions = const [],
    this.balance,
    this.issue,
  });

  final String bank;
  final String? lastFour;
  final BankAccountKind accountKind;
  final List<BankTransaction> transactions;
  final BankBalance? balance;

  /// Why nothing was extracted, shown to the user in the review screen.
  final String? issue;

  bool get isEmpty => transactions.isEmpty && balance == null;
}

AccountType accountTypeFor(BankAccountKind kind) =>
    kind == BankAccountKind.debit ? AccountType.bank : AccountType.credit;

String bankTransactionKindLabel(BankTransactionKind kind) => switch (kind) {
      BankTransactionKind.purchase => 'Purchase',
      BankTransactionKind.withdrawal => 'Cash withdrawal',
      BankTransactionKind.cardPayment => 'Card payment',
      BankTransactionKind.income => 'Income',
      BankTransactionKind.refund => 'Refund',
    };

/// Maps a merchant name onto one of the app's seeded category ids.
String categorizeMerchant(String value) {
  final text = _normalize(value);
  if (RegExp(
    r'uber|didi|indriver|cabify|taxi|metro|combustible|gasolina|shell|texaco|sunix|total',
  ).hasMatch(text)) {
    return 'cat_transport';
  }
  if (RegExp(
    r'supermercado|super market|nacional|jumbo|bravo|ole|sirena|pricesmart|mercado',
  ).hasMatch(text)) {
    return 'cat_food';
  }
  if (RegExp(
    r'restaurant|restaurante|cafe|coffee|pedidosya|ubereats|payan|pizza|burger|kfc|mcdonald|wendy',
  ).hasMatch(text)) {
    return 'cat_food';
  }
  if (RegExp(r'farmacia|medical|clinica|laboratorio|hospital|salud').hasMatch(text)) {
    return 'cat_health';
  }
  if (RegExp(r'netflix|spotify|cinema|cine|youtube|hbo|disney|gaming').hasMatch(text)) {
    return 'cat_entertainment';
  }
  if (RegExp(
    r'claro|altice|edenorte|edesur|internet|telefono|electricidad|agua',
  ).hasMatch(text)) {
    return 'cat_bills';
  }
  if (RegExp(r'airbnb|hotel|airline|aerolinea|jetblue|arajet|booking').hasMatch(text)) {
    return 'cat_expense_other';
  }
  if (RegExp(r'cajero|atm|retiro|avance de efectivo').hasMatch(text)) {
    return 'cat_expense_other';
  }
  return 'cat_shopping';
}

String _normalize(String value) => value
    .toLowerCase()
    .replaceAll('á', 'a')
    .replaceAll('é', 'e')
    .replaceAll('í', 'i')
    .replaceAll('ó', 'o')
    .replaceAll('ú', 'u')
    .replaceAll('ñ', 'n')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

String _clean(String text) => text.replaceAll(RegExp(r'[\s\u00a0]+'), ' ').trim();

bool _looksLikeHtml(String body) =>
    RegExp(r'<\s*(html|body|table|tr|td|div|p|br)\b', caseSensitive: false)
        .hasMatch(body);

String _visibleText(dom.Node node) {
  if (node is dom.Text) return node.data;
  if (node is dom.Element && ['script', 'style', 'head'].contains(node.localName)) {
    return '';
  }
  final text = node.nodes.map(_visibleText).join();
  if (node is dom.Element &&
      ['br', 'p', 'div', 'tr', 'td', 'th', 'li', 'table'].contains(node.localName)) {
    return '$text\n';
  }
  return text;
}

String? _cardNumber(String text) {
  // Only the suffix of a card identifier; never a year, phone or account number.
  for (final pattern in [
    r'(?:terminad[ao](?:\s+en)?|ending(?:\s+in)?)\s*[:#]?\s*(\d{4})(?!\d)',
    r'(?:tarjeta|visa|mastercard)[^\n#]{0,70}#\s*(\d{4})(?!\d)',
    r'(?:tarjeta|card|cuenta)[^\n]{0,70}?[*xX•●]{2,}\s*(\d{4})(?!\d)',
    r'(?:cuenta)[^\n]{0,70}?(\d{4})(?!\d)',
  ]) {
    final match = RegExp(pattern, caseSensitive: false).firstMatch(text);
    if (match != null) return match.group(1);
  }
  return null;
}

/// Reads an amount written in either 1,234.56 or 1.234,56 notation.
double? parseBankAmount(String text) {
  final match = RegExp(r'\d[\d.,]*').firstMatch(text);
  if (match == null) return null;
  var number = match.group(0)!;
  if (number.contains(',') && number.contains('.')) {
    number = number.lastIndexOf(',') > number.lastIndexOf('.')
        ? number.replaceAll('.', '').replaceAll(',', '.')
        : number.replaceAll(',', '');
  } else if (number.contains(',')) {
    number = RegExp(r',\d{2}$').hasMatch(number)
        ? number.replaceAll(',', '.')
        : number.replaceAll(',', '');
  }
  return double.tryParse(number);
}

String _currencyFrom(String text, {String fallback = ''}) {
  final money = _normalize(text);
  if (RegExp(r'\b(?:usd|us\$|dolar)').hasMatch(money)) return 'USD';
  if (RegExp(r'\b(?:rd|dop|pesos)').hasMatch(money)) return 'DOP';
  return fallback;
}

String _labelPattern(String name) {
  const folded = {
    'a': '[aáàä]',
    'e': '[eéèë]',
    'i': '[iíìï]',
    'o': '[oóòö]',
    'u': '[uúùü]',
    'n': '[nñ]',
  };
  return _normalize(name).split('').map((ch) {
    if (ch == ' ') return r'\s+';
    return folded[ch] ?? RegExp.escape(ch);
  }).join();
}

/// Reads `Label: value`, including Outlook HTML flattened onto one line.
/// Stops at the next known label so `Monto: RD$ 5 Lugar de transacción: X`
/// does not swallow the merchant into the amount.
String _field(Map<String, String> fields, String text, String name) {
  final key = _normalize(name);
  if (fields[name]?.isNotEmpty == true) return fields[name]!;
  if (fields[key]?.isNotEmpty == true) return fields[key]!;

  final label = _labelPattern(key);
  final others = _fieldKeys
      .map(_normalize)
      .where((item) => item != key)
      .map(_labelPattern)
      .join('|');
  final match = RegExp(
    '(?:^|[\\n\\r]|\\s)$label\\s*:\\s*(.*?)(?=\\s+(?:$others)\\s*:|\\n|\$)',
    caseSensitive: false,
    dotAll: true,
  ).firstMatch(text);
  if (match == null) return '';
  return _clean(match.group(1)!);
}

String _firstField(Map<String, String> fields, String text, List<String> names) {
  for (final name in names) {
    final value = _field(fields, text, name);
    if (value.isNotEmpty) return value;
  }
  return '';
}

DateTime _date(String value, String time, DateTime fallback) {
  final day = RegExp(r'(\d{1,2})[/-](\d{1,2})[/-](\d{2,4})').firstMatch(value);
  if (day == null) return fallback;
  var year = int.parse(day.group(3)!);
  if (year < 100) year += 2000;
  final clock = RegExp(
    r'(\d{1,2}):(\d{2})(?::(\d{2}))?\s*(am|pm)?',
    caseSensitive: false,
  ).firstMatch('$value $time');
  var hour = int.tryParse(clock?.group(1) ?? '') ?? 0;
  if (clock?.group(4)?.toLowerCase() == 'pm' && hour < 12) hour += 12;
  if (clock?.group(4)?.toLowerCase() == 'am' && hour == 12) hour = 0;
  return DateTime(
    year,
    int.parse(day.group(2)!),
    int.parse(day.group(1)!),
    hour,
    int.tryParse(clock?.group(2) ?? '') ?? 0,
    int.tryParse(clock?.group(3) ?? '') ?? 0,
  );
}

final _balanceLabel = RegExp(
  r'(balance|saldo)\s+(disponible|actual|total|en cuenta)',
  caseSensitive: false,
);

/// Reads a stated balance, which is deliberately never treated as a transaction
/// amount. Only explicitly labelled balances are accepted.
BankBalance? parseStatedBalance(String text, DateTime capturedAt) {
  final match = _balanceLabel.firstMatch(text);
  if (match == null) return null;

  final rest = text.substring(match.end);
  // The value sits either on the same line or on the one right below it.
  final value = RegExp(
    r'^\s*:?\s*((?:rd\$|us\$|dop|usd|rd|\$)?\s*\d[\d.,]*)',
    caseSensitive: false,
  ).firstMatch(rest);
  if (value == null) return null;

  final amount = parseBankAmount(value.group(1)!);
  if (amount == null) return null;

  return BankBalance(
    amount: amount,
    currency: _currencyFrom(value.group(1)!, fallback: 'DOP'),
    label: _clean(match.group(0)!),
    capturedAt: capturedAt,
  );
}

/// Pulls the sender address out of pasted text when it still carries headers.
String? detectSender(String text) {
  final angled = RegExp(r'<([^\s<>@]+@[^\s<>]+)>').firstMatch(text);
  if (angled != null) return angled.group(1)!.toLowerCase();
  final header = RegExp(
    r'(?:^|\n)\s*(?:from|de|remitente)\s*:\s*([^\s<>@]+@[^\s<>]+)',
    caseSensitive: false,
  ).firstMatch(text);
  if (header != null) return header.group(1)!.toLowerCase();
  final bare = RegExp(r'[^\s<>@]+@[^\s<>]+\.[a-z]{2,}').firstMatch(text);
  return bare?.group(0)?.toLowerCase();
}

String? _emailAddress(String from) {
  final lower = from.toLowerCase();
  final angled = RegExp(r'<([^>]+)>').firstMatch(lower)?.group(1);
  if (angled != null) return angled;
  final trimmed = lower.trim();
  if (trimmed.contains('@')) return trimmed;
  return null;
}

/// Known addresses/domains only pretty-print the bank name. Unknown banks
/// still parse; they fall through to "Banco …" in the body or the domain.
const _knownSenders = {
  'alertas@bhd.com.do': 'BHD',
  'no-reply@apap.com.do': 'APAP',
  'notificaciones@banreservas.com': 'Banreservas',
  'notificaciones@bsc.com.do': 'Banco Santa Cruz',
};

const _knownDomains = {
  'bhd.com.do': 'BHD',
  'apap.com.do': 'APAP',
  'banreservas.com': 'Banreservas',
  'bsc.com.do': 'Banco Santa Cruz',
  'popular.com.do': 'Popular',
  'scotiabank.com.do': 'Scotiabank',
};

String _bankFromSender(String from) {
  final sender = _emailAddress(from);
  if (sender == null) return '';
  return _knownSenders[sender] ?? _knownDomains[sender.split('@').last] ?? '';
}

String _bankFromDomain(String from) {
  final sender = _emailAddress(from);
  if (sender == null || !sender.contains('@')) return '';
  final domain = sender.split('@').last.split('.').first;
  if (domain.length < 2) return '';
  return '${domain[0].toUpperCase()}${domain.substring(1)}';
}

String _titleCaseWords(String value) => value
    .split(RegExp(r'\s+'))
    .where((word) => word.isNotEmpty)
    .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
    .join(' ');

String _bankFromBody(String normalizedText) {
  if (RegExp(r'\bbhd\b').hasMatch(normalizedText)) return 'BHD';
  if (RegExp(r'\bapap\b').hasMatch(normalizedText)) return 'APAP';
  if (RegExp(r'banreservas').hasMatch(normalizedText)) return 'Banreservas';
  if (RegExp(r'popular').hasMatch(normalizedText)) return 'Popular';
  if (RegExp(r'scotiabank').hasMatch(normalizedText)) return 'Scotiabank';
  if (RegExp(r'santa cruz|\bbsc\b').hasMatch(normalizedText)) {
    return 'Banco Santa Cruz';
  }
  final banco = RegExp(
    r'banco(?:\s+de)?\s+([a-z]+(?:\s+[a-z]+){0,3})',
  ).firstMatch(normalizedText);
  if (banco != null) return 'Banco ${_titleCaseWords(banco.group(1)!)}';
  return '';
}

const _fieldKeys = {
  'fecha',
  'fecha de transaccion',
  'fecha y hora',
  'hora',
  'moneda',
  'monto',
  'importe',
  'comercio',
  'lugar de transaccion',
  'establecimiento',
  'estado',
  'tipo',
  'cajero',
  'descripcion',
  'concepto',
  'valor',
  'date',
  'time',
  'currency',
  'amount',
  'merchant',
  'status',
  'transaction type',
};

bool _isTransactionTableHeader(List<String> labels) {
  final hasAmount = labels.contains('monto') ||
      labels.contains('amount') ||
      labels.contains('valor') ||
      labels.contains('importe');
  final hasMerchant = labels.contains('comercio') ||
      labels.contains('merchant') ||
      labels.contains('lugar de transaccion') ||
      labels.contains('establecimiento');
  final hasStatus = labels.contains('estado') || labels.contains('status');
  return hasAmount && hasMerchant && hasStatus;
}

/// Parses a bank alert email into transactions and, when present, the balance
/// the bank stated. [body] may be HTML or plain text.
BankEmailResult parseBankEmail({
  String from = '',
  String subject = '',
  required String body,
  DateTime? receivedAt,
}) {
  if (body.trim().isEmpty) {
    return const BankEmailResult(issue: 'Paste the email text first.');
  }

  final fallbackDate = receivedAt ?? DateTime.now();
  final sender = from.trim().isNotEmpty ? from : (detectSender(body) ?? '');

  final String rawText;
  if (_looksLikeHtml(body)) {
    final doc = html_parser.parse(body);
    rawText = _visibleText(doc.body ?? doc.documentElement ?? doc);
  } else {
    rawText = body;
  }
  final text = rawText
      .split('\n')
      .map(_clean)
      .where((line) => line.isNotEmpty)
      .join('\n');
  final normalizedText = _normalize(text);

  var bank = _bankFromSender(sender);
  if (bank.isEmpty) {
    bank = _bankFromBody('${_normalize(subject)} $normalizedText');
  }
  if (bank.isEmpty) bank = _bankFromDomain(sender);
  if (bank.isEmpty) {
    return const BankEmailResult(
      issue: 'Could not tell which bank sent this. Add the sender address.',
    );
  }

  final gate = '${_normalize(subject)} $normalizedText';
  if (!RegExp(
    r'notificacion|notification|transaccion|transaction|consumo|purchase|retiro|withdrawal|pago|payment|deposito|deposit|balance|saldo',
  ).hasMatch(gate)) {
    return BankEmailResult(
      bank: bank,
      issue: 'This does not look like a bank transaction alert.',
    );
  }

  final lastFour = _cardNumber(text.replaceAll('\n', ' '));
  if (lastFour == null) {
    return BankEmailResult(
      bank: bank,
      issue: 'No card or account number found in the email.',
    );
  }

  final accountKind = RegExp(
    r'tarjeta (?:de )?debito|debit card|cuenta de ahorro|cuenta corriente|checking account|savings account',
  ).hasMatch(normalizedText)
      ? BankAccountKind.debit
      : BankAccountKind.credit;

  final balance = parseStatedBalance(text, fallbackDate);

  final records = <Map<String, String>>[];
  final fields = <String, String>{};
  if (_looksLikeHtml(body)) {
    final doc = html_parser.parse(body);
    for (final table in doc.querySelectorAll('table')) {
      List<String>? headers;
      for (final row in table.querySelectorAll('tr')) {
        var parent = row.parent;
        while (parent != null && parent.localName != 'table') {
          parent = parent.parent;
        }
        if (parent != table) continue;
        final cells = row.children
            .where((c) => c.localName == 'td' || c.localName == 'th')
            .map((c) => _clean(_visibleText(c)))
            .toList();
        final labels = cells.map((c) => _normalize(c).replaceAll(':', '')).toList();
        if (_isTransactionTableHeader(labels)) {
          headers = labels;
        } else if (headers != null && cells.length == headers.length) {
          records.add(Map.fromIterables(headers, cells));
        } else if (cells.length >= 2 && _fieldKeys.contains(labels.first)) {
          fields[labels.first] = cells.skip(1).join(' ');
        }
      }
    }
  }
  if (records.isEmpty) records.add(fields);

  final transactions = <BankTransaction>[];
  for (final record in records) {
    final type = _normalize(_firstField(record, text, const ['tipo', 'transaction type']));
    final context = '${_normalize(subject)} $type $normalizedText';
    final kind = RegExp(r'retiro|cajero|\batm\b|avance de efectivo').hasMatch(context)
        ? BankTransactionKind.withdrawal
        : RegExp(r'pago (?:a |de )?(?:la )?tarjeta|abono (?:a |de )?(?:la )?tarjeta')
                .hasMatch(context)
            ? BankTransactionKind.cardPayment
            : RegExp(r'nomina|salario|deposito de sueldo|pago de sueldo').hasMatch(context)
                ? BankTransactionKind.income
                : RegExp(r'reembolso|devolucion|refund').hasMatch(context)
                    ? BankTransactionKind.refund
                    : BankTransactionKind.purchase;

    final state = _normalize(_firstField(record, text, const ['estado', 'status']));
    final stateRequired = kind == BankTransactionKind.purchase ||
        kind == BankTransactionKind.withdrawal;
    if (stateRequired &&
        !{'aprobada', 'aprobado', 'approved', 'autorizada', 'authorized'}
            .contains(state)) {
      continue;
    }

    final amountText = _firstField(record, text, const [
      'monto',
      'importe',
      'valor',
      'amount',
    ]);
    final amount = parseBankAmount(amountText);
    if (amount == null || amount <= 0) continue;

    var merchant = _firstField(record, text, const [
      'lugar de transaccion',
      'establecimiento',
      'comercio',
      'merchant',
    ]);
    if (merchant.isEmpty) merchant = _field(record, text, 'cajero');
    if (merchant.isEmpty) merchant = _field(record, text, 'descripcion');
    if (merchant.isEmpty) merchant = _field(record, text, 'concepto');
    if (merchant.isEmpty && kind == BankTransactionKind.withdrawal) {
      merchant = 'Cash withdrawal';
    }
    if (merchant.isEmpty && kind == BankTransactionKind.cardPayment) {
      merchant = 'Card payment';
    }
    if (merchant.isEmpty && kind == BankTransactionKind.income) {
      merchant = 'Salary deposit';
    }
    if (merchant.isEmpty) continue;

    final currency = _currencyFrom(
      '${_firstField(record, text, const ['moneda', 'currency'])} $amountText',
    );
    if (currency.isEmpty) continue;

    transactions.add(
      BankTransaction(
        lastFour: lastFour,
        bank: bank,
        amount: amount,
        currency: currency,
        merchant: merchant,
        date: _date(
          _firstField(record, text, const [
            'fecha y hora',
            'fecha de transaccion',
            'fecha',
            'date',
          ]),
          _firstField(record, text, const ['hora', 'time']),
          fallbackDate,
        ),
        accountKind: accountKind,
        kind: kind,
        categoryId: switch (kind) {
          BankTransactionKind.withdrawal => 'cat_expense_other',
          BankTransactionKind.income => 'cat_salary',
          BankTransactionKind.refund => 'cat_income_other',
          BankTransactionKind.cardPayment => 'cat_bills',
          BankTransactionKind.purchase => categorizeMerchant(merchant),
        },
      ),
    );
  }

  return BankEmailResult(
    bank: bank,
    lastFour: lastFour,
    accountKind: accountKind,
    transactions: transactions,
    balance: balance,
    issue: transactions.isEmpty && balance == null
        ? 'Found the card but no approved transaction or stated balance.'
        : null,
  );
}
