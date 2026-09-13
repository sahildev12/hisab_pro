import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

class GroupAvatar extends StatelessWidget {
  const GroupAvatar({
    super.key,
    required this.name,
    this.colorValue,
    this.size = 48,
  });

  final String name;
  final int? colorValue;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = Color(colorValue ?? 0xFF2563EB);
    final initial = name.trim().isNotEmpty
        ? name.trim().characters.first.toUpperCase()
        : '?';

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: GoogleFonts.inter(
          fontSize: size * 0.38,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
