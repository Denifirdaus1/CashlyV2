import '../../core/money.dart';
import '../enums.dart';
import '../models/cash_rollup.dart';
import '../models/cash_transaction.dart';

abstract class CashRepository {
  Future<List<CashTransaction>> fetchRecentTransactions({int limit = 50});

  Future<CashRollup> fetchRollup({DateTime? today});

  Future<void> addTransaction({
    required DateTime transactionDate,
    required Money amount,
    required CashTransactionType type,
    String? categoryId,
    String? categoryName,
    String? note,
    DateTime? now,
  });
}
