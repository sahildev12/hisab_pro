import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/format.dart';
import '../models/calculation_result.dart';
import '../models/settlement_type.dart';
import '../theme/app_theme.dart';

class QuickSummaryStrip extends StatelessWidget {
  const QuickSummaryStrip({super.key, required this.result});

  final CalculationResult result;

  @override
  Widget build(BuildContext context) {
    final leneLabel =
        result.settlementType == SettlementType.lene ? 'Lene' : 'Dene';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: surfaceDecoration(),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _cell(
                  'Total',
                  formatIndianNumber(result.totalAmount, showCurrency: true),
                  AppColors.primaryBlue,
                ),
              ),
              Container(width: 1, height: 40, color: AppColors.border),
              Expanded(
                child: _cell(
                  'Bracket',
                  formatIndianNumber(result.totalBracket),
                  AppColors.primaryText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _cell(
                  'Passing',
                  formatIndianNumber(result.passing, showCurrency: true),
                  AppColors.warning,
                ),
              ),
              Container(width: 1, height: 40, color: AppColors.border),
              Expanded(
                child: _cell(
                  leneLabel,
                  formatIndianNumber(result.finalAmount, showCurrency: true),
                  AppColors.success,
                  highlight: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _cell(
    String label,
    String value,
    Color color, {
    bool highlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: highlight
          ? BoxDecoration(
              color: AppColors.successLight,
              borderRadius: BorderRadius.circular(10),
            )
          : null,
      child: Column(
        children: [
          Text(
            label.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.secondaryText,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: highlight ? 18 : 16,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
