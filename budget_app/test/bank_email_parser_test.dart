import 'package:flutter_test/flutter_test.dart';

import 'package:budget_app/models/transaction.dart';
import 'package:budget_app/services/bank_email_parser.dart';

void main() {
  group('transactions', () {
    test('parses a BHD HTML transaction table and card suffix', () {
      final result = parseBankEmail(
        from: 'BHD Alertas <alertas@bhd.com.do>',
        subject: 'BHD Notificación de Transacciones',
        body: '''
        <table><tr><td>Fecha</td><td>Moneda</td><td>Monto</td><td>Comercio</td><td>Estado</td><td>Tipo</td></tr>
        <tr><td>09/09/2026 11:33 am</td><td>RD</td><td>\$369.00</td><td>SUPERMERCADO FORTUNA</td><td>Aprobada</td><td>Compra</td></tr></table>
        Te notificamos la transacción realizada con tu Tarjeta Mastercard Local # 9675
      ''',
      );

      expect(result.bank, 'BHD');
      expect(result.lastFour, '9675');
      expect(result.transactions, hasLength(1));
      expect(result.transactions.single.amount, 369);
      expect(result.transactions.single.merchant, 'SUPERMERCADO FORTUNA');
      expect(result.transactions.single.categoryId, 'cat_food');
    });

    test('parses APAP plain numeric amount without using available balance', () {
      final result = parseBankEmail(
        from: 'HOLAPAP <no-reply@apap.com.do>',
        subject: 'APAP, Notificaciones',
        body: '''
        Tu tarjeta de Crédito titular-Visa Gold APAP terminada en 2552 presenta una transacción.
        Fecha: 02/09/2026
        Hora: 22:48
        Moneda: RD pesos dominicanos
        Monto: 373.29
        Comercio: PedidosYa*Barra Payan
        Estado: APROBADA
        Balance disponible: RD\$65,397.38
      ''',
      );

      expect(result.transactions, hasLength(1));
      expect(result.lastFour, '2552');
      expect(result.transactions.single.amount, 373.29);
      expect(result.transactions.single.merchant, 'PedidosYa*Barra Payan');
    });

    test('parses Banreservas approved consumption with values on next line', () {
      final result = parseBankEmail(
        from: 'notificaciones@banreservas.com',
        subject: 'Notificaciones Banreservas',
        body: '''
        Notificación de Consumo
        Su tarjeta ESTANDAR ••5949 presenta un consumo.
        Monto:
        DOP 325.00
        Estado:
        APROBADO
        Comercio:
        KAREN S EXQUISITECES SANTO DOMINGO DO
        Fecha de transacción:
        06/09/2026 19:33 PM
      ''',
      );

      expect(result.transactions, hasLength(1));
      expect(result.lastFour, '5949');
      expect(result.transactions.single.amount, 325);
    });

    test('recognizes a debit-card cash withdrawal', () {
      final result = parseBankEmail(
        from: 'BHD Alertas <alertas@bhd.com.do>',
        subject: 'BHD Notificación de Retiro',
        body: '''
        Tu tarjeta de débito terminada en 8141 presenta una transacción.
        Fecha: 09/09/2026
        Moneda: RD pesos dominicanos
        Monto: 2,000.00
        Comercio: CAJERO AUTOMATICO BHD
        Estado: APROBADA
        Tipo: Retiro en cajero
      ''',
      );

      expect(result.accountKind, BankAccountKind.debit);
      expect(result.transactions, hasLength(1));
      expect(result.transactions.single.kind, BankTransactionKind.withdrawal);
      expect(result.transactions.single.amount, 2000);
      expect(result.transactions.single.transactionType, TransactionType.expense);
    });

    test('recognizes a card payment without a purchase status field', () {
      final result = parseBankEmail(
        from: 'notificaciones@banreservas.com',
        subject: 'Notificaciones Banreservas - Pago de tarjeta',
        body: '''
        Pago de tarjeta confirmado
        Tarjeta terminada en 5949
        Monto: DOP 3,500.00
        Fecha: 10/09/2026
      ''',
      );

      expect(result.transactions, hasLength(1));
      expect(result.transactions.single.kind, BankTransactionKind.cardPayment);
      expect(result.transactions.single.amount, 3500);
    });

    test('treats a salary deposit as income', () {
      final result = parseBankEmail(
        from: 'notificaciones@banreservas.com',
        subject: 'Notificaciones Banreservas',
        body: '''
        Deposito de sueldo recibido
        Cuenta de ahorro terminada en 4410
        Monto: DOP 55,000.00
        Fecha: 30/09/2026
      ''',
      );

      expect(result.transactions, hasLength(1));
      expect(result.transactions.single.kind, BankTransactionKind.income);
      expect(result.transactions.single.transactionType, TransactionType.income);
      expect(result.transactions.single.categoryId, 'cat_salary');
    });

    test('supports another bank when its notification has structured fields', () {
      final result = parseBankEmail(
        from: 'alerts@examplebank.com',
        subject: 'Card transaction approved',
        body: '''
        Your debit card ending in 7788 was used.
        Date: 10/09/2026
        Currency: DOP
        Amount: 850.00
        Merchant: TEST MARKET
        Status: Approved
        Transaction type: Purchase
      ''',
      );

      expect(result.bank, 'Examplebank');
      expect(result.accountKind, BankAccountKind.debit);
      expect(result.transactions, hasLength(1));
      expect(result.transactions.single.amount, 850);
    });

    test('parses Banco Santa Cruz consumption with Lugar de transacción', () {
      final result = parseBankEmail(
        from: 'notificaciones@bsc.com.do',
        subject: 'Notificación, Banco Santa Cruz',
        body: '''
        Get Outlook for iOS
        From: notificaciones@bsc.com.do <notificaciones@bsc.com.do>
        Subject: Notificación, Banco Santa Cruz

        NOTIFICACIÓN DE CONSUMO

        Te notificamos que desde tu tarjeta de Crédito Clásica terminada en 1069 fue realizada la siguiente transacción:

        Monto: RD\$ 5,204.00
        Lugar de transacción: SM. BRAVO SAN VICENTE SANTO DOMINGODO
        Fecha y hora: 8/9/2026 21:07:08
        Estado: Aprobada
      ''',
      );

      expect(result.bank, 'Banco Santa Cruz');
      expect(result.lastFour, '1069');
      expect(result.accountKind, BankAccountKind.credit);
      expect(result.transactions, hasLength(1));
      expect(result.transactions.single.amount, 5204);
      expect(result.transactions.single.currency, 'DOP');
      expect(result.transactions.single.merchant, contains('BRAVO'));
      expect(result.transactions.single.categoryId, 'cat_food');
      expect(result.transactions.single.date, DateTime(2026, 9, 8, 21, 7, 8));
    });

    test('parses an unknown bank using generic field aliases', () {
      final result = parseBankEmail(
        from: 'alerts@ficticiobank.com',
        subject: 'Notificación de consumo',
        body: '''
        Tarjeta terminada en 4242
        Monto: RD\$ 80.00
        Lugar de transacción: SUPERMERCADO NACIONAL
        Fecha y hora: 8/9/2026 09:01:00
        Estado: Aprobada
      ''',
      );

      expect(result.bank, 'Ficticiobank');
      expect(result.lastFour, '4242');
      expect(result.transactions, hasLength(1));
      expect(result.transactions.single.amount, 80);
      expect(result.transactions.single.merchant, contains('NACIONAL'));
      expect(result.transactions.single.date.day, 8);
      expect(result.transactions.single.date.month, 9);
      expect(result.transactions.single.date.year, 2026);
    });

    test('parses Santa Cruz fields flattened onto one Outlook-style line', () {
      final result = parseBankEmail(
        from: 'Banco Santa Cruz <notificaciones@bsc.com.do>',
        subject: 'Notificación, Banco Santa Cruz',
        body:
            'NOTIFICACIÓN DE CONSUMO Te notificamos que desde tu tarjeta de '
            'Crédito Clásica terminada en 1069 fue realizada la siguiente '
            'transacción: Monto: RD\$ 5,204.00 Lugar de transacción: SM. BRAVO '
            'SAN VICENTE SANTO DOMINGODO Fecha y hora: 8/9/2026 21:07:08 '
            'Estado: Aprobada',
      );

      expect(result.bank, 'Banco Santa Cruz');
      expect(result.transactions, hasLength(1));
      expect(result.transactions.single.amount, 5204);
      expect(result.transactions.single.merchant, contains('BRAVO'));
      expect(result.transactions.single.merchant, isNot(contains('Fecha')));
      expect(result.transactions.single.date, DateTime(2026, 9, 8, 21, 7, 8));
    });

    test('skips a declined purchase', () {
      final result = parseBankEmail(
        from: 'alertas@bhd.com.do',
        subject: 'BHD Notificación de Transacciones',
        body: '''
        Tu tarjeta terminada en 9675 presenta una transacción.
        Fecha: 09/09/2026
        Moneda: RD
        Monto: 500.00
        Comercio: TIENDA X
        Estado: DECLINADA
      ''',
      );

      expect(result.transactions, isEmpty);
    });

    test('reads the sender from pasted headers when none is supplied', () {
      final result = parseBankEmail(
        body: '''
        From: BHD Alertas <alertas@bhd.com.do>
        Subject: Notificación de Transacciones
        Tu tarjeta terminada en 9675 presenta una transacción.
        Fecha: 09/09/2026
        Moneda: RD
        Monto: 100.00
        Comercio: TIENDA X
        Estado: APROBADA
      ''',
      );

      expect(result.bank, 'BHD');
      expect(result.transactions, hasLength(1));
    });
  });

  group('stated balance', () {
    test('captures the available balance separately from the amount', () {
      final result = parseBankEmail(
        from: 'HOLAPAP <no-reply@apap.com.do>',
        subject: 'APAP, Notificaciones',
        body: '''
        Tu tarjeta de Crédito titular-Visa Gold APAP terminada en 2552 presenta una transacción.
        Fecha: 02/09/2026
        Moneda: RD pesos dominicanos
        Monto: 373.29
        Comercio: PedidosYa*Barra Payan
        Estado: APROBADA
        Balance disponible: RD\$65,397.38
      ''',
      );

      expect(result.balance, isNotNull);
      expect(result.balance!.amount, 65397.38);
      expect(result.balance!.currency, 'DOP');
      expect(result.balance!.label.toLowerCase(), 'balance disponible');
      expect(result.transactions.single.amount, isNot(65397.38));
    });

    test('reads a balance written on the following line', () {
      final result = parseBankEmail(
        from: 'notificaciones@banreservas.com',
        subject: 'Notificaciones Banreservas',
        body: '''
        Su tarjeta ESTANDAR ••5949 presenta un consumo.
        Monto:
        DOP 325.00
        Estado:
        APROBADO
        Comercio:
        KAREN S EXQUISITECES
        Saldo disponible:
        DOP 12,004.55
      ''',
      );

      expect(result.balance!.amount, 12004.55);
      expect(result.transactions.single.amount, 325);
    });

    test('returns no balance when the email does not state one', () {
      final result = parseBankEmail(
        from: 'alertas@bhd.com.do',
        subject: 'BHD Notificación de Transacciones',
        body: '''
        Tu tarjeta terminada en 9675 presenta una transacción.
        Fecha: 09/09/2026
        Moneda: RD
        Monto: 369.00
        Comercio: SUPERMERCADO FORTUNA
        Estado: APROBADA
      ''',
      );

      expect(result.balance, isNull);
    });

    test('keeps the balance even when there is no usable transaction', () {
      final result = parseBankEmail(
        from: 'no-reply@apap.com.do',
        subject: 'APAP, Notificaciones',
        body: '''
        Estado de tu tarjeta terminada en 2552
        Balance actual: RD\$ 1,250.00
      ''',
      );

      expect(result.transactions, isEmpty);
      expect(result.balance!.amount, 1250);
      expect(result.issue, isNull);
    });

    test('does not confuse a US dollar balance for pesos', () {
      final result = parseBankEmail(
        from: 'no-reply@apap.com.do',
        subject: 'APAP, Notificaciones',
        body: '''
        Tarjeta terminada en 2552
        Balance disponible: US\$ 1.234,56
      ''',
      );

      expect(result.balance!.currency, 'USD');
      expect(result.balance!.amount, 1234.56);
    });
  });

  group('amount parsing', () {
    test('handles both thousand separator conventions', () {
      expect(parseBankAmount('1,234.56'), 1234.56);
      expect(parseBankAmount('1.234,56'), 1234.56);
      expect(parseBankAmount('RD\$369.00'), 369);
      expect(parseBankAmount('2,000.00'), 2000);
      expect(parseBankAmount('no digits here'), isNull);
    });
  });

  group('failure messages', () {
    test('reports when no card number is present', () {
      final result = parseBankEmail(
        from: 'alertas@bhd.com.do',
        subject: 'BHD Notificación',
        body: 'Tu transacción fue aprobada por RD\$100.00',
      );

      expect(result.issue, contains('No card'));
    });

    test('reports when the bank cannot be identified', () {
      final result = parseBankEmail(body: 'Some random text with no bank at all');

      expect(result.issue, contains('bank'));
    });
  });
}
