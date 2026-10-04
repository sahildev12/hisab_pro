import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab_pro/core/storage.dart';
import 'package:hisab_pro/models/history_entry.dart';
import 'package:hisab_pro/models/row_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

HistoryEntry _entry({
  required String id,
  required DateTime savedAt,
  String groupId = 'g1',
}) {
  return HistoryEntry(
    id: id,
    title: 'Test',
    rows: [
      RowData(id: '1', name: 'Sb.', amount: '100', bracket: '10'),
    ],
    passingRate: Decimal.fromInt(96),
    amountDeductionRate: Decimal.fromInt(4),
    savedAt: savedAt,
    status: HistoryEntry.completedStatus,
    groupId: groupId,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('upsert keeps multiple history entries across days', () async {
    final storage = StorageService();
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final today = DateTime.now();

    await storage.upsertHistoryEntry(
      _entry(id: 'old', savedAt: yesterday),
    );
    await storage.upsertHistoryEntry(
      _entry(id: 'new', savedAt: today),
    );

    final loaded = await storage.loadHistory();
    expect(loaded.length, 2);
    expect(loaded.any((e) => e.id == 'old'), isTrue);
    expect(loaded.any((e) => e.id == 'new'), isTrue);
  });

  test('loadHistory skips corrupt rows without dropping valid entries', () async {
    SharedPreferences.setMockInitialValues({
      'hisabpro-history': '''
[
  {"id":"ok","title":"T","rows":[],"passingRate":"96","amountDeductionRate":"4","savedAt":"2026-09-28T10:00:00.000","status":"COMPLETED"},
  {"id":"bad","title":"Broken","rows":"not-a-list","passingRate":"96","amountDeductionRate":"4","savedAt":"2026-09-29T10:00:00.000","status":"COMPLETED"}
]
''',
    });

    final storage = StorageService();
    final loaded = await storage.loadHistory();
    expect(loaded.length, 1);
    expect(loaded.single.id, 'ok');
  });

  test('loadGroupHistory returns all entries for a group', () async {
    final storage = StorageService();
    final groupId = 'group-a';
    await storage.upsertHistoryEntry(
      _entry(
        id: '1',
        savedAt: DateTime.now().subtract(const Duration(days: 3)),
        groupId: groupId,
      ),
    );
    await storage.upsertHistoryEntry(
      _entry(
        id: '2',
        savedAt: DateTime.now(),
        groupId: groupId,
      ),
    );
    await storage.upsertHistoryEntry(
      _entry(
        id: 'other',
        savedAt: DateTime.now(),
        groupId: 'other-group',
      ),
    );

    final groupHistory = await storage.loadGroupHistory(groupId);
    expect(groupHistory.length, 2);
    expect(groupHistory.map((e) => e.id).toSet(), {'1', '2'});
  });
}
