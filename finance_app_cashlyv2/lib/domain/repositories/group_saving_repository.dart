import '../../core/money.dart';
import '../enums.dart';
import '../models/group_member_summary.dart';
import '../models/group_summary.dart';
import '../models/saving_group.dart';
import '../models/saving_group_entry.dart';
import '../models/saving_group_member.dart';

abstract class GroupSavingRepository {
  Future<List<GroupSummary>> listGroupSummaries();

  Future<SavingGroup> createGroup({
    required String name,
    String? description,
    required Money targetTotal,
    DateTime? deadline,
  });

  Future<List<GroupMemberSummary>> listMemberSummaries(String groupId);

  Future<SavingGroupMember> addMember({
    required String groupId,
    required String displayName,
    Money? targetAmount,
    String? avatarUrl,
  });

  Future<SavingGroupMember> updateMember({
    required String memberId,
    String? displayName,
    Money? targetAmount,
    String? avatarUrl,
  });

  Future<void> deleteMember(String memberId);

  Future<List<SavingGroupEntry>> listEntries(String groupId);

  Future<SavingGroupEntry> addEntry({
    required String groupId,
    required String memberId,
    required DateTime transactionDate,
    required Money amount,
    required SavingEntryType type,
    String? note,
  });
}
