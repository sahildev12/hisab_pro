import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/format.dart';
import '../../models/calculation_result.dart';
import 'result_page_theme.dart';

class ResultHeroCard extends StatelessWidget {
  const ResultHeroCard({super.key, required this.result});

  final CalculationResult result;

  @override
  Widget build(BuildContext context) {
    final type = result.resultType;
    final accent = ResultPageStyle.accentFor(type);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: ResultPageLayout.cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: ResultPageStyle.accentBgFor(type),
              shape: BoxShape.circle,
            ),
            child: Icon(
              ResultPageStyle.iconFor(type),
              size: 24,
              color: accent,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type.copyLabel,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                    color: accent,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  formatMoney(result.displayAmount, showCurrency: true),
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: accent,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
