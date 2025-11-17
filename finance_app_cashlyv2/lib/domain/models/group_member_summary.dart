import '../../core/money.dart';

class GroupMemberSummary {
  final String memberId;
  final String groupId;
  final String displayName;
  final Money? targetAmount;
  final Money totalContributed;

  const GroupMemberSummary({
    required this.memberId,
    required this.groupId,
    required this.displayName,
    required this.totalContributed,
    this.targetAmount,
  });
}
