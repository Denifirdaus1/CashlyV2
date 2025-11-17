import '../../core/money.dart';

class PersonalGoalSummary {
  final String goalId;
  final String name;
  final Money targetAmount;
  final Money currentAmount;

  const PersonalGoalSummary({
    required this.goalId,
    required this.name,
    required this.targetAmount,
    required this.currentAmount,
  });

  double get progress {
    if (targetAmount.cents == 0) return 0;
    return (currentAmount.cents / targetAmount.cents).clamp(0, 1);
  }
}
