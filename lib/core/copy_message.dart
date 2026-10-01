import 'dart:math' as math;

import 'package:decimal/decimal.dart';

import '../models/calculation_result.dart';
import '../models/result_type.dart';
import '../models/row_data.dart';
import 'format.dart';
import 'parse_number.dart' show tryParseDecimal;
import 'validate.dart';

String _bold(String text) => '*$text*';

String _upper(String text) => text.toUpperCase();

/// Copy label without trailing dot: `Sb.` → `SB`.
String _formatCopyName(String name) {
  final upper = _upper(name.trim());
  if (upper.endsWith('.')) {
    return upper.substring(0, upper.length - 1);
  }
  return upper;
}

bool _shouldShowBracket(String bracket) {
  if (bracket.isEmpty) return false;
  final parsed = tryParseDecimal(bracket);
  return parsed != null && parsed != Decimal.zero;
}

String _labelValueLine(String label, String value) =>
    '${_bold(_upper(label))} $value';

String buildCopyMessage({
  required String title,
  required List<RowData> rows,
  required CalculationResult result,
  String persistentHeader = '',
}) {
  return buildWhatsAppCopyMessage(
    title: title,
    rows: rows,
    result: result,
    persistentHeader: persistentHeader,
  );
}

/// WhatsApp-style copy/share text for group session and paste calculation.
String buildPasteCopyMessage({
  required String title,
  required List<RowData> rows,
  required CalculationResult result,
  String persistentHeader = '',
}) {
  return buildWhatsAppCopyMessage(
    title: title,
    rows: rows,
    result: result,
    persistentHeader: persistentHeader,
  );
}

/// WhatsApp share format — bold date/title, aligned rows, compact totals.
String buildWhatsAppCopyMessage({
  required String title,
  required List<RowData> rows,
  required CalculationResult result,
  String persistentHeader = '',
}) {
  final buffer = StringBuffer();
  final trimmedHeader = persistentHeader.trim();
  final trimmedTitle =
      title.trim().isEmpty ? 'CALCULATION' : _upper(title.trim());

  if (trimmedHeader.isNotEmpty) {
    buffer.writeln(_bold(trimmedHeader));
    buffer.writeln();
  }

  buffer.writeln(_bold(trimmedTitle));
  buffer.writeln();

  _writeFormattedRows(buffer, rows);

  buffer.writeln();
  if (result.commissionTracking) {
    buffer.writeln(
      _labelValueLine('TOTAL', formatPlainNumber(result.totalAmount)),
    );
  } else {
    buffer.writeln(
      _labelValueLine(
        'TOTAL',
        '${formatPlainNumber(result.totalAmount)}-'
        '${formatPlainNumber(result.commissionEarned)}='
        '${formatPlainNumber(result.netTotalAmount)}',
      ),
    );
  }
  buffer.writeln();
  buffer.writeln(
    _labelValueLine(
      'PASSING',
      '${formatPlainNumber(result.totalBracket)}×'
      '${formatPlainNumber(result.passingRate)}='
      '${formatPlainNumber(result.passing)}',
    ),
  );
  buffer.writeln();
  buffer.writeln(
    _bold(
      '${formatPlainNumber(result.passing)}-'
      '${formatPlainNumber(result.netTotalAmount)}='
      '${formatPlainNumber(result.displayAmount)} '
      '${_upper(_resultSuffix(result.resultType))}',
    ),
  );

  if (result.commissionTracking && result.commissionEarned > Decimal.zero) {
    buffer.writeln();
    buffer.writeln(
      _labelValueLine(
        'COMMISSION',
        formatPlainNumber(result.commissionEarned),
      ),
    );
  }

  return buffer.toString().trimRight();
}

@Deprecated('Use buildWhatsAppCopyMessage')
String buildWebCopyMessage({
  required String title,
  required List<RowData> rows,
  required CalculationResult result,
  String persistentHeader = '',
}) {
  return buildWhatsAppCopyMessage(
    title: title,
    rows: rows,
    result: result,
    persistentHeader: persistentHeader,
  );
}

String _resultSuffix(ResultType type) {
  switch (type) {
    case ResultType.lene:
      return 'lene aaj ke';
    case ResultType.dene:
      return 'dene aaj ke';
    case ResultType.balanced:
      return 'hisab barabar';
  }
}

/// Figure space — same width as digits in most fonts (helps WhatsApp alignment).
const _figSpace = '\u2007';

const _minNameColumnWidth = 8;
const _minAmountColumnWidth = 4;
const _minGapBeforeBracket = 3;

String _figGap(int count) {
  if (count <= 0) return '';
  return _figSpace * count;
}

void _writeFormattedRows(StringBuffer buffer, List<RowData> rows) {
  final activeRows = _copyableRows(rows);
  if (activeRows.isEmpty) return;

  final names = activeRows
      .map((row) => _formatCopyName(row.name))
      .toList(growable: false);
  final longestName =
      names.map((name) => name.length).fold<int>(0, math.max);
  final amountStartColumn = math.max(
    _minNameColumnWidth,
    longestName + 1,
  );
  final amountFieldWidth = math.max(
    _minAmountColumnWidth,
    activeRows
        .map((row) => _displayCell(row.amount).length)
        .fold<int>(0, math.max),
  );
  final anyBracket = activeRows.any(
    (row) => _shouldShowBracket(_displayCell(row.bracket)),
  );
  final bracketOpenColumn = anyBracket
      ? amountStartColumn + amountFieldWidth + _minGapBeforeBracket
      : 0;

  for (var i = 0; i < activeRows.length; i++) {
    final name = names[i];
    final amount = _displayCell(activeRows[i].amount);
    final bracket = _displayCell(activeRows[i].bracket);
    final namePrefix = name.length >= amountStartColumn
        ? '$name '
        : name.padRight(amountStartColumn);
    if (!_shouldShowBracket(bracket)) {
      buffer.writeln('$namePrefix$amount');
      continue;
    }
    final gapBeforeBracket =
        bracketOpenColumn - namePrefix.length - amount.length;
    buffer.writeln(
      '$namePrefix$amount${_figGap(gapBeforeBracket)}($bracket)',
    );
  }
}

bool _rowHasCopyableNumbers(RowData row) {
  if (isRowEmpty(row)) return false;
  return tryParseDecimal(row.amount) != null ||
      tryParseDecimal(row.bracket) != null;
}

List<RowData> _copyableRows(List<RowData> rows) {
  return rows.where(_rowHasCopyableNumbers).toList();
}

/// Copy text for a cell — keeps user typing such as leading zeros (`06`).
String _displayCell(String raw) {
  final cleaned = raw.replaceAll(',', '').trim();
  if (cleaned.isEmpty) return '';
  if (tryParseDecimal(cleaned) == null) return '';
  return cleaned;
}
