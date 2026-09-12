import 'package:decimal/decimal.dart';

import 'result_type.dart';

class CalculationResult {
  const CalculationResult({
    required this.totalAmount,
    required this.amountDeduction,
    required this.netTotalAmount,
    required this.totalBracket,
    required this.passing,
    required this.finalBalance,
    required this.displayAmount,
    required this.passingRate,
    required this.amountDeductionRate,
    required this.resultType,
  });

  final Decimal totalAmount;
  final Decimal amountDeduction;
  final Decimal netTotalAmount;
  final Decimal totalBracket;
  final Decimal passing;
  final Decimal finalBalance;
  final Decimal displayAmount;
  final Decimal passingRate;
  final Decimal amountDeductionRate;
  final ResultType resultType;
}
