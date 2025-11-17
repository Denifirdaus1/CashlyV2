import 'cash_summary.dart';

class CashRollup {
  final CashSummary today;
  final CashSummary month;

  const CashRollup({
    required this.today,
    required this.month,
  });

  static const empty = CashRollup(
    today: CashSummary.zero,
    month: CashSummary.zero,
  );
}
