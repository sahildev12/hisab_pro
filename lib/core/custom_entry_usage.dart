import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

const _customEntryUsageKey = 'hisabpro-custom-entry-usage';

/// Tracks how often each custom entry name is picked so the prompt can surface
/// the six most-used shortcuts.
class CustomEntryUsageService {
  Future<Map<String, int>> _loadBucket() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_customEntryUsageKey);
    if (raw == null || raw.isEmpty) return {};

    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return map.map(
        (key, value) => MapEntry(key, (value as num).toInt()),
      );
    } catch (_) {
      return {};
    }
  }

  Future<void> recordUsage(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;

    final bucket = await _loadBucket();
    bucket[trimmed] = (bucket[trimmed] ?? 0) + 1;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_customEntryUsageKey, jsonEncode(bucket));
  }

  Future<List<String>> getMostUsedNames({int limit = 6}) async {
    final bucket = await _loadBucket();
    if (bucket.isEmpty) return [];

    final sorted = bucket.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(limit).map((entry) => entry.key).toList();
  }
}

/// Sensible defaults until the client builds their own usage history.
const defaultCustomEntrySuggestions = [
  'Mk.',
  'Dr.',
  'Sk.',
  'Rk.',
  'Vm.',
  'Pnk.',
];
