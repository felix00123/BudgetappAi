import 'package:flutter_test/flutter_test.dart';

import 'package:budget_app/services/card_screenshot_ocr.dart';

void main() {
  test('reads last 4, balance, cutoff, and due date from a card screenshot', () {
    const text = '''
VISA
•••• •••• 1101
Crédito disponible
DOP 19,681.25
Balance tarjeta
Límite DOP 20,000.00
USD 0.00
Fecha de corte Septiembre 2, 2026
Pagar antes de Septiembre 17, 2026
Credimás
''';

    final fields = parseCardScreenshotText(text);
    expect(fields.lastFour, '1101');
    expect(fields.balance, 19681.25);
    expect(fields.cutoffDate, DateTime(2026, 9, 2));
    expect(fields.dueDate, DateTime(2026, 9, 17));
  });

  test('prefers crédito disponible over other balances', () {
    const text = '''
•••• 4281
Crédito disponible DOP 10,000.50
Balance a la fecha DOP 318.75
Pagar antes de October 12, 2026
''';
    final fields = parseCardScreenshotText(text);
    expect(fields.lastFour, '4281');
    expect(fields.balance, 10000.50);
    expect(fields.dueDate, DateTime(2026, 10, 12));
  });

  test('parses Spanish day-first due dates', () {
    const text = '•••• 9675\nPagar antes de 17 de septiembre de 2026';
    final fields = parseCardScreenshotText(text);
    expect(fields.lastFour, '9675');
    expect(fields.dueDate, DateTime(2026, 9, 17));
  });
}
