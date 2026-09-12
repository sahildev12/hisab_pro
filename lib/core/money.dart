import 'package:decimal/decimal.dart';

/// Calculates [percent]% of [value] using decimal-safe arithmetic.
Decimal percentOf(Decimal value, Decimal percent) {
  return (value * percent / Decimal.fromInt(100))
      .toDecimal(scaleOnInfinitePrecision: 10);
}

/// Money amounts are rounded to the nearest whole rupee using half-up rounding.
///
/// Example: 120777 × 4% = 4831.08 → 4831
Decimal roundMoney(Decimal value) {
  if (value == Decimal.zero) return Decimal.zero;

  final isNegative = value < Decimal.zero;
  final absolute = isNegative ? -value : value;
  final remainder = absolute % Decimal.one;
  final whole = absolute - remainder;

  final rounded = remainder >= Decimal.parse('0.5')
      ? whole + Decimal.one
      : whole;

  return isNegative ? -rounded : rounded;
}

/// Suggested amount deduction when passing rate changes (100 − passing).
Decimal suggestedAmountDeduction(Decimal passingRate) {
  final suggested = Decimal.fromInt(100) - passingRate;
  if (suggested < Decimal.zero) return Decimal.zero;
  return suggested;
}
