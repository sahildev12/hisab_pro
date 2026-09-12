import 'package:decimal/decimal.dart';
import 'package:intl/intl.dart';

final _indianFormatter = NumberFormat('#,##,###.##', 'en_IN');

String formatIndianNumber(Decimal value, {bool showCurrency = false}) {
  final numeric = value.toDouble();
  final formatted = _indianFormatter.format(numeric);
  return showCurrency ? '₹$formatted' : formatted;
}

String formatPlainNumber(Decimal value) {
  final text = value.toString();
  if (text.contains('.')) {
    return text.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
  }
  return text;
}
