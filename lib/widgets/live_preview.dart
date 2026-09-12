import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/format.dart';
import '../models/calculation_result.dart';
import '../theme/app_theme.dart';

class LivePreview extends StatelessWidget {
  const LivePreview({super.key, this.result});

  final CalculationResult? result;

  @override
  Widget build(BuildContext context) {
    if (result == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          '${formatMoney(result!.displayAmount, showCurrency: true)} '
          '${result!.resultType.displayLabel}',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
        ),
      ),
    );
  }
}
