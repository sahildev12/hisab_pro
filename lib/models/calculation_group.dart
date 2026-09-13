import 'package:decimal/decimal.dart';

import '../core/calculate.dart' as calc;
import '../core/money.dart';

/// A WhatsApp-style calculation group with its own rates and isolated data.
class CalculationGroup {
  CalculationGroup({
    required this.id,
    required this.name,
    required this.passingRate,
    required this.amountDeductionRate,
    required this.createdAt,
    required this.updatedAt,
    this.avatarColorValue,
  });

  final String id;
  final String name;
  final Decimal passingRate;
  final Decimal amountDeductionRate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int? avatarColorValue;

  CalculationGroup copyWith({
    String? id,
    String? name,
    Decimal? passingRate,
    Decimal? amountDeductionRate,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? avatarColorValue,
  }) {
    return CalculationGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      passingRate: passingRate ?? this.passingRate,
      amountDeductionRate:
          amountDeductionRate ?? this.amountDeductionRate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      avatarColorValue: avatarColorValue ?? this.avatarColorValue,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'passingRate': passingRate.toString(),
        'amountDeductionRate': amountDeductionRate.toString(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        if (avatarColorValue != null) 'avatarColorValue': avatarColorValue,
      };

  factory CalculationGroup.fromJson(Map<String, dynamic> json) {
    final passing = Decimal.parse(json['passingRate'].toString());
    return CalculationGroup(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      passingRate: passing,
      amountDeductionRate: json['amountDeductionRate'] != null
          ? Decimal.parse(json['amountDeductionRate'].toString())
          : suggestedAmountDeduction(passing),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      avatarColorValue: json['avatarColorValue'] as int?,
    );
  }

  factory CalculationGroup.create({
    required String name,
    Decimal? passingRate,
    Decimal? amountDeductionRate,
  }) {
    final now = DateTime.now();
    final passing = passingRate ?? calc.defaultPassingRate;
    final deduction = amountDeductionRate ?? suggestedAmountDeduction(passing);
    return CalculationGroup(
      id: now.microsecondsSinceEpoch.toString(),
      name: name.trim(),
      passingRate: passing,
      amountDeductionRate: deduction,
      createdAt: now,
      updatedAt: now,
      avatarColorValue: _colorForName(name),
    );
  }

  static int _colorForName(String name) {
    const palette = [
      0xFF2563EB,
      0xFF17365D,
      0xFF16A34A,
      0xFF7C3AED,
      0xFFDC2626,
      0xFF0891B2,
      0xFFCA8A04,
      0xFFDB2777,
    ];
    if (name.trim().isEmpty) return palette.first;
    var hash = 0;
    for (final codeUnit in name.trim().codeUnits) {
      hash = (hash + codeUnit) % palette.length;
    }
    return palette[hash];
  }
}
