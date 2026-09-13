import 'dart:convert';

import 'package:decimal/decimal.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/calculation_group.dart';
import '../models/history_entry.dart';
import '../models/row_data.dart';
import 'calculate.dart' as calc;
import 'money.dart';

const _draftKey = 'hisabpro-draft';
const _legacyCalculationKey = 'hisabpro-v1';
const _settingsKey = 'hisabpro-settings';
const _historyKey = 'hisabpro-history';
const _persistentHeaderKey = 'hisabpro-persistent-header';
const _commissionBalancesKey = 'hisabpro-commission-balances';
const _groupsKey = 'hisabpro-groups';
const _groupDraftPrefix = 'hisabpro-group-draft-';
const _pasteCalculationDraftKey = 'hisabpro-paste-calculation-draft';
const historyRetentionDays = 35;

class AppSettings {
  const AppSettings({
    required this.defaultPassingRate,
    required this.defaultAmountDeductionRate,
    this.defaultCommissionTracking = false,
    this.customEntryNames = const [],
    this.darkMode = false,
  });

  final Decimal defaultPassingRate;
  final Decimal defaultAmountDeductionRate;
  final bool defaultCommissionTracking;
  final List<String> customEntryNames;
  final bool darkMode;

  Map<String, dynamic> toJson() => {
        'defaultPassingRate': defaultPassingRate.toString(),
        'defaultAmountDeductionRate': defaultAmountDeductionRate.toString(),
        'defaultCommissionTracking': defaultCommissionTracking,
        'customEntryNames': customEntryNames,
        'darkMode': darkMode,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    if (json['defaultPassingRate'] != null) {
      final custom = (json['customEntryNames'] as List<dynamic>? ?? [])
          .map((item) => item.toString().trim())
          .where((name) => name.isNotEmpty)
          .toList();
      return AppSettings(
        defaultPassingRate:
            Decimal.parse(json['defaultPassingRate'].toString()),
        defaultAmountDeductionRate: Decimal.parse(
          (json['defaultAmountDeductionRate'] ?? '4').toString(),
        ),
        defaultCommissionTracking:
            json['defaultCommissionTracking'] as bool? ?? false,
        customEntryNames: custom,
        darkMode: json['darkMode'] as bool? ?? false,
      );
    }

    if (json['defaultRate'] != null) {
      final passing = Decimal.parse(json['defaultRate'].toString());
      return AppSettings(
        defaultPassingRate: passing,
        defaultAmountDeductionRate: suggestedAmountDeduction(passing),
      );
    }

    return AppSettings(
      defaultPassingRate: calc.defaultPassingRate,
      defaultAmountDeductionRate: calc.defaultAmountDeductionRate,
    );
  }

  AppSettings copyWith({
    Decimal? defaultPassingRate,
    Decimal? defaultAmountDeductionRate,
    bool? defaultCommissionTracking,
    List<String>? customEntryNames,
    bool? darkMode,
  }) {
    return AppSettings(
      defaultPassingRate: defaultPassingRate ?? this.defaultPassingRate,
      defaultAmountDeductionRate:
          defaultAmountDeductionRate ?? this.defaultAmountDeductionRate,
      defaultCommissionTracking:
          defaultCommissionTracking ?? this.defaultCommissionTracking,
      customEntryNames: customEntryNames ?? this.customEntryNames,
      darkMode: darkMode ?? this.darkMode,
    );
  }
}

class DraftState {
  DraftState({
    required this.title,
    required this.rows,
    required this.passingRate,
    required this.amountDeductionRate,
    this.lastView = 'main',
    this.historyEntryId,
    this.updatedAt,
    this.commissionTracking = false,
    this.groupId,
    this.originalPastedText,
  });

  final String title;
  final List<RowData> rows;
  final Decimal passingRate;
  final Decimal amountDeductionRate;
  final String lastView;
  final String? historyEntryId;
  final DateTime? updatedAt;
  final bool commissionTracking;
  final String? groupId;
  final String? originalPastedText;

  Map<String, dynamic> toJson() => {
        'title': title,
        'rows': rows.map((row) => row.toJson()).toList(),
        'passingRate': passingRate.toString(),
        'amountDeductionRate': amountDeductionRate.toString(),
        'lastView': lastView,
        if (historyEntryId != null) 'historyEntryId': historyEntryId,
        if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
        'commissionTracking': commissionTracking,
        if (groupId != null) 'groupId': groupId,
        if (originalPastedText != null)
          'originalPastedText': originalPastedText,
      };

