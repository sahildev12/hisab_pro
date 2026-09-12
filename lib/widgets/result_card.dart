import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/format.dart'
    show formatBracket, formatMoney, formatPlainNumber, formatRate;
import '../models/calculation_result.dart';
import '../theme/app_theme.dart';

class ResultCard extends StatefulWidget {
  const ResultCard({
    super.key,
    required this.title,
    required this.result,
  });

  final String title;
  final CalculationResult result;

  @override
  State<ResultCard> createState() => _ResultCardState();
}

class _ResultCardState extends State<ResultCard> {
  bool _showDetails = true;

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    final label = result.resultType.displayLabel;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.title.trim().isEmpty ? 'Calculation' : widget.title.trim(),
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryText,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        Container(
          decoration: surfaceDecoration(context),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _breakdownRow(
                'Total Amount',
                formatMoney(result.totalAmount, showCurrency: true),
              ),
              const SizedBox(height: 10),
              _breakdownRow(
                'Amount Deduction @ ${formatRate(result.amountDeductionRate)}',
                formatMoney(result.amountDeduction, showCurrency: true),
              ),
              const SizedBox(height: 10),
              _breakdownRow(
                'Net Total Amount',
                formatMoney(result.netTotalAmount, showCurrency: true),
                bold: true,
              ),
              const SizedBox(height: 10),
              _breakdownRow(
                'Total Bracket',
                formatBracket(result.totalBracket),
              ),
              const SizedBox(height: 10),
              _breakdownRow(
                'Passing @ ${formatPlainNumber(result.passingRate)}',
                formatMoney(result.passing, showCurrency: true),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
          decoration: BoxDecoration(
            color: AppColors.successLight,
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            border: Border.all(
              color: AppColors.success.withValues(alpha: 0.25),
            ),
          ),
          child: Column(
            children: [
              Text(
                label.toUpperCase(),
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.success,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                formatMoney(result.displayAmount, showCurrency: true),
                style: GoogleFonts.inter(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: surfaceDecoration(context),
          child: Column(
            children: [
              InkWell(
                onTap: () => setState(() => _showDetails = !_showDetails),
                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Text(
                        'Calculation Details',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: AppColors.primaryText,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        _showDetails
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: AppColors.secondaryText,
                      ),
                    ],
                  ),
                ),
              ),
              if (_showDetails)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: appSurfaceSoftColor(context),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _detailsText(result),
                      style: GoogleFonts.robotoMono(
                        fontSize: 13,
                        height: 1.6,
                        color: AppColors.primaryText,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  String _detailsText(CalculationResult result) {
    return '''
${formatPlainNumber(result.totalAmount)} × ${formatPlainNumber(result.amountDeductionRate)}% = ${formatPlainNumber(result.amountDeduction)}

${formatPlainNumber(result.totalAmount)} − ${formatPlainNumber(result.amountDeduction)} = ${formatPlainNumber(result.netTotalAmount)}

${formatPlainNumber(result.totalBracket)} × ${formatPlainNumber(result.passingRate)} = ${formatMoney(result.passing, showCurrency: false)}

${formatMoney(result.netTotalAmount, showCurrency: false)} − ${formatMoney(result.passing, showCurrency: false)} = ${formatMoney(result.displayAmount, showCurrency: false)}''';
  }

  Widget _breakdownRow(
    String label,
    String value, {
    bool bold = false,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: bold ? FontWeight.w600 : FontWeight.w500,
              color: AppColors.secondaryText,
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: bold ? 16 : 15,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
            color: valueColor ?? AppColors.primaryText,
          ),
        ),
      ],
    );
  }
}
