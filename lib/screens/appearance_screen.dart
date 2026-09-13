import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/storage.dart';
import '../theme/app_theme.dart';
import '../widgets/hisab_page_header.dart';

class AppearanceScreen extends StatefulWidget {
  const AppearanceScreen({
    super.key,
    required this.storage,
    required this.initialSettings,
    required this.onChanged,
  });

  final StorageService storage;
  final AppSettings initialSettings;
  final ValueChanged<AppSettings> onChanged;

  @override
  State<AppearanceScreen> createState() => _AppearanceScreenState();
}

class _AppearanceScreenState extends State<AppearanceScreen> {
  late AppSettings _settings;

  @override
  void initState() {
    super.initState();
    _settings = widget.initialSettings;
  }

  Future<void> _setDarkMode(bool darkMode) async {
    final updated = _settings.copyWith(darkMode: darkMode);
    setState(() => _settings = updated);
    await widget.storage.saveSettings(updated);
    widget.onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.canvasDark
          : HisabPageColors.canvas,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HisabPageHeader(
            title: 'Appearance',
            subtitle: 'Theme and display',
            onBack: () => Navigator.pop(context),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.pagePadding),
              children: [
          Text(
            'Theme',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.slateDark : AppColors.slate,
            ),
          ),
          const SizedBox(height: 10),
          _ThemeOption(
            icon: Icons.light_mode_outlined,
            title: 'Light mode',
            subtitle: 'Clean white background',
            selected: !_settings.darkMode,
            onTap: () => _setDarkMode(false),
          ),
          const SizedBox(height: 8),
          _ThemeOption(
            icon: Icons.dark_mode_outlined,
            title: 'Dark mode',
            subtitle: 'Easier on the eyes at night',
            selected: _settings.darkMode,
            onTap: () => _setDarkMode(true),
          ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = selected
        ? AppColors.primary
        : (isDark ? AppColors.hairlineDark : AppColors.hairline);
    final surfaceColor =
        isDark ? AppColors.surfaceDark : AppColors.surface;
    final iconBg =
        isDark ? AppColors.primarySoftDark : AppColors.primarySoft;

    return Material(
      color: surfaceColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: borderColor,
              width: selected ? 2 : 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: iconBg,
                  child: Icon(icon, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: isDark
                              ? AppColors.slateDark
                              : AppColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
                if (selected)
                  const Icon(Icons.check_circle, color: AppColors.primary)
                else
                  Icon(
                    Icons.circle_outlined,
                    color: isDark ? AppColors.slateDark : AppColors.stone,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
