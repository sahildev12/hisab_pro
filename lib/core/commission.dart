import 'package:decimal/decimal.dart';

/// Stable key for per-person commission balance storage.
///
/// Uses normalized calculation title. Empty titles share a default bucket.
String commissionOwnerId(String title) {
  final normalized = title.trim().toLowerCase();
  return normalized.isEmpty ? '__default__' : normalized;
}

Decimal adjustCommissionBalance({
  required Decimal currentBalance,
  required Decimal previousEarned,
  required Decimal newEarned,
}) {
  return currentBalance - previousEarned + newEarned;
}
