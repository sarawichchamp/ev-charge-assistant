import 'package:intl/intl.dart';

class Formatters {
  static final _currency = NumberFormat('0.00');
  static final _kwh = NumberFormat('0.0#');
  static final _odometer = NumberFormat('#,###');
  static final _time = DateFormat('HH:mm');
  static final _dateTime = DateFormat('yyyy-MM-dd HH:mm');

  static String currency(num value) => _currency.format(value);
  static String kwh(num value) => _kwh.format(value);
  static String odometer(num value) => _odometer.format(value);
  static String time(DateTime value) => _time.format(value);
  static String dateTime(DateTime value) => _dateTime.format(value);
}
