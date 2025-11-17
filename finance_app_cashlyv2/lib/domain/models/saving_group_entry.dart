import '../../core/money.dart';
import '../enums.dart';

class SavingGroupEntry {
  final String id;
  final String groupId;
  final String memberId;
  final DateTime transactionDate;
  final Money amount;
  final SavingEntryType type;
  final String? note;
  final DateTime createdAt;

  SavingGroupEntry({
    required this.id,
    required this.groupId,
    required this.memberId,
    required this.transactionDate,
    required this.amount,
    required this.type,
    required this.createdAt,
    this.note,
  });
}
