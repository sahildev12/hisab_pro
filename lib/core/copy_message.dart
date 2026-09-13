import 'dart:math' as math;

import 'package:decimal/decimal.dart';

import '../models/calculation_result.dart';
import '../models/row_data.dart';
import 'format.dart';
import 'parse_number.dart';
import 'validate.dart';

/// Column width for summary labels (fits COMMISSION + 1 space).
const _summaryLabelWidth = 11;

String _label(String text) => text.padRight(_summaryLabelWidth);

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

  _writeFormattedRows(buffer, rows);

  buffer.writeln();
  if (result.commissionTracking) {
    buffer.writeln(
      '${_label('TOTAL')}${formatPlainNumber(result.totalAmount)}',
    );
  } else {
    buffer.writeln(
      '${_label('TOTAL')}'
      '${formatPlainNumber(result.totalAmount)} - '
      '${formatPlainNumber(result.commissionEarned)} = '
      '${formatPlainNumber(result.netTotalAmount)}',
    );
  }
  buffer.writeln();
  buffer.writeln(
    '${_label('PASSING')}'
    '${formatPlainNumber(result.totalBracket)} × '
    '${formatPlainNumber(result.passingRate)} = '
    '${formatMoney(result.passing, showCurrency: false)}',
  );
  buffer.writeln();
  buffer.writeln(
    '${formatMoney(result.netTotalAmount, showCurrency: false)} - '
    '${formatMoney(result.passing, showCurrency: false)} = '
    '${formatMoney(result.displayAmount, showCurrency: false)} '
    '${result.resultType.displayLabel.toLowerCase()}.',
  );

  if (result.commissionTracking && result.commissionEarned > Decimal.zero) {
    buffer.writeln();
    buffer.writeln(
      '${_label('COMMISSION')}'
      '${formatMoney(result.commissionEarned, showCurrency: false)}',
    );
  }

  return buffer.toString().trimRight();
}

void _writeFormattedRows(StringBuffer buffer, List<RowData> rows) {
  final activeRows = rows.where((item) => !isRowEmpty(item)).toList();
  if (activeRows.isEmpty) return;

  final nameWidth = activeRows
      .map((row) => row.name.trim().length)
      .fold<int>(0, math.max);
  final amountWidth = activeRows
      .map((row) => formatPlainNumber(parseDecimal(row.amount)).length)
      .fold<int>(0, math.max);
  final bracketWidth = activeRows
      .map((row) => formatPlainNumber(parseDecimal(row.bracket)).length)
      .fold<int>(0, math.max);

  for (final row in activeRows) {
    final name = row.name.trim().padRight(nameWidth);
    final amount =
        formatPlainNumber(parseDecimal(row.amount)).padLeft(amountWidth);
    final bracket =
        formatPlainNumber(parseDecimal(row.bracket)).padLeft(bracketWidth);
    buffer.writeln('$name  $amount  ($bracket)');
  }
}
