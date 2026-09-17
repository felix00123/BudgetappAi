import 'package:html/dom.dart' as dom;
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

/// Keeps block tags as line breaks so `Monto:` / `Lugar de transacción:`
/// stay on their own lines for the generic parser. Collapsing every
/// whitespace character to a single space would glue the labels together.
String _htmlToVisibleText(String html) {
  final doc = html_parser.parse(html);
  final root = doc.body ?? doc.documentElement;
  if (root == null) return html;
  return _visibleText(root)
      .replaceAll(RegExp(r'[ \t]+'), ' ')
      .replaceAll(RegExp(r' *\n+ *'), '\n')
      .trim();
}

String _visibleText(dom.Node node) {
  if (node is dom.Text) return node.data;
  if (node is dom.Element &&
      ['script', 'style', 'head'].contains(node.localName)) {
    return '';
  }
  final text = node.nodes.map(_visibleText).join();
  if (node is dom.Element &&
      ['br', 'p', 'div', 'tr', 'td', 'th', 'li', 'table']
          .contains(node.localName)) {
    return '$text\n';
  }
  return text;
}

/// KQL-ish search used with Graph `$search` for bank card alerts.
/// No inner double quotes: Graph already wraps the whole `$search` value
/// in quotes, so `"tarjeta terminada"` inside it returns HTTP 400.
String outlookBankSearchQuery({DateTime? since, DateTime? until}) {
  final parts = <String>[
    '(from:alertas@bhd.com.do OR from:no-reply@apap.com.do OR '
        'from:notificaciones@banreservas.com OR from:notificaciones@bsc.com.do OR '
        'subject:transacciones OR subject:notificacion OR subject:notificaciones OR '
        'subject:consumo OR subject:compra OR subject:aprobada OR '
        'subject:retiro OR subject:pago OR terminada OR transaccion OR consumo)',
  ];
  if (since != null) {
    parts.add('received>=${_graphDate(since)}');
  }
  if (until != null) {
    parts.add('received<=${_graphDate(until)}');
  }
  return parts.join(' AND ');
}

/// Graph `$search` must be one quoted string. Strips inner `"` so KQL
/// phrases cannot break the wrapper.
String encodeOutlookGraphSearch(String kql) {
  final cleaned = kql.replaceAll('"', '');
  return Uri.encodeQueryComponent('"$cleaned"');
}

String _graphDate(DateTime date) {
  final value = date.toUtc();
  return '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}
