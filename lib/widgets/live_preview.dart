import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/format.dart';
import '../models/calculation_result.dart';
import '../models/settlement_type.dart';
import '../theme/app_theme.dart';

class LivePreview extends StatelessWidget {
  const LivePreview({super.key, this.result});

  final CalculationResult? result;

  @override
  Widget build(BuildContext context) {
    final label = result == null
        ? 'Enter amounts to calculate'
        : '${formatIndianNumber(result!.finalAmount, showCurrency: true)} '
            '${result!.settlementType == SettlementType.lene ? 'Lene Aaj' : 'Dene Aaj'}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            'Preview',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.secondaryText,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.secondaryText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
