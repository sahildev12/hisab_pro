import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'result_page_theme.dart';

/// Two-column label/value row with optional leading icon.
class ResultAlignedRow extends StatelessWidget {
  const ResultAlignedRow({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.iconColor,
    this.labelStyle,
    this.valueStyle,
    this.subtitle,
    this.minHeight = ResultPageLayout.rowHeight,
  });

  final String label;
  final String value;
  final IconData? icon;
  final Color? iconColor;
  final TextStyle? labelStyle;
  final TextStyle? valueStyle;
  final String? subtitle;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    final defaultLabel = GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: ResultPageColors.muted,
      height: 1.2,
    );
    final defaultValue = GoogleFonts.inter(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      color: ResultPageColors.navy,
      height: 1.2,
    );

    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: minHeight),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: iconColor ?? ResultPageColors.muted),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label, style: labelStyle ?? defaultLabel),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: ResultPageColors.muted.withValues(alpha: 0.9),
                      height: 1.2,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            textAlign: TextAlign.right,
            style: valueStyle ?? defaultValue,
          ),
        ],
      ),
    );
  }
}

/// Formula row with aligned result column (no leading equals sign).
class ResultFormulaRow extends StatelessWidget {
  const ResultFormulaRow({
    super.key,
    required this.label,
    required this.formula,
    required this.result,
    this.resultStyle,
  });

  final String label;
  final String formula;
  final String result;
  final TextStyle? resultStyle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: ResultPageColors.muted,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                formula,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: ResultPageColors.navy,
                  height: 1.35,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              result,
              textAlign: TextAlign.right,
              style: resultStyle ??
                  GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: ResultPageColors.navy,
                    height: 1.35,
                  ),
            ),
          ],
        ),
      ],
    );
  }
}
