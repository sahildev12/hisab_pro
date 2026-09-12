import 'package:decimal/decimal.dart';

import '../models/row_data.dart';
import 'parse_number.dart';

class ValidationResult {
  const ValidationResult({
    required this.isValid,
    this.errorMessage,
    this.rowIndex,
  });

  final bool isValid;
  final String? errorMessage;
  final int? rowIndex;
}

bool isRowEmpty(RowData row) {
  return row.name.trim().isEmpty &&
      row.amount.trim().isEmpty &&
      row.bracket.trim().isEmpty;
}

bool isValidNumber(String value) {
  if (value.trim().isEmpty) {
    return false;
  }
  return tryParseDecimal(value) != null;
}

bool isWholeNumberAmount(String value) {
  final parsed = tryParseDecimal(value);
  if (parsed == null) return false;
  return parsed % Decimal.one == Decimal.zero;
}

ValidationResult validateRows(
  List<RowData> rows, {
  required List<String> allowedNames,
}) {
  var hasAnyData = false;

  for (var i = 0; i < rows.length; i++) {
    final row = rows[i];
    if (isRowEmpty(row)) {
      continue;
    }

    hasAnyData = true;
    final hasName = row.name.trim().isNotEmpty;
    final hasAmount = row.amount.trim().isNotEmpty;
    final hasBracket = row.bracket.trim().isNotEmpty;

    if (!hasAmount || !hasBracket) {
      return ValidationResult(
        isValid: false,
        errorMessage: 'Row ${i + 1}: Amount and bracket are required',
        rowIndex: i,
      );
    }

    if (!isValidNumber(row.amount)) {
      return ValidationResult(
        isValid: false,
        errorMessage: 'Row ${i + 1}: Enter a valid amount.',
        rowIndex: i,
      );
    }

    if (!isWholeNumberAmount(row.amount)) {
      return ValidationResult(
        isValid: false,
        errorMessage: 'Row ${i + 1}: Amount must be a whole number.',
        rowIndex: i,
      );
    }

    if (!isValidNumber(row.bracket)) {
      return ValidationResult(
        isValid: false,
        errorMessage: 'Row ${i + 1}: Enter a valid bracket.',
        rowIndex: i,
      );
    }

    if (!hasName || !allowedNames.contains(row.name.trim())) {
      return ValidationResult(
        isValid: false,
        errorMessage: 'Row ${i + 1}: Select a name',
        rowIndex: i,
      );
    }
  }

  if (!hasAnyData) {
    return const ValidationResult(
      isValid: false,
      errorMessage: 'Add at least one row with data',
    );
  }

  return const ValidationResult(isValid: true);
}
