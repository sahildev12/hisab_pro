import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

/// Hardcoded HisabPro brand text (no image assets).
class HisabLogo extends StatelessWidget {
  const HisabLogo({
    super.key,
    this.height = 32,
  });

  final double height;

  @override
  Widget build(BuildContext context) {
    final fontSize = height * 0.9;

    return RichText(
      text: TextSpan(
        style: GoogleFonts.inter(
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          height: 1.1,
          letterSpacing: -0.5,
        ),
        children: const [
          TextSpan(
            text: 'Hisab',
            style: TextStyle(color: AppColors.primaryText),
          ),
          TextSpan(
            text: 'Pro',
            style: TextStyle(color: AppColors.primaryBlue),
          ),
        ],
      ),
    );
  }
}
