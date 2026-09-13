import 'package:decimal/decimal.dart';

import '../models/row_data.dart';
import 'money.dart';
import 'parse_number.dart';

/// A single parse error tied to a source line.
class SmartParseLineError {
  const SmartParseLineError({
    required this.lineNumber,
    required this.lineText,
    required this.message,
  });

  final int lineNumber;
  final String lineText;
  final String message;
}

/// Successful parse output ready for the calculation engine.
class SmartParseResult {
  const SmartParseResult({
    required this.title,
    required this.rows,
    this.passingRate,
    this.amountDeductionRate,
    this.originalText = '',
  });

  final String title;
  final List<RowData> rows;
  final Decimal? passingRate;
  final Decimal? amountDeductionRate;
  final String originalText;

  bool get hasRates => passingRate != null && amountDeductionRate != null;
}

/// Parses WhatsApp-style calculation messages into structured data.
class SmartTextParser {
  static final _entryPattern = RegExp(
    r'^\s*([A-Za-z]{1,6})\.?\s+([\d,]+)\s*\(\s*([\d.,]+)\s*\)\s*$',
    caseSensitive: false,
  );

  static final _ratePattern = RegExp(r'(\d+)\s*%\s*(\d+)\s*$');

  static final _noisePattern = RegExp(r'^[\s*._\-=]+|[\s*._\-=]+$');

  /// Parse pasted text. Returns errors if any line looks like data but fails.
  static ({
    SmartParseResult? result,
    List<SmartParseLineError> errors,
  }) parse(
    String text, {
    List<String> allowedEntryNames = const [],
  }) {
    final errors = <SmartParseLineError>[];
    final rows = <RowData>[];
    String title = '';
    Decimal? passingRate;
    Decimal? amountDeductionRate;

    final lines = text.split(RegExp(r'\r?\n'));
    var rowIndex = 0;

    for (var i = 0; i < lines.length; i++) {
      final rawLine = lines[i];
      final line = rawLine.trim();
      final lineNumber = i + 1;

      if (line.isEmpty) continue;
      if (_isFormattingOnly(line)) continue;
      if (_isSummaryLine(line)) continue;

      final entryMatch = _entryPattern.firstMatch(line);
      final rateMatch = _ratePattern.firstMatch(line);
      if (rateMatch != null) {
        final passing = int.tryParse(rateMatch.group(1)!);
        final deduction = int.tryParse(rateMatch.group(2)!);
        if (passing == null || deduction == null || passing + deduction != 100) {
          errors.add(SmartParseLineError(
            lineNumber: lineNumber,
            lineText: rawLine,
            message: 'Rate must be like 96%4 (passing + deduction = 100).',
          ));
          continue;
        }
        passingRate = Decimal.fromInt(passing);
        amountDeductionRate = Decimal.fromInt(deduction);
        final titlePart = line.substring(0, rateMatch.start).trim();
        if (titlePart.isNotEmpty) {
          title = _cleanTitle(titlePart);
        }
        continue;
      }

      if (entryMatch != null) {
        final nameRaw = entryMatch.group(1)!.trim();
        final amountRaw = entryMatch.group(2)!.trim();
        final bracketRaw = entryMatch.group(3)!.trim();

        final name = _normalizeEntryName(nameRaw, allowedEntryNames);
        if (name == null) {
          errors.add(SmartParseLineError(
            lineNumber: lineNumber,
            lineText: rawLine,
            message: 'Entry name "$nameRaw" is not recognized.',
          ));
          continue;
        }

        if (tryParseDecimal(amountRaw) == null) {
          errors.add(SmartParseLineError(
            lineNumber: lineNumber,
            lineText: rawLine,
            message: 'Amount is invalid.',
          ));
          continue;
        }

        if (tryParseDecimal(bracketRaw) == null) {
          errors.add(SmartParseLineError(
            lineNumber: lineNumber,
            lineText: rawLine,
            message: 'Bracket is invalid.',
          ));
          continue;
        }

        rows.add(RowData(
          id: '${DateTime.now().microsecondsSinceEpoch}-$rowIndex',
          name: name,
          amount: amountRaw.replaceAll(',', ''),
          bracket: bracketRaw,
        ));
        rowIndex++;
        continue;
      }

      if (_looksLikePartialEntry(line)) {
        errors.add(SmartParseLineError(
          lineNumber: lineNumber,
          lineText: rawLine,
          message: _partialEntryMessage(line),
        ));
        continue;
      }

      if (title.isEmpty && rows.isEmpty) {
        title = _cleanTitle(line);
        continue;
      }

      if (rows.isEmpty) {
        title = title.isEmpty ? _cleanTitle(line) : '$title $line'.trim();
      }
    }

    if (errors.isNotEmpty) {
      return (result: null, errors: errors);
    }

    if (rows.isEmpty) {
      return (
        result: null,
        errors: [
          const SmartParseLineError(
            lineNumber: 1,
            lineText: '',
            message: 'No entries found. Use format: Sb. 6995 (30)',
          ),
        ],
      );
    }

    return (
      result: SmartParseResult(
        title: title,
        rows: rows,
        passingRate: passingRate,
        amountDeductionRate: amountDeductionRate,
        originalText: text,
      ),
      errors: <SmartParseLineError>[],
    );
  }

