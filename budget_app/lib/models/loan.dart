import 'dart:math';

/// A single row in an amortization schedule.
class AmortizationRow {
  const AmortizationRow({
    required this.installment,
    required this.date,
    required this.payment,
    required this.interest,
    required this.principal,
    required this.balance,
  });

  final int installment;
  final DateTime date;
  final double payment;
  final double interest;
  final double principal;
  final double balance;
}

class Loan {
  const Loan({
    required this.id,
    required this.name,
    required this.principal,
    required this.annualInterestRate,
    required this.termMonths,
    required this.startDate,
    required this.remainingBalance,
    required this.createdAt,
    this.extraMonthlyPayment = 0,
    this.monthlyPaymentOverride,
    this.totalInterestPaid = 0,
    this.paymentsMade = 0,
    this.icon,
    this.note,
  });

  final String id;
  final String name;
  final double principal;
  /// Annual rate as a percentage (e.g. 6.5 for 6.5%).
  final double annualInterestRate;
  final int termMonths;
  final DateTime startDate;
  final double remainingBalance;
  final double extraMonthlyPayment;
  final double? monthlyPaymentOverride;
  final double totalInterestPaid;
  final int paymentsMade;
  final DateTime createdAt;
  final String? icon;
  final String? note;

  double get monthlyInterestRate => annualInterestRate / 100 / 12;

  double get calculatedMonthlyPayment =>
      calculateMonthlyPayment(principal, annualInterestRate, termMonths);

  double get monthlyPayment => monthlyPaymentOverride ?? calculatedMonthlyPayment;

  double get totalMonthlyPayment => monthlyPayment + extraMonthlyPayment;

  double get amountPaidOff =>
      (principal - remainingBalance).clamp(0, double.infinity);

  double get progress =>
      principal > 0 ? (amountPaidOff / principal).clamp(0, 1) : 0;

  bool get isPaidOff => remainingBalance <= 0.01;

  int? get monthsRemaining {
    if (isPaidOff) return 0;
    return estimateMonthsRemaining(
      balance: remainingBalance,
      annualRate: annualInterestRate,
      monthlyPayment: totalMonthlyPayment,
    );
  }

  DateTime? get estimatedPayoffDate {
    final months = monthsRemaining;
    if (months == null) return null;
    return _addMonths(DateTime.now(), months);
  }

  List<AmortizationRow> amortizationSchedule({int maxMonths = 360}) {
    return buildAmortizationSchedule(
      balance: remainingBalance,
      annualRate: annualInterestRate,
      monthlyPayment: monthlyPayment,
      extraPayment: extraMonthlyPayment,
      startFrom: DateTime.now(),
      maxMonths: maxMonths,
    );
  }

