import '../../core/money.dart';

class CashSummary {
  final Money totalIncome;
  final Money totalExpense;

  const CashSummary({
    required this.totalIncome,
    required this.totalExpense,
  });

  Money get balance => totalIncome - totalExpense;

  static const zero = CashSummary(
    totalIncome: Money(0),
    totalExpense: Money(0),
  );
}
