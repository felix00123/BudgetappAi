/// A balance the bank stated in an alert email, kept as history.
///
/// Snapshots are never used to recompute an account balance; they are stored so
/// the app can chart how the bank-reported balance moved over time and flag when
/// it drifts from the balance derived from transactions.
class BalanceSnapshot {
  final String id;
  final String accountId;
  final double balance;
  final String currency;

  /// Label the email used, e.g. "Balance disponible".
  final String label;
  final DateTime capturedAt;
  final String source;
  final String? externalId;

  BalanceSnapshot({
    required this.id,
    required this.accountId,
    required this.balance,
    required this.currency,
    required this.label,
    required this.capturedAt,
    this.source = 'email',
    this.externalId,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'accountId': accountId,
        'balance': balance,
        'currency': currency,
        'label': label,
        'capturedAt': capturedAt.toIso8601String(),
        'source': source,
        'externalId': externalId,
      };

  factory BalanceSnapshot.fromJson(Map<String, dynamic> json) => BalanceSnapshot(
        id: json['id'] as String,
        accountId: json['accountId'] as String,
        balance: (json['balance'] as num).toDouble(),
        currency: json['currency'] as String? ?? 'DOP',
        label: json['label'] as String? ?? 'Balance',
        capturedAt: DateTime.parse(json['capturedAt'] as String),
        source: json['source'] as String? ?? 'email',
        externalId: json['externalId'] as String?,
      );

  BalanceSnapshot copyWith({
    String? accountId,
    double? balance,
    String? currency,
    String? label,
    DateTime? capturedAt,
    String? source,
    String? externalId,
  }) =>
      BalanceSnapshot(
        id: id,
        accountId: accountId ?? this.accountId,
        balance: balance ?? this.balance,
        currency: currency ?? this.currency,
        label: label ?? this.label,
        capturedAt: capturedAt ?? this.capturedAt,
        source: source ?? this.source,
        externalId: externalId ?? this.externalId,
      );
}
