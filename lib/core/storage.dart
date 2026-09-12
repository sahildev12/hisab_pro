import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/row_data.dart';
import '../models/settlement_type.dart';
import 'calculate.dart';

const _storageKey = 'hisabpro-v1';

class SavedState {
  const SavedState({
    required this.title,
    required this.rows,
    this.lastView = 'main',
    this.settlementType = SettlementType.lene,
    this.bracketRate = defaultMultiplier,
  });

  final String title;
  final List<RowData> rows;
  final String lastView;
  final SettlementType settlementType;
  final int bracketRate;

  Map<String, dynamic> toJson() => {
        'title': title,
        'rows': rows.map((row) => row.toJson()).toList(),
        'lastView': lastView,
        'settlementType': settlementType.storageValue,
        'bracketRate': bracketRate,
      };

  factory SavedState.fromJson(Map<String, dynamic> json) {
    final rawRows = json['rows'] as List<dynamic>? ?? [];
    return SavedState(
      title: json['title'] as String? ?? '',
      rows: rawRows
          .map((item) => RowData.fromJson(item as Map<String, dynamic>))
          .toList(),
      lastView: json['lastView'] as String? ?? 'main',
      settlementType: SettlementType.fromString(
        json['settlementType'] as String?,
      ),
      bracketRate: json['bracketRate'] as int? ?? defaultMultiplier,
    );
  }
}

class StorageService {
  Future<SavedState?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }

    try {
      final jsonMap = jsonDecode(raw) as Map<String, dynamic>;
      return SavedState.fromJson(jsonMap);
    } catch (_) {
      return null;
    }
  }

  Future<void> save(SavedState state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(state.toJson()));
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}
