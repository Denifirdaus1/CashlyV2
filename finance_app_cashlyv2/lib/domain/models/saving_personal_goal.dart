import '../../core/money.dart';

class SavingPersonalGoal {
  final String id;
  final String name;
  final String? description;
  final Money targetAmount;
  final DateTime? deadline;
  final DateTime createdAt;

  SavingPersonalGoal({
    required this.id,
    required this.name,
    required this.targetAmount,
    required this.createdAt,
    this.description,
    this.deadline,
  });
}