  static String? _normalizeEntryName(
    String raw,
    List<String> allowedEntryNames,
  ) {
    final withDot = raw.endsWith('.') ? raw : '$raw.';
    final upper = withDot.substring(0, withDot.length - 1).toUpperCase();
    final candidate = '$upper.';

    for (final allowed in allowedEntryNames) {
      final normalized = allowed.trim();
      if (normalized.toLowerCase() == candidate.toLowerCase()) {
        return normalized.endsWith('.') ? normalized : '$normalized.';
      }
      if (normalized.toLowerCase() == raw.toLowerCase()) {
        return normalized.endsWith('.') ? normalized : '$normalized.';
      }
    }

    if (allowedEntryNames.isEmpty) {
      return candidate;
    }

    return null;
  }

  static String _cleanTitle(String line) {
    return line
        .replaceAll(RegExp(r'^\*+|\*+$'), '')
        .replaceAll(_noisePattern, '')
        .trim();
  }

  static bool _isFormattingOnly(String line) {
    final stripped = line.replaceAll(RegExp(r'[\s*]'), '');
    return stripped.isEmpty;
  }

  static bool _isSummaryLine(String line) {
    final upper = line.toUpperCase();
    return upper.startsWith('TOTAL') ||
        upper.startsWith('PASSING') ||
        upper.startsWith('COMMISSION') ||
        upper.contains('LENE AAJ') ||
        upper.contains('DENE AAJ') ||
        upper.contains('BARABAR');
  }

  static bool _looksLikePartialEntry(String line) {
    final hasParen = line.contains('(');
    final hasLetters = RegExp(r'[A-Za-z]').hasMatch(line);
    final hasDigits = RegExp(r'\d').hasMatch(line);
    return hasLetters && hasDigits || hasParen;
  }

  static String _partialEntryMessage(String line) {
    if (!line.contains('(')) {
      return 'Bracket is missing.';
    }
    if (!RegExp(r'\d').hasMatch(line)) {
      return 'Amount is invalid.';
    }
    return 'Could not understand this line.';
  }

  /// Fuzzy match group name against parsed title.
  static bool titleMatchesGroup(String title, String groupName) {
    final a = title.trim().toLowerCase();
    final b = groupName.trim().toLowerCase();
    if (a.isEmpty || b.isEmpty) return false;
    return a == b || a.contains(b) || b.contains(a);
  }

  /// Resolve rates: parsed rates win, else group defaults.
  static ({
    Decimal passingRate,
    Decimal amountDeductionRate,
  }) resolveRates({
    SmartParseResult? parsed,
    required Decimal groupPassingRate,
    required Decimal groupDeductionRate,
  }) {
    if (parsed != null && parsed.hasRates) {
      return (
        passingRate: parsed.passingRate!,
        amountDeductionRate: parsed.amountDeductionRate!,
      );
    }
    return (
      passingRate: groupPassingRate,
      amountDeductionRate: groupDeductionRate,
    );
  }
}
