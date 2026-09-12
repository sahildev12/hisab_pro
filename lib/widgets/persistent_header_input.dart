import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

/// Persistent header text (labeled "Date") — never cleared by calculation actions.
class PersistentHeaderInput extends StatelessWidget {
  const PersistentHeaderInput({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Date', style: sectionLabelStyle(context)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          onChanged: onChanged,
          textCapitalization: TextCapitalization.sentences,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.inkDeep,
          ),
          decoration: InputDecoration(
            hintText: 'Enter date or label',
            hintStyle: GoogleFonts.inter(
              color: AppColors.stone,
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: const Icon(
              Icons.calendar_today_outlined,
              size: 18,
              color: AppColors.slate,
            ),
          ),
        ),
      ],
    );
  }
}
