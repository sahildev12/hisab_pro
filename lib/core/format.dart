import 'package:decimal/decimal.dart';
import 'package:intl/intl.dart';

import 'money.dart';

final _indianWholeFormatter = NumberFormat('#,##,###', 'en_IN');
final _indianDecimalFormatter = NumberFormat('#,##,###.##', 'en_IN');

/// Whole-rupee monetary values (no decimals in display).
String formatMoney(Decimal value, {bool showCurrency = false}) {
  final whole = roundMoney(value);
  final formatted = _indianWholeFormatter.format(whole.toDouble());
  return showCurrency ? '₹$formatted' : formatted;
}

/// Bracket totals — decimals allowed.
String formatBracket(Decimal value) {
  final formatted = _indianDecimalFormatter.format(value.toDouble());
  return formatted;
}

/// Passing amount — decimals allowed.
String formatPassingAmount(Decimal value, {bool showCurrency = false}) {
  final formatted = _indianDecimalFormatter.format(value.toDouble());
  return showCurrency ? '₹$formatted' : formatted;
}

@Deprecated('Use formatMoney or formatBracket')
String formatIndianNumber(Decimal value, {bool showCurrency = false}) {
  final numeric = value.toDouble();
  final hasFraction = value % Decimal.one != Decimal.zero;
  final formatter =
      hasFraction ? _indianDecimalFormatter : _indianWholeFormatter;
  final formatted = formatter.format(numeric);
  return showCurrency ? '₹$formatted' : formatted;
}

String formatPlainNumber(Decimal value) {
  final text = value.toString();
  if (text.contains('.')) {
    return text.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
  }
  return text;
}

String formatRate(Decimal rate) {
  final plain = formatPlainNumber(rate);
  return '$plain%';
}

String formatHistoryDate(DateTime date) {
  final datePart = DateFormat('d MMM yyyy').format(date);
  final timePart = DateFormat('h:mm a').format(date);
  return '$datePart $timePart';
}

/// History card subtitle — date and time separated by a bullet.
String formatHistoryCardDate(DateTime date) {
  final datePart = DateFormat('d MMM yyyy').format(date);
  final timePart = DateFormat('h:mm a').format(date);
  return '$datePart • $timePart';
}
