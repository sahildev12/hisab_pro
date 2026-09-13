import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../constants/entry_names.dart';
import '../core/format.dart';
import '../core/history_helpers.dart';
import '../core/storage.dart';
import '../models/calculation_group.dart';
import '../models/history_entry.dart';
import '../theme/app_theme.dart';
import '../widgets/group_avatar.dart';
import '../widgets/hisab_logo.dart';
import 'create_group_screen.dart';
import 'group_session_screen.dart';
import 'settings_screen.dart';
import 'smart_calculator_screen.dart';

class GroupListSummary {
  const GroupListSummary({
    this.subtitle = '',
    this.preview = '',
    this.isDraft = false,
    this.draftRowCount = 0,
    this.updatedAt,
  });

  final String subtitle;
  final String preview;
  final bool isDraft;
  final int draftRowCount;
  final DateTime? updatedAt;
}

class GroupsHomeScreen extends StatefulWidget {
  const GroupsHomeScreen({
    super.key,
    required this.storage,
    required this.settings,
    required this.onSettingsChanged,
  });

  final StorageService storage;
  final AppSettings settings;
  final ValueChanged<AppSettings> onSettingsChanged;

  @override
  State<GroupsHomeScreen> createState() => _GroupsHomeScreenState();
}

class _GroupsHomeScreenState extends State<GroupsHomeScreen> {
  List<CalculationGroup> _groups = [];
  final Map<String, GroupListSummary> _summaries = {};
  bool _loading = true;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await widget.storage.migrateLegacyToDefaultGroup();
    await _reload();
  }

  Future<void> _reload() async {
    final groups = await widget.storage.loadGroups();
    final history = await widget.storage.loadHistory();
    final summaries = <String, GroupListSummary>{};

    for (final group in groups) {
      summaries[group.id] = await _summaryForGroup(group, history);
    }

    if (!mounted) return;
    setState(() {
      _groups = groups;
      _summaries
        ..clear()
        ..addAll(summaries);
      _loading = false;
    });
  }

  Future<GroupListSummary> _summaryForGroup(
    CalculationGroup group,
    List<HistoryEntry> history,
  ) async {
    final draft = await widget.storage.loadGroupDraft(
      group.id,
      fallbackPassingRate: group.passingRate,
      fallbackAmountDeductionRate: group.amountDeductionRate,
    );

    final groupHistory = history
        .where((e) => e.groupId == group.id && !e.isDraft)
        .toList();

    if (draft != null && draft.hasData && draft.lastView != 'results') {
      final rowCount =
          draft.rows.where((r) => r.name.isNotEmpty || r.amount.isNotEmpty).length;
      return GroupListSummary(
        subtitle:
            '${group.passingRate.toStringAsFixed(0)}% • ${group.amountDeductionRate.toStringAsFixed(0)}%',
        preview: 'Draft • $rowCount rows',
        isDraft: true,
        draftRowCount: rowCount,
        updatedAt: draft.updatedAt,
      );
    }

    HistoryEntry? latest;
    for (final entry in groupHistory) {
      if (latest == null || entry.savedAt.isAfter(latest.savedAt)) {
        latest = entry;
      }
    }

    if (latest != null) {
      final item = HistoryDisplayItem.fromEntry(latest);
      final resultLabel = item.result?.resultType.displayLabel ?? '';
      final amount = item.result != null
          ? formatMoney(item.result!.displayAmount, showCurrency: true)
          : '';
      return GroupListSummary(
        subtitle:
            '${group.passingRate.toStringAsFixed(0)}% • ${group.amountDeductionRate.toStringAsFixed(0)}%',
        preview: [resultLabel, amount].where((s) => s.isNotEmpty).join(' '),
        updatedAt: latest.updatedAt ?? latest.savedAt,
      );
    }

    return GroupListSummary(
      subtitle:
          '${group.passingRate.toStringAsFixed(0)}% • ${group.amountDeductionRate.toStringAsFixed(0)}%',
      preview: 'No calculations yet',
      updatedAt: group.updatedAt,
    );
  }

  List<CalculationGroup> get _filteredGroups {
    if (_search.trim().isEmpty) return _groups;
    final q = _search.trim().toLowerCase();
    return _groups.where((g) => g.name.toLowerCase().contains(q)).toList();
  }

  String _formatTime(DateTime? time) {
    if (time == null) return '';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(time.year, time.month, time.day);
    if (day == today) {
      return DateFormat.jm().format(time);
    }
    if (day == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    }
    return DateFormat('d MMM').format(time);
  }

  Future<void> _openCreateGroup() async {
    final group = await Navigator.push<CalculationGroup>(
      context,
      MaterialPageRoute(
        builder: (context) => CreateGroupScreen(
          storage: widget.storage,
          settings: widget.settings,
        ),
      ),
    );
    if (group != null) await _reload();
  }

  void _openGroup(CalculationGroup group) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GroupSessionScreen(
          storage: widget.storage,
          settings: widget.settings,
          group: group,
          entryNames: allEntryNames(widget.settings.customEntryNames),
          onSettingsChanged: widget.onSettingsChanged,
          onGroupUpdated: _reload,
        ),
      ),
    ).then((_) => _reload());
  }

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SettingsScreen(
          storage: widget.storage,
          settings: widget.settings,
          onSettingsChanged: (s) {
            widget.onSettingsChanged(s);
            setState(() {});
          },
          onOpenHistoryEntry: (_) {},
        ),
      ),
    );
  }

  void _openGlobalSmartCalculator() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SmartCalculatorScreen(
          storage: widget.storage,
          settings: widget.settings,
          groups: _groups,
          entryNames: allEntryNames(widget.settings.customEntryNames),
          onComplete: () => _reload(),
        ),
      ),
    ).then((_) => _reload());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
                    child: Row(
                      children: [
                        const HisabLogo(height: 32),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: _openGlobalSmartCalculator,
                          icon: const Icon(Icons.content_paste_go_outlined, size: 18),
                          label: const Text('Smart'),
                        ),
                        IconButton(
                          onPressed: _openSettings,
                          icon: const Icon(Icons.settings_outlined),
                          tooltip: 'Settings',
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Text(
                      'Calculations',
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryText,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      onChanged: (v) => setState(() => _search = v),
                      decoration: InputDecoration(
                        hintText: 'Search groups',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppSpacing.inputRadius),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: _filteredGroups.isEmpty
                        ? Center(
                            child: Text(
                              _groups.isEmpty
                                  ? 'No groups yet.\nTap + to add your first group.'
                                  : 'No groups match your search.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(color: AppColors.slate),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(8, 0, 8, 88),
                            itemCount: _filteredGroups.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1, indent: 72),
                            itemBuilder: (context, index) {
                              final group = _filteredGroups[index];
                              final summary = _summaries[group.id];
                              return _GroupRow(
                                group: group,
                                summary: summary,
                                timeLabel: _formatTime(summary?.updatedAt),
                                onTap: () => _openGroup(group),
                              );
                            },
                          ),
                  ),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateGroup,
        backgroundColor: AppColors.primaryBlue,
        icon: const Icon(Icons.add),
        label: const Text('Add Group'),
      ),
    );
  }
}

class _GroupRow extends StatelessWidget {
  const _GroupRow({
    required this.group,
    required this.summary,
    required this.timeLabel,
    required this.onTap,
  });

  final CalculationGroup group;
  final GroupListSummary? summary;
  final String timeLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final preview = summary?.preview ?? '';
    final subtitle = summary?.subtitle ?? '';
    final isDraft = summary?.isDraft ?? false;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Row(
            children: [
              GroupAvatar(
                name: group.name,
                colorValue: group.avatarColorValue,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            group.name,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryText,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (timeLabel.isNotEmpty)
                          Text(
                            timeLabel,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.slate,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.slate,
                      ),
                    ),
                    if (preview.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        preview,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: isDraft
                              ? AppColors.primaryBlue
                              : AppColors.charcoal,
                          fontWeight:
                              isDraft ? FontWeight.w600 : FontWeight.w400,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
