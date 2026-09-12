import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

class Header extends StatelessWidget {
  const Header({
    super.key,
    this.onSettingsTap,
    this.onHistoryTap,
  });

  final VoidCallback? onSettingsTap;
  final VoidCallback? onHistoryTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  style: GoogleFonts.inter(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                    letterSpacing: -0.5,
                  ),
                  children: [
                    TextSpan(
                      text: 'Hisab',
                      style: TextStyle(color: appPrimaryTextColor(context)),
                    ),
                    const TextSpan(
                      text: 'Pro',
                      style: TextStyle(color: AppColors.primary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Fast • Accurate • Always Yours',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: appSecondaryTextColor(context),
                ),
              ),
            ],
          ),
        ),
        _headerIconButton(
          context,
          icon: Icons.history_outlined,
          tooltip: 'History',
          onTap: onHistoryTap,
        ),
        const SizedBox(width: 8),
        _headerIconButton(
          context,
          icon: Icons.settings_outlined,
          tooltip: 'Settings',
          onTap: onSettingsTap,
        ),
      ],
    );
  }

  Widget _headerIconButton(
    BuildContext context, {
    required IconData icon,
    required String tooltip,
    required VoidCallback? onTap,
  }) {
    return Material(
      color: appSurfaceColor(context),
      shape: CircleBorder(side: BorderSide(color: appBorderColor(context))),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Tooltip(
          message: tooltip,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(icon, color: AppColors.ink, size: 22),
          ),
        ),
      ),
    );
  }
}