  factory DraftState.fromJson(
    Map<String, dynamic> json, {
    Decimal? fallbackPassingRate,
    Decimal? fallbackAmountDeductionRate,
  }) {
    final resolvedPassing = fallbackPassingRate ?? calc.defaultPassingRate;
    final resolvedDeduction =
        fallbackAmountDeductionRate ?? calc.defaultAmountDeductionRate;
    final rawRows = json['rows'] as List<dynamic>? ?? [];

    Decimal passingRate;
    Decimal amountDeductionRate;

    if (json['passingRate'] != null) {
      passingRate = Decimal.parse(json['passingRate'].toString());
      amountDeductionRate = json['amountDeductionRate'] != null
          ? Decimal.parse(json['amountDeductionRate'].toString())
          : suggestedAmountDeduction(passingRate);
    } else if (json['rate'] != null) {
      passingRate = Decimal.parse(json['rate'].toString());
      amountDeductionRate = suggestedAmountDeduction(passingRate);
    } else if (json['bracketRate'] != null) {
      passingRate = Decimal.parse(json['bracketRate'].toString());
      amountDeductionRate = suggestedAmountDeduction(passingRate);
    } else {
      passingRate = resolvedPassing;
      amountDeductionRate = resolvedDeduction;
    }

    return DraftState(
      title: json['title'] as String? ?? '',
      rows: rawRows
          .map((item) => RowData.fromJson(item as Map<String, dynamic>))
          .toList(),
      passingRate: passingRate,
      amountDeductionRate: amountDeductionRate,
      lastView: json['lastView'] as String? ?? 'main',
      historyEntryId: json['historyEntryId'] as String?,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      commissionTracking: json['commissionTracking'] as bool? ??
          json['commissionSeparate'] as bool? ??
          false,
      groupId: json['groupId'] as String?,
      originalPastedText: json['originalPastedText'] as String?,
    );
  }

  bool get hasData =>
      title.trim().isNotEmpty ||
      rows.any(
        (row) =>
            row.name.trim().isNotEmpty ||
            row.amount.trim().isNotEmpty ||
            row.bracket.trim().isNotEmpty,
      );

  HistoryEntry toHistoryEntry({
    required String id,
    required String status,
    DateTime? savedAt,
    DateTime? updatedAt,
    Decimal? commissionEarned,
    Decimal? commissionBalanceAtThatTime,
    String? groupId,
    String? originalPastedText,
  }) {
    final now = DateTime.now();
    return HistoryEntry(
      id: id,
      title: title,
      rows: rows,
      passingRate: passingRate,
      amountDeductionRate: amountDeductionRate,
      savedAt: savedAt ?? updatedAt ?? now,
      updatedAt: updatedAt ?? now,
      status: status,
      commissionTracking: commissionTracking,
      commissionEarned: commissionEarned,
      commissionBalanceAtThatTime: commissionBalanceAtThatTime,
      groupId: groupId ?? this.groupId,
      originalPastedText: originalPastedText ?? this.originalPastedText,
    );
  }
}

