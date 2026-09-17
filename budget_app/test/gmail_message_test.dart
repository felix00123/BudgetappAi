import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:googleapis/gmail/v1.dart' as gmail;

import 'package:budget_app/services/gmail_message.dart';
import 'package:budget_app/services/gmail_sync_service.dart';

String _b64(String text) => base64Url.encode(utf8.encode(text));

void main() {
  group('gmailDateQuery', () {
    test('formats UTC date as YYYY/MM/DD', () {
      expect(
        gmailDateQuery(DateTime.utc(2026, 3, 5, 15)),
        '2026/03/05',
      );
    });
  });

  group('gmail message helpers', () {
    test('reads headers case-insensitively', () {
      final message = gmail.Message(
        payload: gmail.MessagePart(
          headers: [
            gmail.MessagePartHeader(
              name: 'From',
              value: 'alertas@bhd.com.do',
            ),
            gmail.MessagePartHeader(
              name: 'Subject',
              value: 'Notificacion de consumo',
            ),
          ],
        ),
      );

      expect(gmailHeader(message, 'from'), 'alertas@bhd.com.do');
      expect(gmailHeader(message, 'SUBJECT'), 'Notificacion de consumo');
      expect(gmailHeader(message, 'missing'), '');
    });

    test('decodes plain text body', () {
      final message = gmail.Message(
        payload: gmail.MessagePart(
          mimeType: 'text/plain',
          body: gmail.MessagePartBody(data: _b64('Balance disponible RD\$100')),
        ),
      );

      expect(gmailBodyText(message), contains('Balance disponible'));
    });

    test('prefers HTML visible text over plain', () {
      final message = gmail.Message(
        payload: gmail.MessagePart(
          mimeType: 'multipart/alternative',
          parts: [
            gmail.MessagePart(
              mimeType: 'text/plain',
              body: gmail.MessagePartBody(data: _b64('plain only')),
            ),
            gmail.MessagePart(
              mimeType: 'text/html',
              body: gmail.MessagePartBody(
                data: _b64('<p>HTML <b>body</b></p>'),
              ),
            ),
          ],
        ),
      );

      final text = gmailBodyText(message);
      expect(text, contains('HTML'));
      expect(text, contains('body'));
      expect(text, isNot(contains('plain only')));
    });

    test('converts internalDate millis to local DateTime', () {
      final message = gmail.Message(
        internalDate:
            '${DateTime.utc(2026, 1, 15, 12).millisecondsSinceEpoch}',
      );
      final date = gmailInternalDate(message);
      expect(date, isNotNull);
      expect(date!.year, 2026);
      expect(date.month, 1);
      expect(date.day, 15);
    });
  });

  group('purchaseSearch', () {
    test('matches alert shape not only three banks', () {
      expect(GmailSyncService.purchaseSearch, contains('bsc.com.do'));
      expect(GmailSyncService.purchaseSearch, contains('notificacion'));
      expect(GmailSyncService.purchaseSearch, contains('terminada en'));
      expect(GmailSyncService.purchaseSearch, contains('lugar de transaccion'));
    });
  });
}
