class SavingGoal {
  const SavingGoal({
    required this.id,
    required this.accountId,
    required this.name,
    required this.targetAmount,
    required this.savedAmount,
    required this.targetDate,
    required this.isCompleted,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String? accountId;
  final String name;
  final int targetAmount;
  final int savedAmount;
  final DateTime? targetDate;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  double get progress {
    if (targetAmount <= 0) return 0;
    return (savedAmount / targetAmount).clamp(0, 1);
  }
}
