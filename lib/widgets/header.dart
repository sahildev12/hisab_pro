import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'hisab_logo.dart';

class Header extends StatelessWidget {
  const Header({
    super.key,
    this.onSettingsTap,
    this.onHistoryTap,
    this.onCommissionTap,
  });

  final VoidCallback? onSettingsTap;
  final VoidCallback? onHistoryTap;
  final VoidCallback? onCommissionTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: HisabLogo(height: 30),
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
          icon: Icons.currency_rupee_rounded,
          tooltip: 'Total Commission',
          onTap: onCommissionTap,
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