  /// Full original schedule from loan start (for reference).
  List<AmortizationRow> originalSchedule({int maxMonths = 360}) {
    return buildAmortizationSchedule(
      balance: principal,
      annualRate: annualInterestRate,
      monthlyPayment: calculatedMonthlyPayment,
      extraPayment: extraMonthlyPayment,
      startFrom: startDate,
      maxMonths: maxMonths,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'principal': principal,
        'annualInterestRate': annualInterestRate,
        'termMonths': termMonths,
        'startDate': startDate.toIso8601String(),
        'remainingBalance': remainingBalance,
        'extraMonthlyPayment': extraMonthlyPayment,
        'monthlyPaymentOverride': monthlyPaymentOverride,
        'totalInterestPaid': totalInterestPaid,
        'paymentsMade': paymentsMade,
        'createdAt': createdAt.toIso8601String(),
        'icon': icon,
        'note': note,
      };

  factory Loan.fromJson(Map<String, dynamic> json) => Loan(
        id: json['id'] as String,
        name: json['name'] as String,
        principal: (json['principal'] as num).toDouble(),
        annualInterestRate: (json['annualInterestRate'] as num).toDouble(),
        termMonths: json['termMonths'] as int,
        startDate: DateTime.parse(json['startDate'] as String),
        remainingBalance: (json['remainingBalance'] as num).toDouble(),
        extraMonthlyPayment:
            (json['extraMonthlyPayment'] as num?)?.toDouble() ?? 0,
        monthlyPaymentOverride:
            (json['monthlyPaymentOverride'] as num?)?.toDouble(),
        totalInterestPaid: (json['totalInterestPaid'] as num?)?.toDouble() ?? 0,
        paymentsMade: json['paymentsMade'] as int? ?? 0,
        createdAt: DateTime.parse(json['createdAt'] as String),
        icon: json['icon'] as String?,
        note: json['note'] as String?,
      );

  Loan copyWith({
    String? name,
    double? principal,
    double? annualInterestRate,
    int? termMonths,
    DateTime? startDate,
    double? remainingBalance,
    double? extraMonthlyPayment,
    double? monthlyPaymentOverride,
    bool clearMonthlyPaymentOverride = false,
    double? totalInterestPaid,
    int? paymentsMade,
    String? icon,
    String? note,
  }) =>
      Loan(
        id: id,
        name: name ?? this.name,
        principal: principal ?? this.principal,
        annualInterestRate: annualInterestRate ?? this.annualInterestRate,
        termMonths: termMonths ?? this.termMonths,
        startDate: startDate ?? this.startDate,
        remainingBalance: remainingBalance ?? this.remainingBalance,
        extraMonthlyPayment: extraMonthlyPayment ?? this.extraMonthlyPayment,
        monthlyPaymentOverride: clearMonthlyPaymentOverride
            ? null
            : (monthlyPaymentOverride ?? this.monthlyPaymentOverride),
        totalInterestPaid: totalInterestPaid ?? this.totalInterestPaid,
        paymentsMade: paymentsMade ?? this.paymentsMade,
        createdAt: createdAt,
        icon: icon ?? this.icon,
        note: note ?? this.note,
      );
}

const loanIcons = ['🏠', '🚗', '🎓', '💳', '🏦', '📋', '💼', '🛵'];

double calculateMonthlyPayment(
  double principal,
  double annualRate,
  int termMonths,
) {
  if (termMonths <= 0 || principal <= 0) return 0;
  if (annualRate <= 0) return principal / termMonths;

  final r = annualRate / 100 / 12;
  final factor = pow(1 + r, termMonths).toDouble();
  return principal * r * factor / (factor - 1);
}

int? estimateMonthsRemaining({
  required double balance,
  required double annualRate,
  required double monthlyPayment,
  int maxMonths = 600,
}) {
  if (balance <= 0.01) return 0;
  if (monthlyPayment <= 0) return null;

  final r = annualRate / 100 / 12;
  if (r == 0) {
    return (balance / monthlyPayment).ceil();
  }

  var remaining = balance;
  var months = 0;
  while (remaining > 0.01 && months < maxMonths) {
    final interest = remaining * r;
    if (monthlyPayment <= interest) return null;
    final principalPart = monthlyPayment - interest;
    remaining -= principalPart;
    months++;
  }
  return months;
}

List<AmortizationRow> buildAmortizationSchedule({
  required double balance,
  required double annualRate,
  required double monthlyPayment,
  required double extraPayment,
  required DateTime startFrom,
  int maxMonths = 360,
}) {
  if (balance <= 0) return [];

  final rows = <AmortizationRow>[];
  var remaining = balance;
  final r = annualRate / 100 / 12;
  var date = DateTime(startFrom.year, startFrom.month, startFrom.day);
  var installment = 1;

  while (remaining > 0.01 && installment <= maxMonths) {
    final interest = remaining * r;
    var payment = monthlyPayment + extraPayment;
    if (payment <= interest && monthlyPayment > 0) {
      payment = monthlyPayment;
    }

    var principalPart = payment - interest;
    if (principalPart > remaining) {
      principalPart = remaining;
      payment = interest + principalPart;
    } else if (principalPart < 0) {
      principalPart = 0;
      payment = interest;
    }

    remaining -= principalPart;
    rows.add(
      AmortizationRow(
        installment: installment,
        date: date,
        payment: payment,
        interest: interest,
        principal: principalPart,
        balance: remaining.clamp(0, double.infinity),
      ),
    );

    date = _addMonths(date, 1);
    installment++;
  }

  return rows;
}

/// Applies a payment using standard amortization (interest first, then principal).
Loan applyPayment(Loan loan, double amount) {
  if (amount <= 0 || loan.isPaidOff) return loan;

  final interest = loan.remainingBalance * loan.monthlyInterestRate;
  final interestPaid = min(amount, interest);
  final principalPaid = min(amount - interestPaid, loan.remainingBalance);
  final newBalance = loan.remainingBalance - principalPaid;

  return loan.copyWith(
    remainingBalance: newBalance < 0.01 ? 0 : newBalance,
    totalInterestPaid: loan.totalInterestPaid + interestPaid,
    paymentsMade: loan.paymentsMade + 1,
  );
}

DateTime _addMonths(DateTime date, int months) {
  final month = date.month - 1 + months;
  final year = date.year + month ~/ 12;
  final newMonth = month % 12 + 1;
  final day = min(date.day, _daysInMonth(year, newMonth));
  return DateTime(year, newMonth, day);
}

int _daysInMonth(int year, int month) {
  return DateTime(year, month + 1, 0).day;
}
