import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/format.dart' show formatIndianNumber, formatPlainNumber;
import '../models/calculation_result.dart';
import '../models/settlement_type.dart';
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
    final settlementLabel = result.settlementType == SettlementType.lene
        ? 'Lene Aaj'
        : 'Dene Aaj';
    final bracketText = formatIndianNumber(result.totalBracket);

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
                settlementLabel.toUpperCase(),
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.success,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                formatIndianNumber(result.finalAmount, showCurrency: true),
                style: GoogleFonts.inter(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: surfaceDecoration(),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _breakdownRow(
                'Total Amount',
                formatIndianNumber(result.totalAmount, showCurrency: true),
              ),
              const SizedBox(height: 10),
              _breakdownRow('Total Bracket', bracketText),
              const SizedBox(height: 10),
              _breakdownRow(
                '${result.multiplier}% of Bracket',
                formatIndianNumber(result.passing, showCurrency: true),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Divider(height: 1, color: AppColors.border),
              ),
              _breakdownRow(
                settlementLabel,
                formatIndianNumber(result.finalAmount, showCurrency: true),
                bold: true,
                valueColor: AppColors.success,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: surfaceDecoration(),
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
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _detailsText(result, bracketText, settlementLabel),
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

  String _detailsText(
    CalculationResult result,
    String bracketText,
    String settlementLabel,
  ) {
    return '''
Total Amount
= ${formatPlainNumber(result.totalAmount)}

Total Bracket
= ${formatPlainNumber(result.totalBracket)}

Passing
= ${formatPlainNumber(result.totalBracket)} × ${result.multiplier}
= ${formatPlainNumber(result.passing)}

$settlementLabel
= ${formatPlainNumber(result.totalAmount)} − ${formatPlainNumber(result.passing)}
= ${formatPlainNumber(result.finalAmount)}''';
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