class StorageService {
  Future<AppSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_settingsKey);
    if (raw == null || raw.isEmpty) {
      return AppSettings(
        defaultPassingRate: calc.defaultPassingRate,
        defaultAmountDeductionRate: calc.defaultAmountDeductionRate,
      );
    }
    try {
      final jsonMap = jsonDecode(raw) as Map<String, dynamic>;
      final settings = AppSettings.fromJson(jsonMap);
      final needsMigration = jsonMap['defaultPassingRate'] == null;
      if (needsMigration) {
        await saveSettings(settings);
      }
      return settings;
    } catch (_) {
      return AppSettings(
        defaultPassingRate: calc.defaultPassingRate,
        defaultAmountDeductionRate: calc.defaultAmountDeductionRate,
      );
    }
  }

  Future<void> saveSettings(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_settingsKey, jsonEncode(settings.toJson()));
  }

  Future<DraftState?> loadDraft({
    Decimal? fallbackPassingRate,
    Decimal? fallbackAmountDeductionRate,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    var raw = prefs.getString(_draftKey);

    if (raw == null || raw.isEmpty) {
      raw = prefs.getString(_legacyCalculationKey);
    }

    if (raw == null || raw.isEmpty) {
      return null;
    }

    final settings = await loadSettings();
    final passingFallback = fallbackPassingRate ?? settings.defaultPassingRate;
    final deductionFallback =
        fallbackAmountDeductionRate ?? settings.defaultAmountDeductionRate;

    try {
      final jsonMap = jsonDecode(raw) as Map<String, dynamic>;
      final state = DraftState.fromJson(
        jsonMap,
        fallbackPassingRate: passingFallback,
        fallbackAmountDeductionRate: deductionFallback,
      );

      final needsMigration =
          jsonMap['passingRate'] == null || prefs.getString(_draftKey) == null;
      if (needsMigration) {
        await saveDraft(state);
        await prefs.remove(_legacyCalculationKey);
      }

      return state;
    } catch (_) {
      return null;
    }
  }

  Future<void> saveDraft(DraftState state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_draftKey, jsonEncode(state.toJson()));
  }

  Future<void> clearDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_draftKey);
    await prefs.remove(_legacyCalculationKey);
  }

  Future<String?> loadPasteCalculationDraft() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_pasteCalculationDraftKey);
  }

  Future<void> savePasteCalculationDraft(String text) async {
    final prefs = await SharedPreferences.getInstance();
    if (text.trim().isEmpty) {
      await prefs.remove(_pasteCalculationDraftKey);
      return;
    }
    await prefs.setString(_pasteCalculationDraftKey, text);
  }

  Future<void> clearPasteCalculationDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pasteCalculationDraftKey);
  }

  Future<List<HistoryEntry>> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_historyKey);
    if (raw == null || raw.isEmpty) return [];

    try {
      final list = jsonDecode(raw) as List<dynamic>;
      final cutoff = DateTime.now().subtract(
        const Duration(days: historyRetentionDays),
      );
      final entries = list
          .map((item) => HistoryEntry.fromJson(item as Map<String, dynamic>))
          .where((entry) => entry.savedAt.isAfter(cutoff))
          .toList()
        ..sort((a, b) => b.savedAt.compareTo(a.savedAt));

      if (entries.length != list.length) {
        await saveHistory(entries);
      }

      return entries;
    } catch (_) {
      return [];
    }
  }

  Future<void> saveHistory(List<HistoryEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = entries.map((entry) => entry.toJson()).toList();
    await prefs.setString(_historyKey, jsonEncode(encoded));
  }

  Future<void> addToHistory(HistoryEntry entry) async {
    await upsertHistoryEntry(entry);
  }

  Future<void> upsertHistoryEntry(HistoryEntry entry) async {
    final history = await loadHistory();
    final index = history.indexWhere((item) => item.id == entry.id);
    if (index >= 0) {
      history[index] = entry;
    } else {
      history.insert(0, entry);
    }
    history.sort((a, b) => b.savedAt.compareTo(a.savedAt));
    await saveHistory(history);
  }

  Future<HistoryEntry?> loadActiveDraftEntry() async {
    final draft = await loadDraft();
    if (draft == null || !draft.hasData) return null;

    final history = await loadHistory();
    final id = draft.historyEntryId ?? HistoryEntry.activeDraftId;
    HistoryEntry? existing;
    for (final entry in history) {
      if (entry.id == id) {
        existing = entry;
        break;
      }
    }

    if (existing != null &&
        existing.status == HistoryEntry.completedStatus &&
        draft.lastView == 'results') {
      return null;
    }

    final savedAt = existing?.savedAt ?? draft.updatedAt ?? DateTime.now();
    final status = draft.lastView == 'results'
        ? HistoryEntry.completedStatus
        : HistoryEntry.draftStatus;

    return draft.toHistoryEntry(
      id: id,
      status: status,
      savedAt: savedAt,
      updatedAt: draft.updatedAt ?? DateTime.now(),
    );
  }

  Future<void> deleteFromHistory(String id) async {
    final history = await loadHistory();
    history.removeWhere((entry) => entry.id == id);
    await saveHistory(history);
  }

  Future<String> loadPersistentHeader() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_persistentHeaderKey) ?? '';
  }

  Future<void> savePersistentHeader(String text) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_persistentHeaderKey, text);
  }

  Future<Map<String, Decimal>> loadCommissionBalances() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_commissionBalancesKey);
    if (raw == null || raw.isEmpty) return {};

    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return map.map(
        (key, value) => MapEntry(key, Decimal.parse(value.toString())),
      );
    } catch (_) {
      return {};
    }
  }

  Future<Decimal> getCommissionBalance(String ownerId) async {
    final balances = await loadCommissionBalances();
    return balances[ownerId] ?? Decimal.zero;
  }

  Future<void> setCommissionBalance(String ownerId, Decimal balance) async {
    final balances = await loadCommissionBalances();
    if (balance <= Decimal.zero) {
      balances.remove(ownerId);
    } else {
      balances[ownerId] = balance;
    }

    final prefs = await SharedPreferences.getInstance();
    final encoded = balances.map(
      (key, value) => MapEntry(key, value.toString()),
    );
    await prefs.setString(_commissionBalancesKey, jsonEncode(encoded));
  }

  Future<void> clearCommissionBalance(String ownerId) async {
    await setCommissionBalance(ownerId, Decimal.zero);
  }

  // ── Groups ──────────────────────────────────────────────────────────────

  Future<List<CalculationGroup>> loadGroups() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_groupsKey);
    if (raw == null || raw.isEmpty) return [];

    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map(
            (item) =>
                CalculationGroup.fromJson(item as Map<String, dynamic>),
          )
          .toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    } catch (_) {
      return [];
    }
  }

  Future<void> saveGroups(List<CalculationGroup> groups) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = groups.map((g) => g.toJson()).toList();
    await prefs.setString(_groupsKey, jsonEncode(encoded));
  }

  Future<void> upsertGroup(CalculationGroup group) async {
    final groups = await loadGroups();
    final index = groups.indexWhere((g) => g.id == group.id);
    if (index >= 0) {
      groups[index] = group;
    } else {
      groups.insert(0, group);
    }
    groups.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    await saveGroups(groups);
  }

  Future<void> deleteGroup(String groupId) async {
    final groups = await loadGroups();
    groups.removeWhere((g) => g.id == groupId);
    await saveGroups(groups);

    final history = await loadHistory();
    history.removeWhere((e) => e.groupId == groupId);
    await saveHistory(history);

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_groupDraftPrefix$groupId');
  }

  Future<DraftState?> loadGroupDraft(
    String groupId, {
    Decimal? fallbackPassingRate,
    Decimal? fallbackAmountDeductionRate,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_groupDraftPrefix$groupId');
    if (raw == null || raw.isEmpty) return null;

    try {
      final jsonMap = jsonDecode(raw) as Map<String, dynamic>;
      return DraftState.fromJson(
        jsonMap,
        fallbackPassingRate: fallbackPassingRate,
        fallbackAmountDeductionRate: fallbackAmountDeductionRate,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> saveGroupDraft(String groupId, DraftState state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_groupDraftPrefix$groupId',
      jsonEncode(state.toJson()),
    );
  }

  Future<void> clearGroupDraft(String groupId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_groupDraftPrefix$groupId');
  }

  Future<List<HistoryEntry>> loadGroupHistory(String groupId) async {
    final all = await loadHistory();
    return all.where((e) => e.groupId == groupId).toList();
  }

  Future<void> migrateLegacyToDefaultGroup() async {
    final existing = await loadGroups();
    if (existing.isNotEmpty) return;

    final settings = await loadSettings();
    final group = CalculationGroup.create(
      name: 'My Calculations',
      passingRate: settings.defaultPassingRate,
      amountDeductionRate: settings.defaultAmountDeductionRate,
    );
    await upsertGroup(group);

    final legacyDraft = await loadDraft(
      fallbackPassingRate: settings.defaultPassingRate,
      fallbackAmountDeductionRate: settings.defaultAmountDeductionRate,
    );
    if (legacyDraft != null && legacyDraft.hasData) {
      await saveGroupDraft(
        group.id,
        DraftState(
          title: legacyDraft.title,
          rows: legacyDraft.rows,
          passingRate: legacyDraft.passingRate,
          amountDeductionRate: legacyDraft.amountDeductionRate,
          lastView: legacyDraft.lastView,
          historyEntryId: legacyDraft.historyEntryId,
          updatedAt: legacyDraft.updatedAt,
          commissionTracking: legacyDraft.commissionTracking,
          groupId: group.id,
        ),
      );
      await clearDraft();
    }

    final history = await loadHistory();
    var migrated = false;
    for (var i = 0; i < history.length; i++) {
      if (history[i].groupId == null) {
        history[i] = history[i].copyWith(groupId: group.id);
        migrated = true;
      }
    }
    if (migrated) {
      await saveHistory(history);
    }
  }
}
