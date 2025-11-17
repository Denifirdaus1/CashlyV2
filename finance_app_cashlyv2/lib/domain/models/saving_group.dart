import '../../core/money.dart';

class SavingGroup {
  final String id;
  final String name;
  final String? description;
  final Money targetTotal;
  final DateTime? deadline;
  final DateTime createdAt;

  SavingGroup({
    required this.id,
    required this.name,
    required this.targetTotal,
    required this.createdAt,
    this.description,
    this.deadline,
  });
}
