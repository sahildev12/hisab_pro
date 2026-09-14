import 'package:decimal/decimal.dart';

import '../models/row_data.dart';
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
  static final _numericTokenPattern = RegExp(
    r'(?:\d[\d,]*(?:\.\d+)?|\.\d+)\.?',
  );

  /// Short entry codes use a trailing dot (Sb.) or 1–3 letters before the amount.
  static final _entryNamePrefix = RegExp(
    r'^(?:[A-Za-z]{1,6}\.\s+|[A-Za-z]{1,3}\s+\d)',
    caseSensitive: false,
  );

  static final _rateEndPattern = RegExp(
    r'(\d{1,3})\s*[%/\-_&$#:,]?\s*(\d{1,3})\s*\.?\s*$',
  );

  static final _datePattern = RegExp(
    r'^\d{1,2}[-=]\d{1,2}[-=]\d{4}$',
  );

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
      final line = normalizeLine(rawLine);
      final lineNumber = i + 1;

      if (line.isEmpty) continue;
      if (_isFormattingOnly(line)) continue;
      if (_isDateLine(line)) continue;
      if (_isSummaryLine(line)) continue;

      final rateLine = _tryParseRateLine(line);
      if (rateLine != null) {
        passingRate = Decimal.fromInt(rateLine.passing);
        amountDeductionRate = Decimal.fromInt(rateLine.deduction);
        if (rateLine.title.isNotEmpty) {
          title = rateLine.title;
        }
        continue;
      }

      if (_hasEntryNamePrefix(line)) {
        final entry = _tryParseEntryLine(line, allowedEntryNames);
        if (entry.error != null) {
          errors.add(SmartParseLineError(
            lineNumber: lineNumber,
            lineText: rawLine,
            message: entry.error!,
          ));
          continue;
        }
        if (entry.row != null) {
          rows.add(entry.row!.copyWith(
            id: '${DateTime.now().microsecondsSinceEpoch}-$rowIndex',
          ));
          rowIndex++;
        }
        continue;
      }

      if (title.isEmpty && rows.isEmpty) {
        title = _cleanTitle(line);
        continue;
      }

      if (_looksLikeDataLine(line)) {
        errors.add(SmartParseLineError(
          lineNumber: lineNumber,
          lineText: rawLine,
          message: 'Could not understand this line.',
        ));
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
            message: 'No entries found. Paste lines like: Sb. 6781 45',
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

  /// Normalize a single line for parsing (tabs, spaces, WhatsApp bold).
  static String normalizeLine(String raw) {
    var line = raw.replaceAll('\t', ' ').trim();
    line = stripWhatsAppFormatting(line);
    line = line.replaceAll(RegExp(r'\s+'), ' ');
    return line;
  }

  /// Remove leading/trailing WhatsApp bold markers.
  static String stripWhatsAppFormatting(String line) {
    return line.replaceAll(RegExp(r'^\*+|\*+$'), '').trim();
  }

  /// Normalize a numeric token (commas, parens, trailing punctuation dots).
  static String? normalizeNumericToken(String raw) {
    var token = raw.replaceAll(',', '').trim();
    if (token.startsWith('(') && token.endsWith(')')) {
      token = token.substring(1, token.length - 1).trim();
    }

    while (token.endsWith('.') && token.length > 1) {
      final without = token.substring(0, token.length - 1);
      if (tryParseDecimal(without) != null) {
        token = without;
      } else {
        break;
      }
    }

    if (tryParseDecimal(token) == null) {
      return null;
    }
    return token;
  }

  static List<String> extractNumericTokens(String line) {
    final expanded = line.replaceAllMapped(
      RegExp(r'\(\s*([^)]+)\s*\)'),
      (match) => ' ${match.group(1)!} ',
    );

    final tokens = <String>[];
    for (final match in _numericTokenPattern.allMatches(expanded)) {
      final normalized = normalizeNumericToken(match.group(0)!);
      if (normalized != null) {
        tokens.add(normalized);
      }
    }
    return tokens;
  }

  static ({
    String title,
    int passing,
    int deduction,
  })? _tryParseRateLine(String line) {
    if (_hasEntryNamePrefix(line)) {
      return null;
    }

    final match = _rateEndPattern.firstMatch(line);
    if (match == null) return null;

    final passing = int.tryParse(match.group(1)!);
    final deduction = int.tryParse(match.group(2)!);
    if (passing == null || deduction == null) return null;
    if (passing > 100 || deduction > 100) return null;

    final titlePart = line.substring(0, match.start).trim();
    return (
      title: _cleanTitle(titlePart),
      passing: passing,
      deduction: deduction,
    );
  }

  static ({
    RowData? row,
    String? error,
  }) _tryParseEntryLine(
    String line,
    List<String> allowedEntryNames,
  ) {
    final nameMatch = RegExp(r'^([A-Za-z]{1,6}\.?)\s+(.*)$').firstMatch(line);
    final entryLabel = nameMatch?.group(1) ?? 'this entry';
    final remainder = nameMatch?.group(2) ?? line;

    final firstNumeric = _numericTokenPattern.firstMatch(remainder);
    if (firstNumeric != null) {
      final beforeAmount = remainder.substring(0, firstNumeric.start).trim();
      if (beforeAmount.isNotEmpty &&
          RegExp(r'[A-Za-z]').hasMatch(beforeAmount)) {
        return (
          row: null,
          error: 'Amount is invalid for $entryLabel.',
        );
      }
    }

    final numericTokens = extractNumericTokens(line);
    if (numericTokens.isEmpty) {
      return (row: null, error: 'Amount is invalid for $entryLabel.');
    }
    if (numericTokens.length < 2) {
      final name = _extractEntryName(line, numericTokens);
      final label = name ?? entryLabel;
      return (
        row: null,
        error: 'Bracket / passing value is missing for $label.',
      );
    }

    final amountRaw = numericTokens[0];
    final bracketRaw = numericTokens[1];
    final nameRaw = _extractEntryName(line, numericTokens);
    if (nameRaw == null || nameRaw.isEmpty) {
      return (row: null, error: 'Entry name is missing.');
    }

    final name = _normalizeEntryName(nameRaw, allowedEntryNames);
    if (name == null) {
      return (
        row: null,
        error: 'Entry name "$nameRaw" is not recognized.',
      );
    }

    if (tryParseDecimal(amountRaw) == null) {
      return (row: null, error: 'Amount is invalid for $name.');
    }

    if (tryParseDecimal(bracketRaw) == null) {
      return (
        row: null,
        error: 'Bracket / passing value is invalid for $name.',
      );
    }

    return (
      row: RowData(
        id: '',
        name: name,
        amount: amountRaw,
        bracket: bracketRaw,
      ),
      error: null,
    );
  }

  static String? _extractEntryName(
    String line,
    List<String> numericTokens,
  ) {
    final expanded = line.replaceAllMapped(
      RegExp(r'\(\s*([^)]+)\s*\)'),
      (match) => ' ${match.group(1)!} ',
    );

    final firstMatch = _numericTokenPattern.firstMatch(expanded);
    if (firstMatch == null) {
      return expanded.trim().isEmpty ? null : expanded.trim();
    }

    final namePart = expanded.substring(0, firstMatch.start).trim();
    if (namePart.isEmpty) return null;
    return namePart;
  }

  static bool _hasEntryNamePrefix(String line) {
    return _entryNamePrefix.hasMatch(line);
  }

  static String? _normalizeEntryName(
    String raw,
    List<String> allowedEntryNames,
  ) {
    final trimmed = raw.trim();
    final withoutTrailingDot =
        trimmed.endsWith('.') ? trimmed.substring(0, trimmed.length - 1) : trimmed;
    final withDot = '$withoutTrailingDot.';

    for (final allowed in allowedEntryNames) {
      final normalized = allowed.trim();
      final allowedBase = normalized.endsWith('.')
          ? normalized.substring(0, normalized.length - 1)
          : normalized;
      if (allowedBase.toLowerCase() == withoutTrailingDot.toLowerCase()) {
        return normalized.endsWith('.') ? normalized : '$normalized.';
      }
    }

    if (allowedEntryNames.isEmpty) {
      return withDot;
    }

    return null;
  }

  static String _cleanTitle(String line) {
    return stripWhatsAppFormatting(line)
        .replaceAll(RegExp(r'^[\s._\-=]+|[\s._\-=]+$'), '')
        .trim();
  }

  static bool _isFormattingOnly(String line) {
    final stripped = line.replaceAll(RegExp(r'[\s*]'), '');
    return stripped.isEmpty;
  }

  static bool _isDateLine(String line) {
    return _datePattern.hasMatch(line);
  }

  static bool _isSummaryLine(String line) {
    final upper = line.toUpperCase();
    if (upper.startsWith('TOTAL') ||
        upper.startsWith('PASSING') ||
        upper.startsWith('COMMISSION') ||
        upper.contains('LENE AAJ') ||
        upper.contains('DENE AAJ') ||
        upper.contains('BARABAR')) {
      return true;
    }

    if (RegExp(r'\d+\s*[-×x*]\s*\d+\s*=').hasMatch(line)) {
      return true;
    }

    return false;
  }

  static bool _looksLikeDataLine(String line) {
    final hasLetters = RegExp(r'[A-Za-z]').hasMatch(line);
    final hasDigits = RegExp(r'\d').hasMatch(line);
    return hasLetters && hasDigits;
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
