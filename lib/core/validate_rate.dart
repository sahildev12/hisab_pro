import 'package:decimal/decimal.dart';

import 'parse_number.dart';

class RateValidationResult {
  const RateValidationResult({required this.isValid, this.errorMessage});

  final bool isValid;
  final String? errorMessage;
}

RateValidationResult validatePassingRate(String value) {
  final parsed = tryParseDecimal(value);
  if (parsed == null) {
    return const RateValidationResult(
      isValid: false,
      errorMessage: 'Enter a valid passing rate.',
    );
  }
  if (parsed <= Decimal.zero || parsed > Decimal.fromInt(100)) {
    return const RateValidationResult(
      isValid: false,
      errorMessage: 'Enter a valid rate between 0 and 100.',
    );
  }
  return const RateValidationResult(isValid: true);
}

RateValidationResult validateDeductionRate(String value) {
  final parsed = tryParseDecimal(value);
  if (parsed == null) {
    return const RateValidationResult(
      isValid: false,
      errorMessage: 'Enter a valid amount deduction rate.',
    );
  }
  if (parsed <= Decimal.zero || parsed > Decimal.fromInt(100)) {
    return const RateValidationResult(
      isValid: false,
      errorMessage: 'Enter a valid rate between 0 and 100.',
    );
  }
  return const RateValidationResult(isValid: true);
}

@Deprecated('Use validatePassingRate or validateDeductionRate')
RateValidationResult validateRate(String value) => validatePassingRate(value);

Decimal parsePassingRate(String value) {
  final result = validatePassingRate(value);
  if (!result.isValid) {
    throw FormatException(
      result.errorMessage ?? 'Enter a valid passing rate.',
    );
  }
  return parseDecimal(value);
}

Decimal parseDeductionRate(String value) {
  final result = validateDeductionRate(value);
  if (!result.isValid) {
    throw FormatException(
      result.errorMessage ?? 'Enter a valid amount deduction rate.',
    );
  }
  return parseDecimal(value);
}

Decimal parseRate(String value) => parsePassingRate(value);
