import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/format.dart';
import '../models/calculation_result.dart';
import '../theme/app_theme.dart';

class CommissionBalanceCard extends StatelessWidget {
  const CommissionBalanceCard({
    super.key,
    required this.result,
    this.onClear,
    this.compact = false,
  });

  final CalculationResult result;
  final VoidCallback? onClear;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (!result.showsCommissionInfo) return const SizedBox.shrink();

    if (!result.commissionTracking && result.commissionEarned <= Decimal.zero) {
      return const SizedBox.shrink();
    }

    final isDark = isDarkContext(context);
    final accentBg = result.commissionTracking
        ? (isDark ? const Color(0xFF1A3D2E) : const Color(0xFFECFDF3))
        : appSurfaceSoftColor(context);

    return Container(
      padding: EdgeInsets.all(compact ? 12 : 16),
      decoration: BoxDecoration(
        color: accentBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: result.commissionTracking
              ? AppColors.success.withValues(alpha: 0.3)
              : appBorderColor(context),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.payments_outlined,
                size: 18,
                color: result.commissionTracking
                    ? AppColors.success
                    : AppColors.slate,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  result.commissionTracking
                      ? 'Commission'
                      : 'Commission @ ${formatRate(result.amountDeductionRate)}',
                  style: GoogleFonts.inter(
                    fontSize: compact ? 14 : 15,
                    fontWeight: FontWeight.w700,
                    color: appPrimaryTextColor(context),
                  ),
                ),
              ),
              if (result.commissionTracking)
                Text(
                  result.commissionStatusLabel,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.success,
                  ),
                ),
            ],
          ),
          if (result.commissionEarned > Decimal.zero) ...[
            const SizedBox(height: 8),
            _row(
              context,
              label: result.commissionTracking
                  ? 'Commission Earned Today'
                  : 'Commission',
              amount: result.commissionEarned,
            ),
          ],
          if (result.commissionTracking &&
              result.commissionBalance > Decimal.zero) ...[
            const SizedBox(height: 6),
            _row(
              context,
              label: 'Commission Balance',
              amount: result.commissionBalance,
              emphasized: true,
            ),
          ],
          if (result.commissionTracking && onClear != null) ...[
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: onClear,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
                side: BorderSide(
                  color: AppColors.danger.withValues(alpha: 0.4),
                ),
                minimumSize: const Size.fromHeight(40),
              ),
              child: const Text('Clear Commission'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _row(
    BuildContext context, {
    required String label,
    required Decimal amount,
    bool emphasized = false,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: appSecondaryTextColor(context),
            ),
          ),
        ),
        Text(
          formatMoney(amount, showCurrency: true),
          style: GoogleFonts.inter(
            fontSize: emphasized ? (compact ? 20 : 24) : (compact ? 16 : 18),
            fontWeight: FontWeight.w800,
            color: emphasized
                ? AppColors.success
                : appPrimaryTextColor(context),
          ),
        ),
      ],
    );
  }
}
