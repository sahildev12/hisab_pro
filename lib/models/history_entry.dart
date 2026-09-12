import 'package:decimal/decimal.dart';

import 'row_data.dart';

class HistoryEntry {
  const HistoryEntry({
    required this.id,
    required this.title,
    required this.rows,
    required this.passingRate,
    required this.amountDeductionRate,
    required this.savedAt,
    this.status = 'COMPLETED',
    this.updatedAt,
  });

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
    );
  }

  factory HistoryEntry.fromJson(Map<String, dynamic> json) {
    final rawRows = json['rows'] as List<dynamic>? ?? [];
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
