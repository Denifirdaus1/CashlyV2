import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/date_utils.dart';
import '../../core/money.dart';
import '../../domain/enums.dart';
import '../../domain/models/group_member_summary.dart';
import '../../domain/models/group_summary.dart';
import '../../domain/models/saving_group.dart';
import '../../domain/models/saving_group_entry.dart';
import '../../domain/models/saving_group_member.dart';
import '../../domain/repositories/group_saving_repository.dart';

class SupabaseGroupSavingRepository implements GroupSavingRepository {
  final SupabaseClient _client;

  SupabaseGroupSavingRepository(this._client);

  @override
  Future<SavingGroup> createGroup({
    required String name,
    String? description,
    required Money targetTotal,
    DateTime? deadline,
  }) async {
    final payload = {
      'name': name,
      'description': description,
      'target_total_cents': targetTotal.cents,
      'deadline': deadline != null ? DateOnly.toDateString(deadline) : null,
    };

    final rows = await _client
        .from('saving_groups')
        .insert(payload)
        .select()
        .limit(1) as List<dynamic>;

    return _mapGroup(rows.first as Map<String, dynamic>);
  }

  @override
  Future<List<GroupSummary>> listGroupSummaries() async {
    final rows = await _client
        .from('vw_saving_group_summary')
        .select()
        .order('name') as List<dynamic>;

    return rows.map((row) => _mapGroupSummary(row as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<GroupMemberSummary>> listMemberSummaries(String groupId) async {
    final rows = await _client
        .from('vw_saving_group_member_summary')
        .select()
        .eq('group_id', groupId)
        .order('display_name') as List<dynamic>;

    return rows
        .map((row) => _mapMemberSummary(row as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<SavingGroupMember> addMember({
    required String groupId,
    required String displayName,
    Money? targetAmount,
  }) async {
    final payload = {
      'group_id': groupId,
      'display_name': displayName,
      'target_amount_cents': targetAmount?.cents,
    };

    final rows = await _client
        .from('saving_group_members')
        .insert(payload)
        .select()
        .limit(1) as List<dynamic>;

    return _mapMember(rows.first as Map<String, dynamic>);
  }

  @override
  Future<List<SavingGroupEntry>> listEntries(String groupId) async {
    final rows = await _client
        .from('saving_group_entries')
        .select()
        .eq('group_id', groupId)
        .filter('deleted_at', 'is', null)
        .order('transaction_date', ascending: false)
        .order('created_at', ascending: false) as List<dynamic>;

    return rows.map((row) => _mapEntry(row as Map<String, dynamic>)).toList();
  }

  @override
  Future<SavingGroupEntry> addEntry({
    required String groupId,
    required String memberId,
    required DateTime transactionDate,
    required Money amount,
    required SavingEntryType type,
    String? note,
  }) async {
    final payload = {
      'group_id': groupId,
      'member_id': memberId,
      'transaction_date': DateOnly.toDateString(transactionDate),
      'amount_cents': amount.cents,
      'type': type.name,
      'note': note,
    };

    final rows = await _client
        .from('saving_group_entries')
        .insert(payload)
        .select()
        .limit(1) as List<dynamic>;

    return _mapEntry(rows.first as Map<String, dynamic>);
  }

  GroupSummary _mapGroupSummary(Map<String, dynamic> row) {
    return GroupSummary(
      groupId: row['group_id'] as String,
      name: row['name'] as String,
      targetTotal: Money(row['target_total_cents'] as int? ?? 0),
      totalContributed: Money(row['total_contributed_cents'] as int? ?? 0),
      memberCount: row['member_count'] as int? ?? 0,
    );
  }

  SavingGroup _mapGroup(Map<String, dynamic> row) {
    return SavingGroup(
      id: row['id'] as String,
      name: row['name'] as String,
      description: row['description'] as String?,
      targetTotal: Money(row['target_total_cents'] as int? ?? 0),
      deadline: row['deadline'] != null
          ? DateTime.parse(row['deadline'] as String)
          : null,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }

  GroupMemberSummary _mapMemberSummary(Map<String, dynamic> row) {
    return GroupMemberSummary(
      memberId: row['member_id'] as String,
      groupId: row['group_id'] as String,
      displayName: row['display_name'] as String,
      targetAmount: row['target_amount_cents'] != null
          ? Money(row['target_amount_cents'] as int)
          : null,
      totalContributed: Money(row['total_contributed_cents'] as int? ?? 0),
    );
  }

  SavingGroupMember _mapMember(Map<String, dynamic> row) {
    return SavingGroupMember(
      id: row['id'] as String,
      groupId: row['group_id'] as String,
      displayName: row['display_name'] as String,
      targetAmount: row['target_amount_cents'] != null
          ? Money(row['target_amount_cents'] as int)
          : null,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }

  SavingGroupEntry _mapEntry(Map<String, dynamic> row) {
    final typeStr = row['type'] as String? ?? 'deposit';
    final type = typeStr == SavingEntryType.withdraw.name
        ? SavingEntryType.withdraw
        : SavingEntryType.deposit;

    return SavingGroupEntry(
      id: row['id'] as String,
      groupId: row['group_id'] as String,
      memberId: row['member_id'] as String,
      transactionDate: DateTime.parse(row['transaction_date'] as String),
      amount: Money(row['amount_cents'] as int? ?? 0),
      type: type,
      note: row['note'] as String?,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }
}
