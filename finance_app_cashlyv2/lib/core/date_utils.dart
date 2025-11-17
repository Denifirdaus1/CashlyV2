import 'package:intl/intl.dart';

class DateOnly {
  static final _formatter = DateFormat('yyyy-MM-dd');

  static String toDateString(DateTime date) => _formatter.format(date);

  static DateTime now() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }
}
