import '../../core/money.dart';
import '../enums.dart';
import '../models/personal_goal_summary.dart';
import '../models/saving_personal_entry.dart';
import '../models/saving_personal_goal.dart';

abstract class PersonalSavingRepository {
  Future<List<PersonalGoalSummary>> listGoalSummaries();

  Future<SavingPersonalGoal> createGoal({
    required String name,
    String? description,
    required Money targetAmount,
    DateTime? deadline,
  });

  Future<SavingPersonalGoal> updateGoal({
    required String goalId,
    String? name,
    String? description,
    Money? targetAmount,
    DateTime? deadline,
  });

  Future<void> deleteGoal(String goalId);

  Future<List<SavingPersonalEntry>> listEntries(String goalId);

  Future<SavingPersonalEntry> addEntry({
    required String goalId,
    required DateTime transactionDate,
    required Money amount,
    required SavingEntryType type,
    String? note,
  });
}
