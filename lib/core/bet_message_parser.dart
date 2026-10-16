import 'package:decimal/decimal.dart';

/// Bet line types from [MESSAGE-LOGIC.md].
enum BetMessageKind { single, joda, crossing }

sealed class BetParseResult {
  const BetParseResult(this.kind);
  final BetMessageKind kind;
}

/// Table 1–100 single pricing.
class SingleBetLine extends BetParseResult {
  SingleBetLine({
    required this.tableNumber,
    required this.amountRs,
    required this.rawLine,
  }) : super(BetMessageKind.single);

  /// Normalized slot (00 and 100 both map to 100).
  final int tableNumber;
  final Decimal amountRs;
  final String rawLine;
}

/// Joda cut or crossing — same formula, different [n].
class BundleBetLine extends BetParseResult {
  BundleBetLine({
    required BetMessageKind kind,
    required this.digitsRaw,
    required this.clientPriceRs,
    required this.n,
    required this.factor,
    required this.lineTotalRs,
    required this.rawLine,
  })  : assert(kind == BetMessageKind.joda || kind == BetMessageKind.crossing),
        super(kind);

  final String digitsRaw;
  final Decimal clientPriceRs;
  final int n;
  final int factor;
  final Decimal lineTotalRs;
  final String rawLine;
}

class BetParseFailure {
  const BetParseFailure(this.message, {this.rawLine = ''});
  final String message;
  final String rawLine;
}

/// Parses one WhatsApp bet line per team rules.
class BetMessageParser {
  static final _jodaKeyword = RegExp(
    r'\b(joda|jode|jk|jc|jara\s*kat|cut\s*into)\b',
    caseSensitive: false,
  );

  static final _bundleDigits = RegExp(r'^\d{3,}$');

  /// Factor = n² − n.
  static int bundleFactor(int n) => n * n - n;

  /// Joda: cancel one digit per matched pair (same digit).
  static int jodaEffectiveN(String digits) {
    final counts = List<int>.filled(10, 0);
    for (final code in digits.codeUnits) {
      counts[code - 48]++;
    }
    var cancel = 0;
    for (final c in counts) {
      cancel += c ~/ 2;
    }
    return digits.length - cancel;
  }

  static int crossingN(String digits) => digits.length;

  /// 00 ↔ 100 for single table only.
  static int normalizeSingleTableNumber(int n) {
    if (n == 0) return 100;
    if (n == 100) return 100;
    return n;
  }

  static ({String digits, Decimal price})? _parseDigitsThenPrice(
    String line, {
    required List<String> separators,
  }) {
    final trimmed = line.trim();
    for (final sep in separators) {
      final idx = trimmed.indexOf(sep);
      if (idx <= 0) continue;
      final left = trimmed.substring(0, idx).trim();
      final right = trimmed.substring(idx + sep.length).trim();
      if (!_bundleDigits.hasMatch(left)) continue;
      final priceStr = _leadingInt(right);
      if (priceStr == null) continue;
      return (digits: left, price: Decimal.parse(priceStr));
    }
    return null;
  }

  static String? _leadingInt(String s) {
    final m = RegExp(r'^(\d+)').firstMatch(s.trim());
    return m?.group(1);
  }

  static BetParseResult? parseLine(String line) {
    final failure = parseLineOrFailure(line);
    return failure is BetParseResult ? failure : null;
  }

  static Object parseLineOrFailure(String line) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) {
      return const BetParseFailure('Empty line');
    }

    if (_jodaKeyword.hasMatch(trimmed)) {
      return _parseJoda(trimmed) ??
          BetParseFailure('Could not parse joda line', rawLine: trimmed);
    }

    // Single (1–100) before crossing so `100=5` is not treated as a 3-digit bundle.
    final single = _parseSingle(trimmed);
    if (single != null) return single;

    final crossing = _parseCrossing(trimmed);
    if (crossing != null) return crossing;

    return BetParseFailure('Unrecognized bet line', rawLine: trimmed);
  }

  static BundleBetLine? _parseCrossing(String line) {
    final parsed = _parseDigitsThenPrice(
      line,
      separators: const ['=', '+', '.'],
    );
    if (parsed == null) return null;
    if (_jodaKeyword.hasMatch(line)) return null;

    final n = crossingN(parsed.digits);
    final factor = bundleFactor(n);
    final total = parsed.price * Decimal.fromInt(factor);
    return BundleBetLine(
      kind: BetMessageKind.crossing,
      digitsRaw: parsed.digits,
      clientPriceRs: parsed.price,
      n: n,
      factor: factor,
      lineTotalRs: total,
      rawLine: line,
    );
  }

  static BundleBetLine? _parseJoda(String line) {
    final digitsMatch = RegExp(r'^(\d{3,})').firstMatch(line);
    if (digitsMatch == null) return null;
    final digits = digitsMatch.group(1)!;

    if (digits.length == 3 && _hasDuplicateDigit(digits)) {
      return null;
    }

    final afterDigits = line.substring(digitsMatch.end).trim();
    final priceStr = RegExp(r'(\d+)\s*$').firstMatch(afterDigits)?.group(1) ??
        _leadingInt(afterDigits);
    if (priceStr == null) return null;

    final price = Decimal.parse(priceStr);
    final n = jodaEffectiveN(digits);
    if (n < 3) return null;

    final factor = bundleFactor(n);
    return BundleBetLine(
      kind: BetMessageKind.joda,
      digitsRaw: digits,
      clientPriceRs: price,
      n: n,
      factor: factor,
      lineTotalRs: price * Decimal.fromInt(factor),
      rawLine: line,
    );
  }

  static bool _hasDuplicateDigit(String digits) {
    final seen = <int>{};
    for (final code in digits.codeUnits) {
      if (seen.contains(code)) return true;
      seen.add(code);
    }
    return false;
  }

  static SingleBetLine? _parseSingle(String line) {
    final m = RegExp(
      r'^(\d{1,3})(=|\+|\.)(\d+)$',
      caseSensitive: false,
    ).firstMatch(line.replaceAll(RegExp(r'\s+'), ''));
    if (m == null) return null;

    final tableRaw = int.parse(m.group(1)!);
    if (tableRaw < 0 || tableRaw > 100) return null;

    final table = normalizeSingleTableNumber(tableRaw);
    if (table < 1 || table > 100) return null;

    // Long digit strings are crossing, not single (e.g. 12357890=3).
    if (m.group(1)!.length > 3) return null;
    if (m.group(1)!.length == 3 && tableRaw > 100) return null;
    final amount = Decimal.parse(m.group(3)!);
    return SingleBetLine(
      tableNumber: table,
      amountRs: amount,
      rawLine: line,
    );
  }

  /// Parse multiple non-empty lines; skips failures.
  static List<BetParseResult> parseMessage(String text) {
    final results = <BetParseResult>[];
    for (final line in text.split(RegExp(r'\r?\n'))) {
      final parsed = parseLine(line);
      if (parsed != null) results.add(parsed);
    }
    return results;
  }
}
