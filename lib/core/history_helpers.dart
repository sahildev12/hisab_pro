import 'package:decimal/decimal.dart';
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

enum HistorySort {
  newest,
  oldest,
  amountHigh,
  amountLow,
}

enum HistoryGroupMode { byGroup, byDate, none }

/// Title for history list cards — never appends "(Draft)".
String historyListTitle(HistoryEntry entry, {required bool isDraft}) {
  var title = entry.title.trim();
  title = title
      .replaceAll(RegExp(r'\s*\(draft\)\s*$', caseSensitive: false), '')
      .trim();
  if (title.isEmpty) {
    return isDraft ? 'Untitled' : 'Calculation';
  }
  return title;
}

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

  /// Clean title for history list — no "(Draft)" suffix.
  String get listTitle => historyListTitle(entry, isDraft: isDraft);

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
          commissionTracking: entry.commissionTracking,
          storedCommissionBalance: entry.commissionTracking
              ? entry.commissionBalanceAtThatTime - entry.commissionEarned
              : Decimal.zero,
        ).copyWith(
          commissionBalance: entry.commissionBalanceAtThatTime,
        );
      }
    } catch (_) {
      result = null;
    }
    return HistoryDisplayItem(entry: entry, result: result);
  }
}

/// Sum of the Total Amount of every calculation in [items].
///
/// Entries that could not be calculated contribute nothing.
Decimal historyTotalAmount(List<HistoryDisplayItem> items) {
  return items.fold(
    Decimal.zero,
    (sum, item) => sum + (item.result?.totalAmount ?? Decimal.zero),
  );
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

List<HistoryDisplayItem> sortHistoryItems(
  List<HistoryDisplayItem> items,
  HistorySort sort,
) {
  final sorted = List<HistoryDisplayItem>.from(items);
  switch (sort) {
    case HistorySort.newest:
      sorted.sort((a, b) => b.entry.savedAt.compareTo(a.entry.savedAt));
    case HistorySort.oldest:
      sorted.sort((a, b) => a.entry.savedAt.compareTo(b.entry.savedAt));
    case HistorySort.amountHigh:
      sorted.sort((a, b) {
        final amountA = a.result?.displayAmount ?? Decimal.zero;
        final amountB = b.result?.displayAmount ?? Decimal.zero;
        final byAmount = amountB.compareTo(amountA);
        if (byAmount != 0) return byAmount;
        return b.entry.savedAt.compareTo(a.entry.savedAt);
      });
    case HistorySort.amountLow:
      sorted.sort((a, b) {
        final amountA = a.result?.displayAmount ?? Decimal.zero;
        final amountB = b.result?.displayAmount ?? Decimal.zero;
        final byAmount = amountA.compareTo(amountB);
        if (byAmount != 0) return byAmount;
        return b.entry.savedAt.compareTo(a.entry.savedAt);
      });
  }
  return sorted;
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

/// Buckets history under the calculation group it belongs to.
///
/// [groupNames] maps group ids to display names; unknown ids and entries with
/// no group fall into a single "Other Calculations" bucket.
List<HistoryDateGroup> groupHistoryByGroup(
  List<HistoryDisplayItem> items, {
  required Map<String, String> groupNames,
}) {
  const ungrouped = 'Other Calculations';

  final buckets = <String, List<HistoryDisplayItem>>{};
  final order = <String>[];

  for (final item in items) {
    final groupId = item.entry.groupId;
    final label = groupId == null ? ungrouped : groupNames[groupId] ?? ungrouped;
    buckets.putIfAbsent(label, () {
      order.add(label);
      return [];
    });
    buckets[label]!.add(item);
  }

  // Keep the catch-all bucket last so real groups stay on top.
  order.sort((a, b) {
    if (a == b) return 0;
    if (a == ungrouped) return 1;
    if (b == ungrouped) return -1;
    return 0;
  });

  return order
      .map((label) => HistoryDateGroup(label: label, items: buckets[label]!))
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
