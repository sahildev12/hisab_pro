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
List<RowData> restoreGroupRows(List<RowData> rows, String groupId) {
  if (rows.isEmpty) return defaultGroupRows(groupId);
  return rows
      .map(
        (row) => RowData(
          id: row.id,
          name: row.name,
          amount: row.amount,
          bracket: row.bracket,
        ),
      )
      .toList();
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
