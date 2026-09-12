import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const primaryBlue = Color(0xFF2563EB);
  static const deepNavy = Color(0xFF17365D);
  static const cyanBlue = Color(0xFF22C7F2);
  static const lightBlue = Color(0xFFEFF6FF);
  static const background = Color(0xFFF7FAFF);
  static const surface = Color(0xFFFFFFFF);
  static const border = Color(0xFFDCE5F0);
  static const primaryText = Color(0xFF172B4D);
  static const secondaryText = Color(0xFF64748B);
  static const success = Color(0xFF16A34A);
  static const successLight = Color(0xFFECFDF3);
  static const danger = Color(0xFFDC2626);
  static const warning = Color(0xFFF59E0B);
}

class AppSpacing {
  static const pagePadding = 24.0;
  static const sectionGap = 16.0;
  static const cardRadius = 16.0;
  static const inputRadius = 14.0;
  static const buttonHeight = 56.0;
  static const rowHeight = 62.0;
}

ThemeData buildAppTheme() {
  final textTheme = GoogleFonts.interTextTheme();

  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.background,
    textTheme: textTheme.apply(
      bodyColor: AppColors.primaryText,
      displayColor: AppColors.primaryText,
    ),
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primaryBlue,
      primary: AppColors.primaryBlue,
      surface: AppColors.surface,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.background,
      elevation: 0,
      centerTitle: true,
      foregroundColor: AppColors.primaryText,
      titleTextStyle: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.primaryText,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size(double.infinity, AppSpacing.buttonHeight),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: GoogleFonts.inter(
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primaryText,
        backgroundColor: AppColors.surface,
        side: const BorderSide(color: AppColors.border),
        minimumSize: const Size(0, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.inter(fontWeight: FontWeight.w500),
      ),
    ),
  );
}

BoxDecoration surfaceDecoration({Color? color}) {
  return BoxDecoration(
    color: color ?? AppColors.surface,
    borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
    border: Border.all(color: AppColors.border),
    boxShadow: [
      BoxShadow(
        color: const Color(0xFF0F172A).withValues(alpha: 0.05),
        blurRadius: 10,
        offset: const Offset(0, 2),
      ),
    ],
  );
}

TextStyle sectionLabelStyle() {
  return GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.secondaryText,
  );
}
