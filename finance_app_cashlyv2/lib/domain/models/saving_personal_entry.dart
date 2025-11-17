import '../../core/money.dart';
import '../enums.dart';

class SavingPersonalEntry {
  final String id;
  final String goalId;
  final DateTime transactionDate;
  final Money amount;
  final SavingEntryType type;
  final String? note;
  final DateTime createdAt;

  SavingPersonalEntry({
    required this.id,
    required this.goalId,
    required this.transactionDate,
    required this.amount,
    required this.type,
    required this.createdAt,
    this.note,
  });
}
