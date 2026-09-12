import 'fixed_names.dart';

/// All names available in the dropdown: static defaults + user custom names.
List<String> allEntryNames(List<String> customNames) {
  final seen = <String>{};
  final result = <String>[];
  for (final name in [...fixedNames, ...customNames]) {
    final trimmed = name.trim();
    if (trimmed.isEmpty || seen.contains(trimmed)) continue;
    seen.add(trimmed);
    result.add(trimmed);
  }
  return result;
}

bool isStaticEntryName(String name) => fixedNames.contains(name.trim());

bool isValidEntryName(String name, List<String> customNames) {
  final trimmed = name.trim();
  return trimmed.isNotEmpty &&
      (isStaticEntryName(trimmed) || customNames.contains(trimmed));
}
