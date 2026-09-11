import 'package:flutter_test/flutter_test.dart';
import 'package:_discoveryapis_commons/_discoveryapis_commons.dart';
import 'package:googleapis/gmail/v1.dart' as gmail;

import 'package:budget_app/services/gmail_request_queue.dart';

void main() {
  late DateTime now;
  late List<Duration> waits;
  late GmailRequestQueue queue;

  setUp(() {
    now = DateTime.utc(2026, 9, 9);
    waits = [];
    queue = GmailRequestQueue(
      now: () => now,
      jitter: () => 0,
      sleep: (duration) async {
        waits.add(duration);
        now = now.add(duration);
      },
    );
  });

  test('spaces queued reads 600ms apart', () async {
    final started = <DateTime>[];
    await Future.wait(
      List.generate(
        5,
        (_) => queue.run(() async {
          started.add(now);
        }),
      ),
    );
    expect(started.length, 5);
    for (var i = 1; i < started.length; i++) {
      expect(
        started[i].difference(started[i - 1]),
        greaterThanOrEqualTo(const Duration(milliseconds: 600)),
      );
    }
  });

  test('retries a 403 quota failure then succeeds', () async {
    var attempts = 0;
    final statuses = <String>[];
    final result = await queue.run(() async {
      if (++attempts <= 3) {
        throw gmail.DetailedApiRequestError(
          403,
          "Quota exceeded for quota metric 'Total Query Cost' and limit "
          "'Units per minute per user'",
        );
      }
      return 'success';
    }, onStatus: statuses.add);

    expect(result, 'success');
    expect(attempts, 4);
    expect(statuses.first, contains('Retrying'));
  });

  test('does not retry permission failures', () async {
    final error = gmail.DetailedApiRequestError(403, 'Insufficient Permission');
    await expectLater(
      queue.run(() async => throw error),
      throwsA(same(error)),
    );
  });

  test('does not retry dailyLimitExceeded', () async {
    final error = gmail.DetailedApiRequestError(
      403,
      'Daily Limit Exceeded',
      errors: [
        ApiRequestErrorDetail(reason: 'dailyLimitExceeded'),
      ],
    );
    await expectLater(
      queue.run(() async => throw error),
      throwsA(same(error)),
    );
  });
}
