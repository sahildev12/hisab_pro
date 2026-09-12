import '../models/calculation_result.dart';
import '../models/row_data.dart';
import 'format.dart';
import 'parse_number.dart';
import 'validate.dart';

String buildCopyMessage({
  required String title,
  required List<RowData> rows,
  required CalculationResult result,
  String persistentHeader = '',
}) {
  final buffer = StringBuffer();
  final trimmedHeader = persistentHeader.trim();
  final trimmedTitle = title.trim().isEmpty ? 'Calculation' : title.trim();

  if (trimmedHeader.isNotEmpty) {
    buffer.writeln(trimmedHeader);
    buffer.writeln();
  }

  buffer.writeln(trimmedTitle);
  buffer.writeln();

  for (final row in rows.where((item) => !isRowEmpty(item))) {
    final amount = formatPlainNumber(parseDecimal(row.amount));
    final bracket = formatPlainNumber(parseDecimal(row.bracket));
    buffer.writeln('${row.name.trim()} $amount ($bracket)');
  }

  buffer.writeln();
  buffer.writeln(
    'TOTAL ${formatPlainNumber(result.totalAmount)} - ${formatPlainNumber(result.amountDeduction)} = ${formatPlainNumber(result.netTotalAmount)}',
  );
  buffer.writeln(
    'PASSING ${formatPlainNumber(result.totalBracket)} × ${formatPlainNumber(result.passingRate)} = ${formatMoney(result.passing, showCurrency: false)}',
  );
  buffer.writeln(
    '${formatMoney(result.netTotalAmount, showCurrency: false)} - ${formatMoney(result.passing, showCurrency: false)} = ${formatMoney(result.displayAmount, showCurrency: false)} ${result.resultType.displayLabel.toLowerCase()}.',
  );

  return buffer.toString().trimRight();
}
