import 'commission.dart';

/// Commission balance key scoped to a calculation group.
String groupCommissionOwnerId(String groupId) => 'group:$groupId';

/// Title-based owner within a group context.
String groupTitleCommissionOwnerId(String groupId, String title) {
  final titleId = commissionOwnerId(title);
  if (titleId == '__default__') return groupCommissionOwnerId(groupId);
  return 'group:$groupId:$titleId';
}
