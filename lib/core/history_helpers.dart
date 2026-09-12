import 'package:intl/intl.dart';

import '../constants/fixed_names.dart';
import '../models/calculation_result.dart';
import '../models/history_entry.dart';
import '../models/result_type.dart';
import '../models/row_data.dart';
import 'calculate.dart';
import 'validate.dart';

List<String> _allowedNamesForRows(List<RowData> rows) {
  final names = <String>{...fixedNames};
  for (final row in rows) {
    final trimmed = row.name.trim();
    if (trimmed.isNotEmpty) names.add(trimmed);
  }
  return names.toList();
}

enum HistoryFilter { all, drafts, lene, dene }

class HistoryDisplayItem {
  const HistoryDisplayItem({
    required this.entry,
    this.result,
  });

  final HistoryEntry entry;
  final CalculationResult? result;

  bool get isDraft => entry.isDraft;

  ResultType? get resultType => result?.resultType;

  int get rowCount =>
      entry.rows.where((row) => !isRowEmpty(row)).length;

  String get displayTitle {
    final trimmed = entry.title.trim();
    if (trimmed.isEmpty) {
      return isDraft ? 'Untitled (Draft)' : 'Calculation';
    }
    if (isDraft && !trimmed.toLowerCase().endsWith('(draft)')) {
      return '$trimmed (Draft)';
    }
    return trimmed;
  }

  static HistoryDisplayItem fromEntry(HistoryEntry entry) {
    CalculationResult? result;
    try {
      final validation = validateRows(
        entry.rows,
        allowedNames: _allowedNamesForRows(entry.rows),
      );
      if (validation.isValid) {
        result = calculateSettlement(
          entry.rows,
          passingRate: entry.passingRate,
          amountDeductionRate: entry.amountDeductionRate,
        );
      }
    } catch (_) {
      result = null;
    }
    return HistoryDisplayItem(entry: entry, result: result);
  }
}

class HistoryDateGroup {
  const HistoryDateGroup({
    required this.label,
    required this.items,
  });

  final String label;
  final List<HistoryDisplayItem> items;
}

String historyDateGroupLabel(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(date.year, date.month, date.day);
  if (day == today) return 'Today';
  if (day == today.subtract(const Duration(days: 1))) return 'Yesterday';
  return DateFormat('d MMM yyyy').format(date);
}

List<HistoryDateGroup> groupHistoryByDate(List<HistoryDisplayItem> items) {
  final sorted = List<HistoryDisplayItem>.from(items)
    ..sort((a, b) => b.entry.savedAt.compareTo(a.entry.savedAt));

  final groups = <String, List<HistoryDisplayItem>>{};
  final order = <String>[];

  for (final item in sorted) {
    final label = historyDateGroupLabel(item.entry.savedAt);
    groups.putIfAbsent(label, () {
      order.add(label);
      return [];
    });
    groups[label]!.add(item);
  }

  return order
      .map(
        (label) => HistoryDateGroup(
          label: label,
          items: groups[label]!,
        ),
      )
      .toList();
}

List<HistoryDisplayItem> filterHistoryItems({
  required List<HistoryDisplayItem> items,
  required HistoryFilter filter,
  required String searchQuery,
}) {
  final query = searchQuery.trim().toLowerCase();

  return items.where((item) {
    if (!_matchesFilter(item, filter)) return false;
    if (query.isEmpty) return true;
    return _matchesSearch(item, query);
  }).toList();
}

bool _matchesFilter(HistoryDisplayItem item, HistoryFilter filter) {
  switch (filter) {
    case HistoryFilter.all:
      return true;
    case HistoryFilter.drafts:
      return item.isDraft;
    case HistoryFilter.lene:
      return item.resultType == ResultType.lene;
    case HistoryFilter.dene:
      return item.resultType == ResultType.dene;
  }
}

bool _matchesSearch(HistoryDisplayItem item, String query) {
  if (item.entry.title.toLowerCase().contains(query)) return true;
  for (final row in item.entry.rows) {
    if (row.name.toLowerCase().contains(query)) return true;
  }
  return false;
}

List<HistoryDisplayItem> mergeHistoryWithDraft({
  required List<HistoryEntry> history,
  required HistoryEntry? draftEntry,
}) {
  final items = <HistoryDisplayItem>[];
  final seenIds = <String>{};

  if (draftEntry != null && draftEntry.hasData) {
    items.add(HistoryDisplayItem.fromEntry(draftEntry));
    seenIds.add(draftEntry.id);
  }

  for (final entry in history) {
    if (seenIds.contains(entry.id)) {
      final index = items.indexWhere((item) => item.entry.id == entry.id);
      if (index >= 0 && draftEntry != null && entry.id == draftEntry.id) {
        continue;
      }
    }
    items.add(HistoryDisplayItem.fromEntry(entry));
    seenIds.add(entry.id);
  }

  items.sort((a, b) => b.entry.savedAt.compareTo(a.entry.savedAt));
  return items;
}

int historyCountForDate(List<HistoryDisplayItem> items, String label) {
  return items
      .where(
        (item) => historyDateGroupLabel(item.entry.savedAt) == label,
      )
      .length;
}
