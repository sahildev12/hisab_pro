import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Shared page chrome — blends with canvas; back + title sit together on the left.
class HisabPageColors {
  static const canvas = Color(0xFFF7F9FC);
  static const navy = Color(0xFF17365D);
  static const muted = Color(0xFF64748B);
  static const border = Color(0xFFE2E8F0);
  static const danger = Color(0xFFDC2626);
}

class HisabPageHeader extends StatelessWidget {
  const HisabPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onBack,
    this.actions = const [],
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onBack;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: HisabPageColors.canvas,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (onBack != null)
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  color: HisabPageColors.navy,
                  iconSize: 22,
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),
                  onPressed: onBack,
                )
              else
                const SizedBox(width: 8),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: HisabPageColors.navy,
                          height: 1.2,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: HisabPageColors.muted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              ...actions,
            ],
          ),
        ),
      ),
    );
  }
}

class HisabHeaderIconButton extends StatelessWidget {
  const HisabHeaderIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.color,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      icon: Icon(icon, size: 22, color: color ?? HisabPageColors.navy),
      padding: const EdgeInsets.all(8),
      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
    );
  }
}

Future<void> showHisabHeaderMenu({
  required BuildContext context,
  required RelativeRect position,
  required List<HisabMenuItem> items,
}) async {
  final selected = await showMenu<String>(
    context: context,
    position: position,
    color: Colors.white,
    elevation: 8,
    shadowColor: Colors.black.withValues(alpha: 0.08),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: const BorderSide(color: HisabPageColors.border),
    ),
    items: items
        .map(
          (item) => PopupMenuItem<String>(
            value: item.value,
            height: 44,
            child: Row(
              children: [
                Icon(
                  item.icon,
                  size: 18,
                  color: item.destructive
                      ? HisabPageColors.danger
                      : HisabPageColors.muted,
                ),
                const SizedBox(width: 10),
                Text(
                  item.label,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: item.destructive
                        ? HisabPageColors.danger
                        : HisabPageColors.navy,
                  ),
                ),
              ],
            ),
          ),
        )
        .toList(),
  );

  if (selected == null) return;

  final item = items.firstWhere((entry) => entry.value == selected);
  WidgetsBinding.instance.addPostFrameCallback((_) {
    item.onTap();
  });
}

class HisabMenuItem {
  const HisabMenuItem({
    required this.value,
    required this.label,
    required this.icon,
    required this.onTap,
    this.destructive = false,
  });

  final String value;
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool destructive;
}
