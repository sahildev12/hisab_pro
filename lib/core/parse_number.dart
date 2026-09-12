import 'package:decimal/decimal.dart';

Decimal? tryParseDecimal(String value) {
  final cleaned = value.replaceAll(',', '').trim();
  if (cleaned.isEmpty) {
    return null;
  }

  try {
    return Decimal.parse(cleaned);
  } catch (_) {
    return null;
  }
}

Decimal parseDecimal(String value) {
  final parsed = tryParseDecimal(value);
  if (parsed == null) {
    throw FormatException('Invalid number: $value');
  }
  return parsed;
}
