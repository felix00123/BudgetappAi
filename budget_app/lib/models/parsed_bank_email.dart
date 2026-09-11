import '../services/bank_email_parser.dart';

/// A bank alert email already parsed, ready to import into the budget store.
class ParsedBankEmail {
  const ParsedBankEmail({
    required this.messageId,
    required this.result,
    this.receivedAt,
  });

  final String messageId;
  final BankEmailResult result;
  final DateTime? receivedAt;
}

/// Result of importing parsed bank emails from Gmail or Outlook.
class EmailImportSummary {
  const EmailImportSummary({
    required this.messagesChecked,
    required this.emailsParsed,
    required this.transactionsSaved,
    required this.balancesSaved,
    required this.accountsCreated,
    required this.message,
  });

  final int messagesChecked;
  final int emailsParsed;
  final int transactionsSaved;
  final int balancesSaved;
  final int accountsCreated;
  final String message;
}
