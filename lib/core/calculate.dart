import 'package:decimal/decimal.dart';

import '../models/calculation_result.dart';
import '../models/row_data.dart';
import '../models/settlement_type.dart';
import 'parse_number.dart';
import 'validate.dart';

const int defaultMultiplier = 96;

const bracketRateOptions = [96, 95, 90, 80];

Decimal _sumDecimals(Iterable<Decimal> values) {
  return values.fold(Decimal.zero, (sum, value) => sum + value);
}

CalculationResult calculate(
  List<RowData> rows, {
  int multiplier = defaultMultiplier,
  SettlementType settlementType = SettlementType.lene,
}) {
  final activeRows = rows.where((row) => !isRowEmpty(row)).toList();

  final amounts = activeRows.map((row) => parseDecimal(row.amount));
  final brackets = activeRows.map((row) => parseDecimal(row.bracket));

  final totalAmount = _sumDecimals(amounts);
  final totalBracket = _sumDecimals(brackets);
  final passing = totalBracket * Decimal.fromInt(multiplier);
  final finalAmount = totalAmount - passing;

  return CalculationResult(
    totalAmount: totalAmount,
    totalBracket: totalBracket,
    passing: passing,
    finalAmount: finalAmount,
    multiplier: multiplier,
    settlementType: settlementType,
  );
}
