import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/date_utils.dart';
import '../../core/money.dart';
import '../../domain/enums.dart';
import '../../domain/models/personal_goal_summary.dart';
import '../../domain/models/saving_personal_entry.dart';
import '../../domain/models/saving_personal_goal.dart';
import '../../domain/repositories/personal_saving_repository.dart';

class SupabasePersonalSavingRepository implements PersonalSavingRepository {
  final SupabaseClient _client;

  SupabasePersonalSavingRepository(this._client);

  @override
  Future<SavingPersonalGoal> createGoal({
    required String name,
    String? description,
    required Money targetAmount,
    DateTime? deadline,
  }) async {
    final payload = {
      'name': name,
      'description': description,
      'target_amount_cents': targetAmount.cents,
      'deadline': deadline != null ? DateOnly.toDateString(deadline) : null,
    };

    final rows = await _client
        .from('saving_personal_goals')
        .insert(payload)
        .select()
        .limit(1) as List<dynamic>;

    return _mapGoal(rows.first as Map<String, dynamic>);
  }

  @override
  Future<List<PersonalGoalSummary>> listGoalSummaries() async {
    final rows = await _client
        .from('vw_saving_personal_goal_summary')
        .select()
        .order('name') as List<dynamic>;

    return rows.map((row) => _mapGoalSummary(row as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<SavingPersonalEntry>> listEntries(String goalId) async {
    final rows = await _client
        .from('saving_personal_entries')
        .select()
        .eq('goal_id', goalId)
        .filter('deleted_at', 'is', null)
        .order('transaction_date', ascending: false)
        .order('created_at', ascending: false) as List<dynamic>;

    return rows.map((row) => _mapEntry(row as Map<String, dynamic>)).toList();
  }

  @override
  Future<SavingPersonalEntry> addEntry({
    required String goalId,
    required DateTime transactionDate,
    required Money amount,
    required SavingEntryType type,
    String? note,
  }) async {
    final payload = {
      'goal_id': goalId,
      'transaction_date': DateOnly.toDateString(transactionDate),
      'amount_cents': amount.cents,
      'type': type.name,
      'note': note,
    };

    final rows = await _client
        .from('saving_personal_entries')
        .insert(payload)
        .select()
        .limit(1) as List<dynamic>;

    return _mapEntry(rows.first as Map<String, dynamic>);
  }

  SavingPersonalGoal _mapGoal(Map<String, dynamic> row) {
    return SavingPersonalGoal(
      id: row['id'] as String,
      name: row['name'] as String,
      description: row['description'] as String?,
      targetAmount: Money(row['target_amount_cents'] as int? ?? 0),
      deadline: row['deadline'] != null
          ? DateTime.parse(row['deadline'] as String)
          : null,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }

  PersonalGoalSummary _mapGoalSummary(Map<String, dynamic> row) {
    return PersonalGoalSummary(
      goalId: row['goal_id'] as String,
      name: row['name'] as String,
      targetAmount: Money(row['target_amount_cents'] as int? ?? 0),
      currentAmount: Money(row['current_amount_cents'] as int? ?? 0),
    );
  }

  SavingPersonalEntry _mapEntry(Map<String, dynamic> row) {
    final typeStr = row['type'] as String? ?? 'deposit';
    final type = typeStr == SavingEntryType.withdraw.name
        ? SavingEntryType.withdraw
        : SavingEntryType.deposit;

    return SavingPersonalEntry(
      id: row['id'] as String,
      goalId: row['goal_id'] as String,
      transactionDate: DateTime.parse(row['transaction_date'] as String),
      amount: Money(row['amount_cents'] as int? ?? 0),
      type: type,
      note: row['note'] as String?,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }
}
