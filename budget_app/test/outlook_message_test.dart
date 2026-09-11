import 'package:flutter_test/flutter_test.dart';

import 'package:budget_app/services/outlook_message.dart';
import 'package:budget_app/services/outlook_sync_service.dart';

void main() {
  group('parseOutlookGraphMessage', () {
    test('reads from, subject, html body and received date', () {
      final fields = parseOutlookGraphMessage({
        'id': 'msg-1',
        'subject': 'Notificacion de consumo',
        'from': {
          'emailAddress': {
            'name': 'BHD',
            'address': 'alertas@bhd.com.do',
          },
        },
        'receivedDateTime': '2026-09-10T15:30:00Z',
        'body': {
          'contentType': 'html',
          'content':
              '<p>Compra aprobada RD\$350.00 en Uber</p><p>Balance disponible RD\$1000</p>',
        },
      });

      expect(fields, isNotNull);
      expect(fields!.id, 'msg-1');
      expect(fields.from, contains('alertas@bhd.com.do'));
      expect(fields.subject, 'Notificacion de consumo');
      expect(fields.body, contains('Uber'));
      expect(fields.body, isNot(contains('<p>')));
      expect(fields.receivedAt, isNotNull);
      expect(fields.receivedAt!.year, 2026);
    });

    test('falls back to bodyPreview when body is missing', () {
      final fields = parseOutlookGraphMessage({
        'id': 'msg-2',
        'subject': 'Retiro',
        'from': {
          'emailAddress': {'address': 'no-reply@apap.com.do'},
        },
        'bodyPreview': 'Retiro en cajero RD\$500.00',
      });

      expect(fields!.from, 'no-reply@apap.com.do');
      expect(fields.body, contains('cajero'));
    });

    test('returns null without an id', () {
      expect(parseOutlookGraphMessage({'subject': 'x'}), isNull);
    });
  });

  group('outlookBankSearchQuery', () {
    test('includes bank senders', () {
      final q = outlookBankSearchQuery();
      expect(q, contains('alertas@bhd.com.do'));
      expect(q, contains('apap.com.do'));
      expect(q, contains('banreservas.com'));
    });

    test('adds received date bounds', () {
      final q = outlookBankSearchQuery(
        since: DateTime.utc(2026, 1, 2),
        until: DateTime.utc(2026, 1, 10),
      );
      expect(q, contains('received>=2026-01-02'));
      expect(q, contains('received<=2026-01-10'));
    });
  });

  group('OutlookSyncService config', () {
    test('reports missing client id', () {
      final service = OutlookSyncService(
        readTokens: () async => const OutlookTokenStore(),
        writeTokens: (_) async {},
      );
      // Without dart-define, client id is empty in tests.
      expect(service.isConfigured, isFalse);
      expect(
        () => service.connect(),
        throwsA(
          isA<OutlookSyncException>().having(
            (e) => e.message,
            'message',
            contains('MICROSOFT_CLIENT_ID'),
          ),
        ),
      );
    });
  });
}
