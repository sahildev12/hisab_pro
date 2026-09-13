import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Premium modal shell for HisabPro — backdrop, animation, keyboard-safe layout.
class HisabProModalColors {
  static const backdrop = Color(0x8C0F172A); // rgba(15, 23, 42, 0.55)
  static const surface = Color(0xFFFFFFFF);
  static const border = Color(0xFFE2E8F0);
  static const primary = Color(0xFF2563EB);
  static const navy = Color(0xFF17365D);
  static const muted = Color(0xFF64748B);
  static const softBlue = Color(0xFFEFF6FF);
  static const chipBg = Color(0xFFF1F5F9);
  static const inputBorder = Color(0xFFCBD5E1);
}

Future<T?> showHisabProModal<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  final isMobile = MediaQuery.sizeOf(context).width < 600;

  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: 'Close',
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 180),
    pageBuilder: (dialogContext, animation, secondaryAnimation) {
      return _HisabProModalShell(
        builder: builder,
        isMobile: isMobile,
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curve = Curves.easeOutCubic;
      final fade = CurvedAnimation(parent: animation, curve: curve);
      final scale = Tween<double>(begin: 0.96, end: 1).animate(fade);
      final slide = Tween<Offset>(
        begin: const Offset(0, 0.04),
        end: Offset.zero,
      ).animate(fade);

      return FadeTransition(
        opacity: fade,
        child: isMobile
            ? SlideTransition(position: slide, child: child)
            : ScaleTransition(scale: scale, child: child),
      );
    },
  );
}

class _HisabProModalShell extends StatelessWidget {
  const _HisabProModalShell({
    required this.builder,
    required this.isMobile,
  });

  final WidgetBuilder builder;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final width = MediaQuery.sizeOf(context).width;

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () => Navigator.of(context).maybePop(),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                child: Container(
                  color: HisabProModalColors.backdrop,
                ),
              ),
            ),
          ),
          SafeArea(
            child: AnimatedPadding(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOut,
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 24,
                bottom: 24 + viewInsets.bottom,
              ),
              child: Align(
                alignment: isMobile ? Alignment.center : Alignment.center,
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: 460,
                      minWidth: width > 460 ? 440 : width - 32,
                    ),
                    child: builder(context),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Rounded modal card container.
/// Themed confirm / alert dialog using the same shell as rate modals.
Future<bool?> showHisabProConfirmDialog({
  required BuildContext context,
  required String title,
  required String message,
  String cancelLabel = 'Cancel',
  String confirmLabel = 'Confirm',
  bool destructive = false,
}) {
  return showHisabProModal<bool>(
    context: context,
    builder: (dialogContext) {
      return HisabProModalCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: HisabProModalColors.navy,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: GoogleFonts.inter(
                fontSize: 14,
                height: 1.45,
                color: HisabProModalColors.muted,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(dialogContext, false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: HisabProModalColors.navy,
                        side: const BorderSide(
                          color: HisabProModalColors.inputBorder,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        cancelLabel,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(dialogContext, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: destructive
                            ? const Color(0xFFDC2626)
                            : HisabProModalColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        confirmLabel,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}

class HisabProModalCard extends StatelessWidget {
  const HisabProModalCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: HisabProModalColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: HisabProModalColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2E0F172A),
            blurRadius: 50,
            offset: Offset(0, 20),
          ),
        ],
      ),
      child: child,
    );
  }
}
