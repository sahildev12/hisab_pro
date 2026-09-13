import 'package:flutter/material.dart';

/// Unfocuses the active field when the user taps outside inputs app-wide.
class DismissKeyboard extends StatelessWidget {
  const DismissKeyboard({super.key, required this.child});

  final Widget child;

  static void unfocus() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: unfocus,
      behavior: HitTestBehavior.translucent,
      child: child,
    );
  }
}
