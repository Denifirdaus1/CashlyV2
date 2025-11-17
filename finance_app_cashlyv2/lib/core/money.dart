import 'package:intl/intl.dart';

class Money {
  final int cents;
  const Money(this.cents);

  double get value => cents / 100;

  String format({String locale = 'id_ID', String symbol = 'Rp'}) {
    final formatter = NumberFormat.currency(
      locale: locale,
      symbol: '$symbol ',
      decimalDigits: 0,
    );
    return formatter.format(value);
  }

  Money operator +(Money other) => Money(cents + other.cents);

  Money operator -(Money other) => Money(cents - other.cents);

  static Money fromDouble(double value) => Money((value * 100).round());

  static const Money zero = Money(0);

  static Money fromFormatted(String input) {
    final digits = input.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return Money.zero;
    return Money(int.parse(digits) * 100);
  }
}
