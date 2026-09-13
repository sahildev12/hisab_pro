import 'dart:convert';

import 'package:decimal/decimal.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'format.dart';

const _rateUsageKey = 'hisabpro-rate-usage';

enum RateUsageKind { passing, commission }

class RateUsageService {
  Future<Map<String, int>> _loadBucket(RateUsageKind kind) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_rateUsageKey);
    if (raw == null || raw.isEmpty) return {};

    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final bucket = map[kind.name] as Map<String, dynamic>? ?? {};
      return bucket.map(
        (key, value) => MapEntry(key, (value as num).toInt()),
      );
    } catch (_) {
      return {};
    }
  }

  Future<void> recordUsage(RateUsageKind kind, Decimal rate) async {
    if (rate <= Decimal.zero) return;

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_rateUsageKey);
    Map<String, dynamic> all = {};
    if (raw != null && raw.isNotEmpty) {
      try {
        all = jsonDecode(raw) as Map<String, dynamic>;
      } catch (_) {
        all = {};
      }
    }

    final bucketKey = kind.name;
    final bucket = Map<String, dynamic>.from(
      all[bucketKey] as Map<String, dynamic>? ?? {},
    );
    final normalized = formatPlainNumber(rate);
    bucket[normalized] = ((bucket[normalized] as num?)?.toInt() ?? 0) + 1;
    all[bucketKey] = bucket;

    await prefs.setString(_rateUsageKey, jsonEncode(all));
  }

  Future<List<Decimal>> getMostUsedRates(
    RateUsageKind kind, {
    int limit = 5,
  }) async {
    final bucket = await _loadBucket(kind);
    if (bucket.isEmpty) return [];

    final sorted = bucket.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(limit).map((entry) {
      return Decimal.parse(entry.key);
    }).toList();
  }
}
