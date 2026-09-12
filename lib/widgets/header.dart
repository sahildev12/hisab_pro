import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

class Header extends StatelessWidget {
  const Header({super.key, this.onSettingsTap});

  final VoidCallback? onSettingsTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Row(
        children: [
          RichText(
            text: TextSpan(
              style: GoogleFonts.inter(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                height: 1,
              ),
              children: const [
                TextSpan(
                  text: 'Hisab',
                  style: TextStyle(color: AppColors.deepNavy),
                ),
                TextSpan(
                  text: 'Pro',
                  style: TextStyle(color: AppColors.primaryBlue),
                ),
              ],
            ),
          ),
          const Spacer(),
          Material(
            color: AppColors.surface,
            shape: const CircleBorder(side: BorderSide(color: AppColors.border)),
            child: InkWell(
              onTap: onSettingsTap,
              customBorder: const CircleBorder(),
              child: const SizedBox(
                width: 40,
                height: 40,
                child: Icon(
                  Icons.settings_outlined,
                  color: AppColors.secondaryText,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
