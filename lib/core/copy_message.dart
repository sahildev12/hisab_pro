import '../models/calculation_result.dart';
import '../models/settlement_type.dart';
import '../models/row_data.dart';
import 'format.dart';
import 'parse_number.dart';
import 'validate.dart';

String buildCopyMessage({
  required String title,
  required List<RowData> rows,
  required CalculationResult result,
}) {
  final buffer = StringBuffer();
  final trimmedTitle = title.trim().isEmpty ? 'Calculation' : title.trim();
  final settlementLabel =
      result.settlementType == SettlementType.lene ? 'LENE AAJ' : 'DENE AAJ';

  buffer.writeln(trimmedTitle);
  buffer.writeln();

  for (final row in rows.where((item) => !isRowEmpty(item))) {
    final amount = formatPlainNumber(parseDecimal(row.amount));
    final bracket = formatPlainNumber(parseDecimal(row.bracket));
    buffer.writeln('${row.name.trim()} $amount ($bracket)');
  }

  buffer.writeln();
  buffer.writeln('TOTAL ${formatPlainNumber(result.totalAmount)}');
  buffer.writeln(
    'PASSING ${formatPlainNumber(result.totalBracket)} × ${result.multiplier} = ${formatPlainNumber(result.passing)}',
  );
  buffer.writeln(
    '$settlementLabel = ${formatPlainNumber(result.finalAmount)}',
  );

  return buffer.toString().trimRight();
}
