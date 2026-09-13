import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'result_page_theme.dart';

/// Shared tinted row card — same padding/margin as the commission row on Result.
class ResultTintedCard extends StatelessWidget {
  const ResultTintedCard({
    super.key,
    required this.child,
    this.onTap,
    this.tint = ResultTint.commission,
  });

  final Widget child;
  final VoidCallback? onTap;
  final ResultTint tint;

  @override
  Widget build(BuildContext context) {
    final colors = ResultTintColors.forTint(tint);

    final content = Container(
      width: double.infinity,
      padding: ResultTintedCard.padding,
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(ResultPageLayout.cardRadius),
        border: Border.all(color: colors.border),
      ),
      child: child,
    );

    if (onTap == null) return content;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(ResultPageLayout.cardRadius),
        child: content,
      ),
    );
  }

  static const padding = EdgeInsets.symmetric(horizontal: 12, vertical: 10);
}

enum ResultTint { commission, neutral }

class ResultTintColors {
  const ResultTintColors({required this.background, required this.border});

  final Color background;
  final Color border;

  static ResultTintColors forTint(ResultTint tint) {
    switch (tint) {
      case ResultTint.commission:
        return const ResultTintColors(
          background: ResultPageColors.successBg,
          border: ResultPageColors.successBorder,
        );
      case ResultTint.neutral:
        return const ResultTintColors(
          background: ResultPageColors.tintedBg,
          border: ResultPageColors.tintedBorder,
        );
    }
  }
}

/// Standard row: icon + label + trailing widget.
class ResultTintedRow extends StatelessWidget {
  const ResultTintedRow({
    super.key,
    required this.icon,
    required this.label,
    required this.trailing,
    this.iconColor,
    this.labelStyle,
  });

  final IconData icon;
  final String label;
  final Widget trailing;
  final Color? iconColor;
  final TextStyle? labelStyle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: iconColor ?? ResultPageColors.muted),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: labelStyle ??
                GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: ResultPageColors.muted,
                ),
          ),
        ),
        trailing,
      ],
    );
  }
}
