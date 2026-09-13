import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/format.dart';
import '../../models/calculation_result.dart';
import 'result_page_theme.dart';
import 'result_tinted_card.dart';

class ResultCommissionCard extends StatelessWidget {
  const ResultCommissionCard({
    super.key,
    required this.result,
  });

  final CalculationResult result;

  @override
  Widget build(BuildContext context) {
    if (!result.commissionTracking) {
      return const SizedBox.shrink();
    }

    return ResultTintedCard(
      tint: ResultTint.commission,
      child: ResultTintedRow(
        icon: Icons.account_balance_wallet_outlined,
        iconColor: ResultPageColors.success,
        label: 'Commission',
        trailing: Text(
          formatMoney(result.commissionEarned, showCurrency: true),
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: ResultPageColors.success,
          ),
        ),
      ),
    );
  }
}
