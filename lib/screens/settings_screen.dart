import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/storage.dart';
import '../models/history_entry.dart';
import '../theme/app_theme.dart';
import 'entry_names_screen.dart';
import 'history_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.storage,
    required this.settings,
    required this.onSettingsChanged,
    required this.onOpenHistoryEntry,
    this.onDeleteHistoryEntry,
  });

  final StorageService storage;
  final AppSettings settings;
  final ValueChanged<AppSettings> onSettingsChanged;
  final ValueChanged<HistoryEntry> onOpenHistoryEntry;
  final ValueChanged<String>? onDeleteHistoryEntry;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late AppSettings _settings;

  @override
  void initState() {
    super.initState();
    _settings = widget.settings;
  }

  @override
  void didUpdateWidget(SettingsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.settings != widget.settings) {
      _settings = widget.settings;
    }
  }

  Future<void> _applySettings(AppSettings updated) async {
    setState(() => _settings = updated);
    await widget.storage.saveSettings(updated);
    widget.onSettingsChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        children: [
          _SettingsTile(
            icon: Icons.list_alt_outlined,
            title: 'Entry Names',
            subtitle: 'Manage custom entry names',
            onTap: () async {
              final updated = await Navigator.push<AppSettings>(
                context,
                MaterialPageRoute(
                  builder: (context) => EntryNamesScreen(
                    initialSettings: _settings,
                  ),
                ),
              );
              if (updated != null) {
                await _applySettings(updated);
              }
            },
          ),
          _SettingsTile(
            icon: Icons.history_outlined,
            title: 'History',
            subtitle: 'View saved calculations',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => HistoryScreen(
                    storage: widget.storage,
                    onEditEntry: widget.onOpenHistoryEntry,
                    onDeleteEntry: widget.onDeleteHistoryEntry,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDarkContext(context)
                  ? AppColors.primarySoftDark
                  : AppColors.primarySoft,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: appBorderColor(context)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AppColors.primaryBlue),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Settings are saved automatically.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: appBorderColor(context)),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isDarkContext(context)
              ? AppColors.primarySoftDark
              : AppColors.primarySoft,
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        title: Text(
          title,
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
