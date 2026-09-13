import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/format.dart';
import '../models/calculation_result.dart';
import '../theme/app_theme.dart';

class QuickSummaryStrip extends StatelessWidget {
  const QuickSummaryStrip({super.key, required this.result});

  final CalculationResult result;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: surfaceDecoration(context),
      child: Column(
        children: [
          _row(
            'Total Amount',
            formatMoney(result.totalAmount, showCurrency: true),
          ),
          const SizedBox(height: 8),
          _row(
            result.commissionTracking
                ? 'Commission @ ${formatPlainNumber(result.amountDeductionRate)}% (separate)'
                : 'Commission @ ${formatPlainNumber(result.amountDeductionRate)}%',
            formatMoney(result.commissionEarned, showCurrency: true),
          ),
          const SizedBox(height: 8),
          _row(
            'Net Total',
            formatMoney(result.netTotalAmount, showCurrency: true),
            bold: true,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, color: AppColors.border),
          ),
          _row('Total Bracket', formatBracket(result.totalBracket)),
          const SizedBox(height: 8),
          _row(
            'Passing @ ${formatPlainNumber(result.passingRate)}',
            formatPassingAmount(result.passing, showCurrency: true),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, color: AppColors.border),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.successLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    result.resultType.displayLabel,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.success,
                    ),
                  ),
                ),
                Text(
                  formatMoney(result.displayAmount, showCurrency: true),
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.secondaryText,
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: bold ? 16 : 15,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
            color: AppColors.primaryText,
          ),
        ),
      ],
    );
  }
}
