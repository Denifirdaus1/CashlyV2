import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/supabase_client.dart';
import '../domain/models/cash_rollup.dart';
import '../domain/models/cash_transaction.dart';
import '../domain/models/group_member_summary.dart';
import '../domain/models/group_summary.dart';
import '../domain/models/personal_goal_summary.dart';
import '../domain/models/saving_group_entry.dart';
import '../domain/models/saving_personal_entry.dart';
import '../domain/repositories/cash_repository.dart';
import '../domain/repositories/group_saving_repository.dart';
import '../domain/repositories/personal_saving_repository.dart';
import '../infrastructure/supabase/supabase_cash_repository.dart';
import '../infrastructure/supabase/supabase_group_saving_repository.dart';
import '../infrastructure/supabase/supabase_personal_saving_repository.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return SupabaseManager.client;
});

final cashRepositoryProvider = Provider<CashRepository>((ref) {
  return SupabaseCashRepository(ref.watch(supabaseClientProvider));
});

final personalSavingRepositoryProvider =
    Provider<PersonalSavingRepository>((ref) {
  return SupabasePersonalSavingRepository(ref.watch(supabaseClientProvider));
});

final groupSavingRepositoryProvider = Provider<GroupSavingRepository>((ref) {
  return SupabaseGroupSavingRepository(ref.watch(supabaseClientProvider));
});

class HomeModeNotifier extends Notifier<HomeMode> {
  @override
  HomeMode build() => HomeMode.cashflow;

  void setMode(HomeMode mode) => state = mode;
}

final homeModeProvider = NotifierProvider<HomeModeNotifier, HomeMode>(HomeModeNotifier.new);

enum HomeMode { cashflow, savings }

final cashTransactionsProvider = FutureProvider<List<CashTransaction>>((ref) {
  return ref.watch(cashRepositoryProvider).fetchRecentTransactions(limit: 50);
});

final cashRollupProvider = FutureProvider<CashRollup>((ref) {
  return ref.watch(cashRepositoryProvider).fetchRollup();
});

final personalGoalsProvider =
    FutureProvider<List<PersonalGoalSummary>>((ref) async {
  return ref.watch(personalSavingRepositoryProvider).listGoalSummaries();
});

final personalGoalEntriesProvider =
    FutureProvider.family<List<SavingPersonalEntry>, String>((ref, goalId) {
  return ref.watch(personalSavingRepositoryProvider).listEntries(goalId);
});

final groupSummariesProvider =
    FutureProvider<List<GroupSummary>>((ref) async {
  return ref.watch(groupSavingRepositoryProvider).listGroupSummaries();
});

final groupMemberSummariesProvider = FutureProvider.family<
    List<GroupMemberSummary>, String>((ref, groupId) {
  return ref.watch(groupSavingRepositoryProvider).listMemberSummaries(groupId);
});

final groupEntriesProvider =
    FutureProvider.family<List<SavingGroupEntry>, String>((ref, groupId) {
  return ref.watch(groupSavingRepositoryProvider).listEntries(groupId);
});
