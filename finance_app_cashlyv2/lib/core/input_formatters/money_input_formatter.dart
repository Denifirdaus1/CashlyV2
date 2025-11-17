import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Simple formatter to insert thousand separators while typing whole numbers.
class MoneyInputFormatter extends TextInputFormatter {
  final NumberFormat _formatter = NumberFormat.decimalPattern('id_ID');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return newValue.copyWith(text: '');
    }

    final number = int.parse(digits);
    final newString = _formatter.format(number);
    return TextEditingValue(
      text: newString,
      selection: TextSelection.collapsed(offset: newString.length),
    );
  }
}
