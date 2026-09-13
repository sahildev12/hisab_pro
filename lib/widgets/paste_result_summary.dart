import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/format.dart';
import '../core/money.dart';
import '../models/calculation_result.dart';
import '../theme/app_theme.dart';

class PasteResultSummary extends StatelessWidget {
  const PasteResultSummary({super.key, required this.result});

  final CalculationResult result;

  static const _labelWidth = 11;

  String _label(String text) => text.padRight(_labelWidth);

  String _plain(Decimal value) => formatPlainNumber(roundMoney(value));

  TextStyle _baseStyle() => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: Colors.white,
        height: 1.65,
      );

  TextSpan _span(String text, {bool underline = false}) {
    return TextSpan(
      text: text,
      style:
          underline ? const TextStyle(decoration: TextDecoration.underline) : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final netTotal = _plain(result.netTotalAmount);
    final passing = _plain(result.passing);
    final displayAmount = _plain(result.displayAmount);
    final resultLabel = '${result.resultType.displayLabel.toLowerCase()}.';

    final totalLine = result.commissionTracking
        ? TextSpan(
            children: [
              _span(_label('TOTAL')),
              _span(_plain(result.totalAmount), underline: true),
            ],
          )
        : TextSpan(
            children: [
              _span(_label('TOTAL')),
              _span(_plain(result.totalAmount), underline: true),
              _span(' - ${_plain(result.commissionEarned)} = $netTotal'),
            ],
          );

    final passingLine = TextSpan(
      children: [
        _span(_label('PASSING')),
        _span(
          '${_plain(result.totalBracket)} × ${_plain(result.passingRate)} = $passing',
        ),
      ],
    );

    final finalLine = TextSpan(
      children: [
        _span('$netTotal - $passing', underline: true),
        _span(' = $displayAmount $resultLabel'),
      ],
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFF2F3136),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      child: DefaultTextStyle(
        style: _baseStyle(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(text: totalLine),
            const SizedBox(height: 6),
            RichText(text: passingLine),
            const SizedBox(height: 6),
            RichText(text: finalLine),
          ],
        ),
      ),
    );
  }
}
