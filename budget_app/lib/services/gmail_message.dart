import 'dart:convert';

import 'package:googleapis/gmail/v1.dart' as gmail;
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;

/// Reads a named header from a Gmail message payload.
String gmailHeader(gmail.Message message, String name) {
  for (final header
      in message.payload?.headers ?? const <gmail.MessagePartHeader>[]) {
    if (header.name?.toLowerCase() == name.toLowerCase()) {
      return header.value ?? '';
    }
  }
  return '';
}

/// Prefer HTML (as visible text), fall back to plain text.
String gmailBodyText(gmail.Message message) {
  final htmlParts = _mimeParts(message.payload, 'text/html');
  if (htmlParts.isNotEmpty) {
    final doc = html_parser.parse(htmlParts.join('\n'));
    if (doc.body != null) return _visibleText(doc.body!);
  }
  return _mimeParts(message.payload, 'text/plain').join('\n');
}

DateTime? gmailInternalDate(gmail.Message message) {
  final raw = message.internalDate;
  if (raw == null || raw.isEmpty) return null;
  final millis = int.tryParse(raw);
  if (millis == null) return null;
  return DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true).toLocal();
}

List<String> _mimeParts(gmail.MessagePart? part, String type) {
  if (part == null) return [];
  final result = <String>[];
  if (part.mimeType == type ||
      (part.mimeType == null && type == 'text/plain')) {
    final data = part.body?.data;
    if (data != null) {
      try {
        final bytes = base64Url.decode(base64Url.normalize(data));
        try {
          result.add(utf8.decode(bytes));
        } on FormatException {
          result.add(latin1.decode(bytes));
        }
      } on FormatException {
        // Ignore invalid MIME chunks.
      }
    }
  }
  for (final child in part.parts ?? const <gmail.MessagePart>[]) {
    result.addAll(_mimeParts(child, type));
  }
  return result;
}

String _visibleText(dom.Node node) {
  if (node is dom.Text) return node.data;
  if (node is dom.Element &&
      ['script', 'style', 'head'].contains(node.localName)) {
    return '';
  }
  final text = node.nodes.map(_visibleText).join();
  if (node is dom.Element &&
      [
        'br',
        'p',
        'div',
        'tr',
        'td',
        'th',
        'li',
        'table',
      ].contains(node.localName)) {
    return '$text\n';
  }
  return text;
}
