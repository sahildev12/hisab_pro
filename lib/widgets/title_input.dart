import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

class TitleInput extends StatelessWidget {
  const TitleInput({
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
        Text('Calculation Title', style: sectionLabelStyle(context)),
        const SizedBox(height: 8),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, value, _) {
            return TextField(
              controller: controller,
              onChanged: onChanged,
              textCapitalization: TextCapitalization.sentences,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.inkDeep,
              ),
              decoration: InputDecoration(
                hintText: 'Enter calculation title',
                hintStyle: GoogleFonts.inter(
                  color: AppColors.stone,
                  fontWeight: FontWeight.w400,
                ),
                prefixIcon: const Icon(
                  Icons.title_outlined,
                  size: 20,
                  color: AppColors.slate,
                ),
                suffixIcon: value.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        color: AppColors.slate,
                        onPressed: () {
                          controller.clear();
                          onChanged('');
                        },
                      )
                    : null,
              ),
            );
          },
        ),
      ],
    );
  }
}
