import 'package:flutter/material.dart';

import '../../models/result_type.dart';

/// Result-page palette and layout tokens.
class ResultPageColors {
  static const canvas = Color(0xFFF7F9FC);
  static const card = Color(0xFFFFFFFF);
  static const primary = Color(0xFF2563EB);
  static const navy = Color(0xFF17365D);
  static const muted = Color(0xFF64748B);
  static const border = Color(0xFFE2E8F0);
  static const success = Color(0xFF16A34A);
  static const successDark = Color(0xFF15803D);
  static const successBg = Color(0xFFF0FBF5);
  static const successBorder = Color(0xFFBFE8D0);
  static const successBadgeBg = Color(0xFFDCFCE7);
  static const danger = Color(0xFFDC2626);
  static const dangerBg = Color(0xFFFFF5F5);
  static const dangerBorder = Color(0xFFF3CACA);
  static const dangerButtonBorder = Color(0xFFE5A8A8);
  static const dangerButtonText = Color(0xFFC24141);
  static const neutral = Color(0xFF2563EB);
  static const neutralBg = Color(0xFFEFF6FF);
  static const neutralBorder = Color(0xFFBFDBFE);
  static const detailsBg = Color(0xFFF8FAFC);
  static const tintedBg = Color(0xFFF1F5F9);
  static const tintedBorder = Color(0xFFE2E8F0);
  static const whatsapp = Color(0xFF25D366);
  static const iconBlue = Color(0xFF2563EB);
  static const iconPurple = Color(0xFF7C3AED);
  static const iconOrange = Color(0xFFEA580C);
}

class ResultPageLayout {
  static const pagePadding = 16.0;
  static const cardRadius = 16.0;
  static const heroRadius = 16.0;
  static const sectionGap = 12.0;
  static const titleTopGap = 8.0;
  static const actionGap = 8.0;
  static const rowHeight = 38.0;
  static const primaryButtonHeight = 48.0;
  static const secondaryButtonHeight = 44.0;
  static const whatsappRowHeight = 52.0;

  static BoxDecoration cardDecoration({Color? color, Color? borderColor}) {
    return BoxDecoration(
      color: color ?? ResultPageColors.card,
      borderRadius: BorderRadius.circular(cardRadius),
      border: Border.all(color: borderColor ?? ResultPageColors.border),
    );
  }
}

class ResultPageStyle {
  static Color accentFor(ResultType type) {
    switch (type) {
      case ResultType.lene:
        return ResultPageColors.success;
      case ResultType.dene:
        return ResultPageColors.danger;
      case ResultType.balanced:
        return ResultPageColors.neutral;
    }
  }

  static Color accentBgFor(ResultType type) {
    switch (type) {
      case ResultType.lene:
        return ResultPageColors.successBg;
      case ResultType.dene:
        return ResultPageColors.dangerBg;
      case ResultType.balanced:
        return ResultPageColors.neutralBg;
    }
  }

  static Color accentBorderFor(ResultType type) {
    switch (type) {
      case ResultType.lene:
        return ResultPageColors.successBorder;
      case ResultType.dene:
        return ResultPageColors.dangerBorder;
      case ResultType.balanced:
        return ResultPageColors.neutralBorder;
    }
  }

  static IconData iconFor(ResultType type) {
    switch (type) {
      case ResultType.lene:
        return Icons.arrow_upward_rounded;
      case ResultType.dene:
        return Icons.arrow_downward_rounded;
      case ResultType.balanced:
        return Icons.horizontal_rule_rounded;
    }
  }

  static String subtitleFor(ResultType type) {
    switch (type) {
      case ResultType.lene:
        return 'Amount to receive';
      case ResultType.dene:
        return 'Amount to pay';
      case ResultType.balanced:
        return 'No settlement needed';
    }
  }
}
