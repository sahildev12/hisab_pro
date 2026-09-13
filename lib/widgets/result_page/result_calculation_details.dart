import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/format.dart';
import '../../models/calculation_result.dart';
import 'result_page_theme.dart';
import 'result_tinted_card.dart';

class ResultCalculationDetails extends StatefulWidget {
  const ResultCalculationDetails({
    super.key,
    required this.result,
    this.initiallyExpanded = true,
  });

  final CalculationResult result;
  final bool initiallyExpanded;

  @override
  State<ResultCalculationDetails> createState() =>
      _ResultCalculationDetailsState();
}

class _ResultCalculationDetailsState extends State<ResultCalculationDetails> {
  late bool _expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    return ResultTintedCard(
      tint: ResultTint.neutral,
      onTap: () => setState(() => _expanded = !_expanded),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ResultTintedRow(
            icon: Icons.description_outlined,
            iconColor: ResultPageColors.iconBlue,
            label: 'Calculation Details',
            labelStyle: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: ResultPageColors.navy,
            ),
            trailing: Icon(
              _expanded
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              color: ResultPageColors.muted,
              size: 20,
            ),
          ),
          if (_expanded) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Divider(height: 1, color: ResultPageColors.tintedBorder),
            ),
            Text(
              _detailsText(widget.result),
              style: GoogleFonts.robotoMono(
                fontSize: 13,
                height: 1.6,
                color: ResultPageColors.navy,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _detailsText(CalculationResult result) {
    final commissionLine = result.commissionTracking
        ? 'Commission ${formatMoney(result.commissionEarned, showCurrency: false)} (kept separate)'
        : '''${formatPlainNumber(result.totalAmount)} × ${formatPlainNumber(result.amountDeductionRate)}% = ${formatPlainNumber(result.commissionEarned)}

${formatPlainNumber(result.totalAmount)} − ${formatPlainNumber(result.commissionEarned)} = ${formatPlainNumber(result.netTotalAmount)}''';

    return '''
$commissionLine

${formatPlainNumber(result.totalBracket)} × ${formatPlainNumber(result.passingRate)} = ${formatMoney(result.passing, showCurrency: false)}

${formatMoney(result.netTotalAmount, showCurrency: false)} − ${formatMoney(result.passing, showCurrency: false)} = ${formatMoney(result.displayAmount, showCurrency: false)}''';
  }
}
