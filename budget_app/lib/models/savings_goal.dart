class SavingsGoal {
  final String id;
  final String name;
  final double targetAmount;
  final double currentSaved;
  final DateTime createdAt;
  final String? icon;
  final String? note;

  SavingsGoal({
    required this.id,
    required this.name,
    required this.targetAmount,
    this.currentSaved = 0,
    required this.createdAt,
    this.icon,
    this.note,
  });

  double get progress => targetAmount > 0 ? (currentSaved / targetAmount).clamp(0, 1) : 0;
  double get remaining => (targetAmount - currentSaved).clamp(0, double.infinity);

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'targetAmount': targetAmount,
        'currentSaved': currentSaved,
        'createdAt': createdAt.toIso8601String(),
        'icon': icon,
        'note': note,
      };

  factory SavingsGoal.fromJson(Map<String, dynamic> json) => SavingsGoal(
        id: json['id'] as String,
        name: json['name'] as String,
        targetAmount: (json['targetAmount'] as num).toDouble(),
        currentSaved: (json['currentSaved'] as num?)?.toDouble() ?? 0,
        createdAt: DateTime.parse(json['createdAt'] as String),
        icon: json['icon'] as String?,
        note: json['note'] as String?,
      );

  SavingsGoal copyWith({
    String? name,
    double? targetAmount,
    double? currentSaved,
    String? icon,
    String? note,
  }) =>
      SavingsGoal(
        id: id,
        name: name ?? this.name,
        targetAmount: targetAmount ?? this.targetAmount,
        currentSaved: currentSaved ?? this.currentSaved,
        createdAt: createdAt,
        icon: icon ?? this.icon,
        note: note ?? this.note,
      );

  /// Months needed to reach goal at given monthly savings rate.
  int? monthsToReach(double monthlySavings) {
    if (monthlySavings <= 0) return null;
    if (remaining <= 0) return 0;
    return (remaining / monthlySavings).ceil();
  }

  DateTime? estimatedCompletionDate(double monthlySavings) {
    final months = monthsToReach(monthlySavings);
    if (months == null) return null;
    return DateTime.now().add(Duration(days: months * 30));
  }
}

const goalIcons = ['🚗', '🏠', '✈️', '💻', '🎓', '💍', '🏖️', '📱', '🎯', '💰'];
