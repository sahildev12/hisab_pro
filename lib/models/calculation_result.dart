import 'package:decimal/decimal.dart';

import 'result_type.dart';

class CalculationResult {
  CalculationResult({
    required this.totalAmount,
    required this.amountDeduction,
    required this.netTotalAmount,
    required this.totalBracket,
    required this.passing,
    required this.finalBalance,
    required this.displayAmount,
    required this.passingRate,
    required this.amountDeductionRate,
    required this.resultType,
    Decimal? commissionEarned,
    this.commissionTracking = false,
    Decimal? commissionBalance,
    Decimal? storedCommissionBalance,
  })  : commissionEarned = commissionEarned ?? Decimal.zero,
        commissionBalance = commissionBalance ?? Decimal.zero,
        storedCommissionBalance = storedCommissionBalance ?? Decimal.zero;

  final Decimal totalAmount;
  final Decimal amountDeduction;
  final Decimal netTotalAmount;
  final Decimal totalBracket;
  final Decimal passing;
  final Decimal finalBalance;
  final Decimal displayAmount;
  final Decimal passingRate;
  final Decimal amountDeductionRate;
  final ResultType resultType;
  final Decimal commissionEarned;
  final bool commissionTracking;
  final Decimal commissionBalance;
  final Decimal storedCommissionBalance;

  bool get hasCommissionTracking => commissionTracking;

  bool get showsCommissionInfo =>
      commissionEarned > Decimal.zero || commissionTracking;

  bool get showsCommissionBalance =>
      commissionTracking &&
      (commissionBalance > Decimal.zero || commissionEarned > Decimal.zero);

  String get commissionStatusLabel =>
      commissionTracking ? 'Kept Separate' : 'Paid Daily';

  CalculationResult copyWith({
    Decimal? commissionEarned,
    bool? commissionTracking,
    Decimal? commissionBalance,
    Decimal? storedCommissionBalance,
  }) {
    return CalculationResult(
      totalAmount: totalAmount,
      amountDeduction: amountDeduction,
      netTotalAmount: netTotalAmount,
      totalBracket: totalBracket,
      passing: passing,
      finalBalance: finalBalance,
      displayAmount: displayAmount,
      passingRate: passingRate,
      amountDeductionRate: amountDeductionRate,
      resultType: resultType,
      commissionEarned: commissionEarned ?? this.commissionEarned,
      commissionTracking: commissionTracking ?? this.commissionTracking,
      commissionBalance: commissionBalance ?? this.commissionBalance,
      storedCommissionBalance:
          storedCommissionBalance ?? this.storedCommissionBalance,
    );
  }
}
