import '../../core/money.dart';
import '../enums.dart';

class CashTransaction {
  final String id;
  final DateTime transactionDate;
  final Money amount;
  final CashTransactionType type;
  final String? categoryId;
  final String? note;
  final DateTime createdAt;

  CashTransaction({
    required this.id,
    required this.transactionDate,
    required this.amount,
    required this.type,
    required this.createdAt,
    this.categoryId,
    this.note,
  });
}
