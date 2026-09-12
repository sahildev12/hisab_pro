import 'package:decimal/decimal.dart';

import '../models/calculation_result.dart';
import '../models/result_type.dart';
import '../models/row_data.dart';
import 'money.dart';
import 'parse_number.dart';
import 'validate.dart';

/// Default passing rate (multiplier, e.g. 96 means × 96 on total bracket).
final Decimal defaultPassingRate = Decimal.parse('96');

/// Default amount deduction rate (percentage of total amount).
final Decimal defaultAmountDeductionRate = Decimal.parse('4');

Decimal _sumDecimals(Iterable<Decimal> values) {
  return values.fold(Decimal.zero, (sum, value) => sum + value);
}

ResultType _resolveResultType(Decimal roundedDifference) {
  if (roundedDifference > Decimal.zero) {
    return ResultType.lene;
  }
  if (roundedDifference < Decimal.zero) {
    return ResultType.dene;
  }
  return ResultType.balanced;
}

/// Single source of truth for all settlement calculations.
///
/// Business rules:
/// - Amount deduction: round(totalAmount × amountDeductionRate / 100)
/// - Passing: totalBracket × passingRate (multiplier, NOT divided by 100)
/// - Final difference: round(netTotalAmount − passing) — whole rupees only
CalculationResult calculateSettlement(
  List<RowData> rows, {
  required Decimal passingRate,
  required Decimal amountDeductionRate,
}) {
  final activeRows = rows.where((row) => !isRowEmpty(row)).toList();

  final amounts = activeRows.map((row) => parseDecimal(row.amount));
  final brackets = activeRows.map((row) => parseDecimal(row.bracket));

  final totalAmount = _sumDecimals(amounts);
  final amountDeduction =
      roundMoney(percentOf(totalAmount, amountDeductionRate));
  final netTotalAmount = totalAmount - amountDeduction;
  final totalBracket = _sumDecimals(brackets);
  final passing = totalBracket * passingRate;
  final rawDifference = netTotalAmount - passing;
  final finalBalance = roundMoney(rawDifference);
  final resultType = _resolveResultType(finalBalance);
  final displayAmount = finalBalance.abs();

  return CalculationResult(
    totalAmount: totalAmount,
    amountDeduction: amountDeduction,
    netTotalAmount: netTotalAmount,
    totalBracket: totalBracket,
    passing: passing,
    finalBalance: finalBalance,
    displayAmount: displayAmount,
    passingRate: passingRate,
    amountDeductionRate: amountDeductionRate,
    resultType: resultType,
  );
}
