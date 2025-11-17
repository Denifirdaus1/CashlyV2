import '../../core/money.dart';

class SavingGroupMember {
  final String id;
  final String groupId;
  final String displayName;
  final Money? targetAmount;
  final DateTime createdAt;

  SavingGroupMember({
    required this.id,
    required this.groupId,
    required this.displayName,
    required this.createdAt,
    this.targetAmount,
  });
}
