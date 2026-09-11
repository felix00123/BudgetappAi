import 'package:html/parser.dart' as html_parser;

/// Helpers that turn a Microsoft Graph message JSON into plain fields
/// for [parseBankEmail].
class OutlookMessageFields {
  const OutlookMessageFields({
    required this.id,
    required this.from,
    required this.subject,
    required this.body,
    this.receivedAt,
  });

  final String id;
  final String from;
  final String subject;
  final String body;
  final DateTime? receivedAt;
}

OutlookMessageFields? parseOutlookGraphMessage(Map<String, dynamic> json) {
  final id = json['id'] as String?;
  if (id == null || id.isEmpty) return null;

  final fromObj = json['from'] as Map<String, dynamic>?;
  final emailAddress = fromObj?['emailAddress'] as Map<String, dynamic>?;
  final address = (emailAddress?['address'] as String?)?.trim() ?? '';
  final name = (emailAddress?['name'] as String?)?.trim() ?? '';
  final from = address.isNotEmpty
      ? (name.isNotEmpty ? '$name <$address>' : address)
      : name;

  final subject = (json['subject'] as String?) ?? '';
  final bodyObj = json['body'] as Map<String, dynamic>?;
  final contentType = (bodyObj?['contentType'] as String?)?.toLowerCase() ?? '';
  final rawContent = (bodyObj?['content'] as String?) ??
      (json['bodyPreview'] as String?) ??
      '';

  final body = contentType == 'html'
      ? _htmlToVisibleText(rawContent)
      : rawContent;

  DateTime? receivedAt;
  final receivedRaw = json['receivedDateTime'] as String?;
  if (receivedRaw != null && receivedRaw.isNotEmpty) {
    receivedAt = DateTime.tryParse(receivedRaw)?.toLocal();
  }

  return OutlookMessageFields(
    id: id,
    from: from,
    subject: subject,
    body: body,
    receivedAt: receivedAt,
  );
}

String _htmlToVisibleText(String html) {
  final doc = html_parser.parse(html);
  final body = doc.body;
  if (body == null) return html;
  return body.text.replaceAll(RegExp(r'\s+'), ' ').trim();
}

/// KQL-ish search used with Graph `$search` for Dominican bank alerts.
String outlookBankSearchQuery({DateTime? since, DateTime? until}) {
  final parts = <String>[
    '(from:alertas@bhd.com.do OR from:no-reply@apap.com.do OR '
        'from:notificaciones@banreservas.com OR subject:transacciones OR '
        'subject:consumo OR subject:compra OR subject:aprobada OR '
        'subject:retiro OR subject:pago OR "tarjeta terminada" OR '
        '"consumo realizado")',
  ];
  if (since != null) {
    parts.add('received>=${_graphDate(since)}');
  }
  if (until != null) {
    parts.add('received<=${_graphDate(until)}');
  }
  return parts.join(' AND ');
}

String _graphDate(DateTime date) {
  final value = date.toUtc();
  return '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}
