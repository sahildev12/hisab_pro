import 'package:decimal/decimal.dart';

import '../models/calculation_result.dart';
import '../models/result_type.dart';
import '../models/row_data.dart';
import 'money.dart';
import 'parse_number.dart';
import 'validate.dart';

/// Default passing rate (multiplier, e.g. 96 means × 96 on total bracket).
final Decimal defaultPassingRate = Decimal.parse('96');

/// Default commission / deduction rate (percentage of total amount).
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
/// Commission is always `totalAmount × amountDeductionRate / 100`.
///
/// When [commissionTracking] is true (paid later), commission is not deducted
/// from the main total. When false (paid daily), commission is subtracted
/// before comparing to passing.
CalculationResult calculateSettlement(
  List<RowData> rows, {
  required Decimal passingRate,
  required Decimal amountDeductionRate,
  bool commissionTracking = false,
  Decimal? storedCommissionBalance,
}) {
  final activeRows = rows.where((row) => !isRowEmpty(row)).toList();

  final amounts = activeRows.map((row) => parseDecimal(row.amount));
  final brackets = activeRows.map((row) => parseDecimal(row.bracket));

  final totalAmount = _sumDecimals(amounts);
  final commissionEarned =
      roundMoney(percentOf(totalAmount, amountDeductionRate));

  final netTotalAmount = commissionTracking
      ? totalAmount
      : totalAmount - commissionEarned;

  final totalBracket = _sumDecimals(brackets);
  final passing = totalBracket * passingRate;

  final rawDifference = netTotalAmount - passing;
  final finalBalance = roundMoney(rawDifference);
  final resultType = _resolveResultType(finalBalance);
  final displayAmount = finalBalance.abs();

  final balance = storedCommissionBalance ?? Decimal.zero;
  final commissionBalance = commissionTracking
      ? balance + commissionEarned
      : Decimal.zero;

  return CalculationResult(
    totalAmount: totalAmount,
    amountDeduction: commissionEarned,
    netTotalAmount: netTotalAmount,
    totalBracket: totalBracket,
    passing: passing,
    finalBalance: finalBalance,
    displayAmount: displayAmount,
    passingRate: passingRate,
    amountDeductionRate: amountDeductionRate,
    resultType: resultType,
    commissionEarned: commissionEarned,
    commissionTracking: commissionTracking,
    commissionBalance: commissionBalance,
    storedCommissionBalance: balance,
  );
}
