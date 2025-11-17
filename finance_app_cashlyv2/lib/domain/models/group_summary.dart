import '../../core/money.dart';

class GroupSummary {
  final String groupId;
  final String name;
  final Money targetTotal;
  final Money totalContributed;
  final int memberCount;

  const GroupSummary({
    required this.groupId,
    required this.name,
    required this.targetTotal,
    required this.totalContributed,
    required this.memberCount,
  });

  double get progress {
    if (targetTotal.cents == 0) return 0;
    return (totalContributed.cents / targetTotal.cents).clamp(0, 1);
  }
}
