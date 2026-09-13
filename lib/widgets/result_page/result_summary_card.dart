import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/format.dart';
import '../../models/calculation_result.dart';
import 'result_page_shared.dart';
import 'result_page_theme.dart';

class ResultSummaryCard extends StatelessWidget {
  const ResultSummaryCard({super.key, required this.result});

  final CalculationResult result;

  @override
  Widget build(BuildContext context) {
    final accent = ResultPageStyle.accentFor(result.resultType);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: ResultPageLayout.cardDecoration(),
      child: Column(
        children: [
          ResultAlignedRow(
            label: 'Total Amount',
            value: formatMoney(result.totalAmount, showCurrency: true),
            icon: Icons.payments_outlined,
            iconColor: ResultPageColors.iconBlue,
            minHeight: 34,
          ),
          const SizedBox(height: 4),
          ResultAlignedRow(
            label: 'Total Bracket',
            value: formatBracket(result.totalBracket),
            icon: Icons.tag_outlined,
            iconColor: ResultPageColors.iconPurple,
            minHeight: 34,
          ),
          const SizedBox(height: 4),
          ResultAlignedRow(
            label: 'Passing @ ${formatPlainNumber(result.passingRate)}',
            value: formatMoney(result.passing, showCurrency: true),
            icon: Icons.percent_outlined,
            iconColor: ResultPageColors.iconOrange,
            minHeight: 34,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(height: 1, color: ResultPageColors.border),
          ),
          ResultAlignedRow(
            label: 'Difference',
            subtitle: '(Total − Passing)',
            value: _formatSignedDifference(result.finalBalance),
            icon: Icons.calculate_outlined,
            iconColor: accent,
            minHeight: 38,
            valueStyle: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }

  String _formatSignedDifference(Decimal value) {
    if (value == Decimal.zero) {
      return formatMoney(Decimal.zero, showCurrency: true);
    }
    final sign = value > Decimal.zero ? '' : '-';
    return '$sign${formatMoney(value.abs(), showCurrency: true)}';
  }
}
