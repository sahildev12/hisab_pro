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

String _bold(String text) => '*$text*';

String _boldSummaryLine(String label, String value) {
  if (label.isEmpty) {
    return _bold(value);
  }
  return _bold('${_label(label)}$value');
}

/// Fixed column layout for paste copy rows: `Sb.    4151    ( 35 )`.
const _pasteNameColumnWidth = 7;
const _pasteAmountColumnWidth = 5;
const _pasteBracketColumnStart = 16;

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

/// WhatsApp-style copy text for the paste calculation screen.
///
/// Row brackets use spaced parentheses: `Sb.  4151  ( 35 )`.
String buildPasteCopyMessage({
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

  _writePasteFormattedRows(buffer, rows);

  buffer.writeln();
  if (result.commissionTracking) {
    buffer.writeln(
      _boldSummaryLine('TOTAL', formatPlainNumber(result.totalAmount)),
    );
  } else {
    buffer.writeln(
      _boldSummaryLine(
        'TOTAL',
        '${formatPlainNumber(result.totalAmount)} - '
        '${formatPlainNumber(result.commissionEarned)} = '
        '${formatPlainNumber(result.netTotalAmount)}',
      ),
    );
  }
  buffer.writeln();
  buffer.writeln(
    _boldSummaryLine(
      'PASSING',
      '${formatPlainNumber(result.totalBracket)} × '
      '${formatPlainNumber(result.passingRate)} = '
      '${formatPlainNumber(result.passing)}',
    ),
  );
  buffer.writeln();
  buffer.writeln(
    _boldSummaryLine(
      '',
      '${formatPlainNumber(result.netTotalAmount)} - '
      '${formatPlainNumber(result.passing)} = '
      '${formatPlainNumber(result.displayAmount)} '
      '${result.resultType.displayLabel.toLowerCase()}.',
    ),
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

void _writePasteFormattedRows(StringBuffer buffer, List<RowData> rows) {
  final activeRows = rows.where((item) => !isRowEmpty(item)).toList();
  if (activeRows.isEmpty) return;

  final bracketWidth = activeRows
      .map((row) => formatPlainNumber(parseDecimal(row.bracket)).length)
      .fold<int>(0, math.max);

  for (final row in activeRows) {
    final name = row.name.trim().padRight(_pasteNameColumnWidth);
    final amount = formatPlainNumber(parseDecimal(row.amount))
        .padLeft(_pasteAmountColumnWidth);
    final bracket =
        formatPlainNumber(parseDecimal(row.bracket)).padLeft(bracketWidth);
    final prefix = '$name$amount';
    final gap = math.max(1, _pasteBracketColumnStart - prefix.length);
    buffer.writeln('$prefix${' ' * gap}( $bracket )');
  }
}

void _writeFormattedRows(
  StringBuffer buffer,
  List<RowData> rows, {
  bool spacedBrackets = false,
}) {
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
    if (spacedBrackets) {
      buffer.writeln('$name  $amount  ( $bracket )');
    } else {
      buffer.writeln('$name  $amount  ($bracket)');
    }
  }
}
