import 'package:decimal/decimal.dart';

import 'settlement_type.dart';

class CalculationResult {
  const CalculationResult({
    required this.totalAmount,
    required this.totalBracket,
    required this.passing,
    required this.finalAmount,
    required this.multiplier,
    required this.settlementType,
  });

  final Decimal totalAmount;
  final Decimal totalBracket;
  final Decimal passing;
  final Decimal finalAmount;
  final int multiplier;
  final SettlementType settlementType;
}
