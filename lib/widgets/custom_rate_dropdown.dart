import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/calculate.dart';
import '../theme/app_theme.dart';

class CustomRateDropdown extends StatelessWidget {
  const CustomRateDropdown({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<int>(
      initialValue: value,
      onSelected: onChanged,
      offset: const Offset(0, 44),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      color: AppColors.surface,
      elevation: 4,
      itemBuilder: (context) => bracketRateOptions
          .map(
            (rate) => PopupMenuItem(
              value: rate,
              child: Text(
                '$rate%',
                style: GoogleFonts.inter(
                  fontWeight: rate == value ? FontWeight.w700 : FontWeight.w500,
                  color: AppColors.primaryText,
                ),
              ),
            ),
          )
          .toList(),
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$value%',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryText,
              ),
            ),
            const SizedBox(width: 2),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 20,
              color: AppColors.secondaryText,
            ),
          ],
        ),
      ),
    );
  }
}
