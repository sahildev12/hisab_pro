import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Meta-inspired commerce palette — clean canvas, cobalt accents, soft surfaces.
class AppColors {
  static const canvas = Color(0xFFF5F6F8);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceSoft = Color(0xFFF0F2F5);

  static const primary = Color(0xFF0866FF);
  static const primaryDeep = Color(0xFF0143B5);
  static const primarySoft = Color(0xFFE7F3FF);

  static const inkDeep = Color(0xFF1C2B33);
  static const ink = Color(0xFF344854);
  static const charcoal = Color(0xFF4B5563);
  static const slate = Color(0xFF64748B);
  static const stone = Color(0xFF94A3B8);

  static const hairline = Color(0xFFE4E6EB);
  static const hairlineSoft = Color(0xFFEDF0F3);

  // Legacy aliases used across widgets
  static const primaryBlue = primary;
  static const deepNavy = inkDeep;
  static const background = canvas;
  static const border = hairline;
  static const primaryText = inkDeep;
  static const secondaryText = slate;
  static const lightBlue = primarySoft;

  static const success = Color(0xFF0D9F4E);
  static const successLight = Color(0xFFE8F8EE);
  static const danger = Color(0xFFE41E3F);
  static const warning = Color(0xFFF5C518);

  // Dark palette
  static const canvasDark = Color(0xFF0F172A);
  static const surfaceDark = Color(0xFF1E293B);
  static const surfaceSoftDark = Color(0xFF273449);
  static const inkDeepDark = Color(0xFFF1F5F9);
  static const slateDark = Color(0xFF94A3B8);
  static const hairlineDark = Color(0xFF334155);
  static const hairlineSoftDark = Color(0xFF293548);
  static const primarySoftDark = Color(0xFF1E3A5F);
}

class AppSpacing {
  static const pagePadding = 20.0;
  static const sectionGap = 16.0;
  static const cardRadius = 20.0;
  static const inputRadius = 12.0;
  static const buttonHeight = 48.0;
  static const rowHeight = 62.0;
  static const pillRadius = 100.0;
}

ThemeData buildAppTheme({bool dark = false}) {
  if (dark) return buildDarkAppTheme();

  final textTheme = GoogleFonts.interTextTheme();

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.canvas,
    textTheme: textTheme.apply(
      bodyColor: AppColors.inkDeep,
      displayColor: AppColors.inkDeep,
    ),
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
      primary: AppColors.primary,
      surface: AppColors.surface,
      onSurface: AppColors.inkDeep,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.surface,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      foregroundColor: AppColors.inkDeep,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.inkDeep,
        letterSpacing: -0.2,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        side: const BorderSide(color: AppColors.hairlineSoft),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      hintStyle: GoogleFonts.inter(color: AppColors.stone, fontSize: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
        borderSide: const BorderSide(color: AppColors.hairline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
        borderSide: const BorderSide(color: AppColors.hairline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size(0, AppSpacing.buttonHeight),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
        ),
        textStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.14,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.inkDeep,
        backgroundColor: AppColors.surface,
        side: const BorderSide(color: AppColors.hairline, width: 1.5),
        minimumSize: const Size(0, 44),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
        ),
        textStyle: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          fontSize: 13,
          letterSpacing: -0.1,
        ),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.hairlineSoft,
      thickness: 1,
    ),
  );
}

ThemeData buildDarkAppTheme() {
  final textTheme = GoogleFonts.interTextTheme(ThemeData.dark().textTheme);

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.canvasDark,
    textTheme: textTheme.apply(
      bodyColor: AppColors.inkDeepDark,
      displayColor: AppColors.inkDeepDark,
    ),
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
      primary: AppColors.primary,
      surface: AppColors.surfaceDark,
      onSurface: AppColors.inkDeepDark,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.surfaceDark,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      foregroundColor: AppColors.inkDeepDark,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.inkDeepDark,
        letterSpacing: -0.2,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.surfaceDark,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        side: const BorderSide(color: AppColors.hairlineSoftDark),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceDark,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      hintStyle: GoogleFonts.inter(color: AppColors.slateDark, fontSize: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
        borderSide: const BorderSide(color: AppColors.hairlineDark),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
        borderSide: const BorderSide(color: AppColors.hairlineDark),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size(0, AppSpacing.buttonHeight),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
        ),
        textStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.14,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.inkDeepDark,
        backgroundColor: AppColors.surfaceDark,
        side: const BorderSide(color: AppColors.hairlineDark, width: 1.5),
        minimumSize: const Size(0, 44),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
        ),
        textStyle: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          fontSize: 13,
          letterSpacing: -0.1,
        ),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.hairlineSoftDark,
      thickness: 1,
    ),
  );
}

/// Full-width primary CTA (Calculate, Save Settings).
ButtonStyle fullWidthPrimaryButtonStyle() {
  return ElevatedButton.styleFrom(
    minimumSize: const Size(double.infinity, AppSpacing.buttonHeight),
  );
}

bool isDarkContext(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark;

Color appCanvasColor(BuildContext context) =>
    isDarkContext(context) ? AppColors.canvasDark : AppColors.canvas;

Color appSurfaceColor(BuildContext context) =>
    isDarkContext(context) ? AppColors.surfaceDark : AppColors.surface;

Color appSurfaceSoftColor(BuildContext context) =>
    isDarkContext(context) ? AppColors.surfaceSoftDark : AppColors.surfaceSoft;

Color appPrimaryTextColor(BuildContext context) =>
    isDarkContext(context) ? AppColors.inkDeepDark : AppColors.inkDeep;

Color appSecondaryTextColor(BuildContext context) =>
    isDarkContext(context) ? AppColors.slateDark : AppColors.slate;

Color appBorderColor(BuildContext context) =>
    isDarkContext(context) ? AppColors.hairlineSoftDark : AppColors.hairlineSoft;

BoxDecoration surfaceDecoration(BuildContext context, {Color? color}) {
  return BoxDecoration(
    color: color ?? appSurfaceColor(context),
    borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
    border: Border.all(color: appBorderColor(context)),
  );
}

BoxDecoration softSurfaceDecoration(BuildContext context) {
  return BoxDecoration(
    color: appSurfaceSoftColor(context),
    borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
    border: Border.all(color: appBorderColor(context)),
  );
}

TextStyle sectionLabelStyle(BuildContext context) {
  return GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: appSecondaryTextColor(context),
    letterSpacing: -0.1,
  );
}
