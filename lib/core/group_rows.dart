import '../constants/fixed_names.dart';
import '../models/row_data.dart';

List<RowData> defaultGroupRows(String groupId) {
  return List.generate(
    fixedNames.length,
    (index) => RowData(
      id: '$groupId-${fixedNames[index]}',
      name: fixedNames[index],
    ),
  );
}

/// Restores saved rows in the exact order the user left them.
///
/// Every row gets a stable, unique [RowData.id]. Older drafts sometimes stored
/// blank or duplicate ids, which breaks list add/delete/reorder in Flutter.
List<RowData> restoreGroupRows(List<RowData> rows, String groupId) {
  if (rows.isEmpty) return defaultGroupRows(groupId);

  final seen = <String>{};
  return rows.asMap().entries.map((entry) {
    final index = entry.key;
    final row = entry.value;
    var id = row.id.trim();
    if (id.isEmpty || seen.contains(id)) {
      final stamp = DateTime.now().microsecondsSinceEpoch + index;
      id = '$groupId-${row.name.trim()}-$index-$stamp';
    }
    seen.add(id);
    return RowData(
      id: id,
      name: row.name,
      amount: row.amount,
      bracket: row.bracket,
    );
  }).toList();
}

String? nextMissingFixedName(List<RowData> rows) {
  final present = rows.map((row) => row.name.trim()).toSet();
  for (final name in fixedNames) {
    if (!present.contains(name)) return name;
  }
  return null;
}

String formatCustomEntryName(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return '';
  return trimmed.endsWith('.') ? trimmed : '$trimmed.';
}
