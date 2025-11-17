import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/date_utils.dart';
import '../../core/money.dart';
import '../../domain/enums.dart';
import '../../domain/models/cash_rollup.dart';
import '../../domain/models/cash_summary.dart';
import '../../domain/models/cash_transaction.dart';
import '../../domain/repositories/cash_repository.dart';

class SupabaseCashRepository implements CashRepository {
  final SupabaseClient _client;

  SupabaseCashRepository(this._client);

  @override
  Future<void> addTransaction({
    required DateTime transactionDate,
    required Money amount,
    required CashTransactionType type,
    String? categoryId,
    String? categoryName,
    String? note,
    DateTime? now,
  }) async {
    final resolvedCategoryId = categoryId ??
        (categoryName != null && categoryName.isNotEmpty
            ? await _resolveCategoryId(categoryName, type)
            : null);

    final payload = {
      'transaction_date': DateOnly.toDateString(transactionDate),
      'amount_cents': amount.cents,
      'type': type.name,
      'category_id': resolvedCategoryId,
      'note': note,
      'created_at': (now ?? DateTime.now()).toIso8601String(),
    };

    await _client.from('cash_transactions').insert(payload);
  }

  @override
  Future<List<CashTransaction>> fetchRecentTransactions({int limit = 50}) async {
    final rows = await _client
        .from('cash_transactions')
        .select()
        .filter('deleted_at', 'is', null)
        .order('transaction_date', ascending: false)
        .order('created_at', ascending: false)
        .limit(limit) as List<dynamic>;

    return rows.map((row) => _mapTransaction(row as Map<String, dynamic>)).toList();
  }

  @override
  Future<CashRollup> fetchRollup({DateTime? today}) async {
    final now = today ?? DateOnly.now();
    final startOfMonth = DateTime(now.year, now.month, 1);

    final rows = await _client
        .from('cash_transactions')
        .select('transaction_date, amount_cents, type')
        .filter('deleted_at', 'is', null)
        .gte('transaction_date', DateOnly.toDateString(startOfMonth))
        .lte('transaction_date', DateOnly.toDateString(now)) as List<dynamic>;

    int todayIncome = 0;
    int todayExpense = 0;
    int monthIncome = 0;
    int monthExpense = 0;

    for (final dynamicRow in rows) {
      final row = dynamicRow as Map<String, dynamic>;
      final date = DateTime.parse(row['transaction_date'] as String);
      final amount = row['amount_cents'] as int? ?? 0;
      final typeStr = row['type'] as String? ?? 'expense';
      final isIncome = typeStr == CashTransactionType.income.name;

      final isToday =
          date.year == now.year && date.month == now.month && date.day == now.day;
      final isThisMonth = date.isAfter(startOfMonth.subtract(const Duration(days: 1)));

      if (isThisMonth) {
        if (isIncome) {
          monthIncome += amount;
        } else {
          monthExpense += amount;
        }
      }

      if (isToday) {
        if (isIncome) {
          todayIncome += amount;
        } else {
          todayExpense += amount;
        }
      }
    }

    return CashRollup(
      today: CashSummary(
        totalIncome: Money(todayIncome),
        totalExpense: Money(todayExpense),
      ),
      month: CashSummary(
        totalIncome: Money(monthIncome),
        totalExpense: Money(monthExpense),
      ),
    );
  }

  Future<String?> _resolveCategoryId(
    String categoryName,
    CashTransactionType type,
  ) async {
    final existing = await _client
        .from('cash_categories')
        .select()
        .eq('name', categoryName)
        .eq('type', type.name)
        .limit(1) as List<dynamic>;

    if (existing.isNotEmpty) {
      return (existing.first as Map<String, dynamic>)['id'] as String?;
    }

    final inserted = await _client
        .from('cash_categories')
        .insert({
          'name': categoryName,
          'type': type.name,
        })
        .select()
        .limit(1) as List<dynamic>;

    return (inserted.first as Map<String, dynamic>)['id'] as String?;
  }

  CashTransaction _mapTransaction(Map<String, dynamic> row) {
    final typeStr = row['type'] as String? ?? 'expense';
    final type = typeStr == CashTransactionType.income.name
        ? CashTransactionType.income
        : CashTransactionType.expense;

    return CashTransaction(
      id: row['id'] as String,
      transactionDate: DateTime.parse(row['transaction_date'] as String),
      amount: Money(row['amount_cents'] as int? ?? 0),
      type: type,
      categoryId: row['category_id'] as String?,
      note: row['note'] as String?,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }
}
