import 'package:decimal/decimal.dart';

import 'row_data.dart';

class HistoryEntry {
  HistoryEntry({
    required this.id,
    required this.title,
    required this.rows,
    required this.passingRate,
    required this.amountDeductionRate,
    required this.savedAt,
    this.status = 'COMPLETED',
    this.updatedAt,
    this.commissionTracking = false,
    Decimal? commissionEarned,
    Decimal? commissionBalanceAtThatTime,
    this.groupId,
    this.originalPastedText,
  })  : commissionEarned = commissionEarned ?? Decimal.zero,
        commissionBalanceAtThatTime =
            commissionBalanceAtThatTime ?? Decimal.zero;

  static const draftStatus = 'DRAFT';
  static const completedStatus = 'COMPLETED';
  static const activeDraftId = '__active_draft__';

  final String id;
  final String title;
  final List<RowData> rows;
  final Decimal passingRate;
  final Decimal amountDeductionRate;
  final DateTime savedAt;
  final String status;
  final DateTime? updatedAt;
  final bool commissionTracking;
  final Decimal commissionEarned;
  final Decimal commissionBalanceAtThatTime;
  final String? groupId;
  final String? originalPastedText;

  bool get isDraft => status == draftStatus;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'rows': rows.map((row) => row.toJson()).toList(),
        'passingRate': passingRate.toString(),
        'amountDeductionRate': amountDeductionRate.toString(),
        'savedAt': savedAt.toIso8601String(),
        'status': status,
        if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
        'commissionTracking': commissionTracking,
        'commissionEarned': commissionEarned.toString(),
        'commissionBalanceAtThatTime': commissionBalanceAtThatTime.toString(),
        if (groupId != null) 'groupId': groupId,
        if (originalPastedText != null)
          'originalPastedText': originalPastedText,
      };

  HistoryEntry copyWith({
    String? id,
    String? title,
    List<RowData>? rows,
    Decimal? passingRate,
    Decimal? amountDeductionRate,
    DateTime? savedAt,
    String? status,
    DateTime? updatedAt,
    bool? commissionTracking,
    Decimal? commissionEarned,
    Decimal? commissionBalanceAtThatTime,
    String? groupId,
    String? originalPastedText,
  }) {
    return HistoryEntry(
      id: id ?? this.id,
      title: title ?? this.title,
      rows: rows ?? this.rows,
      passingRate: passingRate ?? this.passingRate,
      amountDeductionRate:
          amountDeductionRate ?? this.amountDeductionRate,
      savedAt: savedAt ?? this.savedAt,
      status: status ?? this.status,
      updatedAt: updatedAt ?? this.updatedAt,
      commissionTracking: commissionTracking ?? this.commissionTracking,
      commissionEarned: commissionEarned ?? this.commissionEarned,
      commissionBalanceAtThatTime:
          commissionBalanceAtThatTime ?? this.commissionBalanceAtThatTime,
      groupId: groupId ?? this.groupId,
      originalPastedText: originalPastedText ?? this.originalPastedText,
    );
  }

  factory HistoryEntry.fromJson(Map<String, dynamic> json) {
    final rawRows = json['rows'] as List<dynamic>? ?? [];
    final legacyTracking = json['commissionSeparate'] as bool? ?? false;
    final tracking =
        json['commissionTracking'] as bool? ?? legacyTracking;

    Decimal commissionEarned = Decimal.zero;
    if (json['commissionEarned'] != null) {
      commissionEarned =
          Decimal.parse(json['commissionEarned'].toString());
    } else if (json['commissionAmount'] != null && tracking) {
      commissionEarned =
          Decimal.parse(json['commissionAmount'].toString());
    }

    return HistoryEntry(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      rows: rawRows
          .map((item) => RowData.fromJson(item as Map<String, dynamic>))
          .toList(),
      passingRate: Decimal.parse(json['passingRate'].toString()),
      amountDeductionRate: Decimal.parse(
        json['amountDeductionRate'].toString(),
      ),
      savedAt: DateTime.parse(json['savedAt'] as String),
      status: json['status'] as String? ?? completedStatus,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      commissionTracking: tracking,
      commissionEarned: commissionEarned,
      commissionBalanceAtThatTime: json['commissionBalanceAtThatTime'] != null
          ? Decimal.parse(json['commissionBalanceAtThatTime'].toString())
          : Decimal.zero,
      groupId: json['groupId'] as String?,
      originalPastedText: json['originalPastedText'] as String?,
    );
  }

  bool get hasData =>
      title.trim().isNotEmpty ||
      rows.any(
        (row) =>
            row.name.trim().isNotEmpty ||
            row.amount.trim().isNotEmpty ||
            row.bracket.trim().isNotEmpty,
      );
}
