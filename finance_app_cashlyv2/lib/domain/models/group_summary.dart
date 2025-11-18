import '../../core/money.dart';

class GroupSummary {
  final String groupId;
  final String name;
  final Money targetTotal;
  final Money totalContributed;
  final int memberCount;
  final String? avatarUrl;

  const GroupSummary({
    required this.groupId,
    required this.name,
    required this.targetTotal,
    required this.totalContributed,
    required this.memberCount,
    this.avatarUrl,
  });

  double get progress {
    if (targetTotal.cents == 0) return 0;
    return (totalContributed.cents / targetTotal.cents).clamp(0, 1);
  }
}
