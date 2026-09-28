import 'package:shared_preferences/shared_preferences.dart';

import '../constants/fixed_names.dart';
import '../models/calculation_group.dart';
import '../models/history_entry.dart';
import '../models/row_data.dart';
import 'calculate.dart' as calc;
import 'storage.dart';

const _demoSeedFlag = 'hisabpro-demo-seeded-v2';

const _demoGroupNames = [
  'Manish',
  'Pankaj',
  'Rahul',
  'Ankit',
  'Modi Bhai',
  'Sunil',
  'Vikas',
  'Deepak',
  'Rohit',
  'Sanjay',
];

/// Adds 10 demo groups (30 history entries each) once per install.
Future<void> seedDemoDataIfNeeded(StorageService storage) async {
  final prefs = await SharedPreferences.getInstance();
  if (prefs.getBool(_demoSeedFlag) == true) return;

  final now = DateTime.now();

  for (var groupIndex = 0; groupIndex < _demoGroupNames.length; groupIndex++) {
    final name = _demoGroupNames[groupIndex];
    final group = CalculationGroup(
      id: 'demo-group-$groupIndex',
      name: name,
      passingRate: calc.defaultPassingRate,
      amountDeductionRate: calc.defaultAmountDeductionRate,
      createdAt: now.subtract(Duration(days: 40 - groupIndex)),
      updatedAt: now.subtract(Duration(hours: groupIndex * 3)),
      avatarColorValue: CalculationGroup.create(name: name).avatarColorValue,
    );

    await storage.upsertGroup(group);

    for (var entryIndex = 0; entryIndex < 30; entryIndex++) {
      final savedAt = now.subtract(
        Duration(days: entryIndex % 28, hours: entryIndex % 12),
      );
      await storage.upsertHistoryEntry(
        HistoryEntry(
          id: 'demo-${group.id}-$entryIndex',
          title: name,
          rows: _demoRows(group.id, entryIndex),
          passingRate: group.passingRate,
          amountDeductionRate: group.amountDeductionRate,
          savedAt: savedAt,
          updatedAt: savedAt,
          status: HistoryEntry.completedStatus,
          groupId: group.id,
        ),
      );
    }
  }

  await prefs.setBool(_demoSeedFlag, true);
}

List<RowData> _demoRows(String groupId, int seed) {
  const amounts = ['12000', '8500', '15000', '6200', '9800', '4300'];
  const brackets = ['120', '85', '150', '62', '98', '43'];

  return List.generate(5, (index) {
    final nameIndex = (seed + index) % fixedNames.length;
    final valueIndex = (seed + index) % amounts.length;
    return RowData(
      id: '$groupId-${fixedNames[nameIndex]}-demo-$seed-$index',
      name: fixedNames[nameIndex],
      amount: amounts[valueIndex],
      bracket: brackets[valueIndex],
    );
  });
}
