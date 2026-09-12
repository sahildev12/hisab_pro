import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/share_message.dart';
import '../theme/app_theme.dart';

class CopyButton extends StatefulWidget {
  const CopyButton({super.key, required this.message});

  final String message;

  @override
  State<CopyButton> createState() => _CopyButtonState();
}

class _CopyButtonState extends State<CopyButton> {
  bool _shared = false;

  Future<void> _share() async {
    await shareCalculationMessage(widget.message);
    setState(() => _shared = true);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Copied and ready to share!'),
          duration: Duration(milliseconds: 1800),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    await Future<void>.delayed(const Duration(milliseconds: 1800));
    if (mounted) setState(() => _shared = false);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSpacing.buttonHeight,
      child: ElevatedButton.icon(
        onPressed: _share,
        style: fullWidthPrimaryButtonStyle().copyWith(
          backgroundColor: WidgetStatePropertyAll(
            _shared ? AppColors.success : AppColors.primary,
          ),
        ),
        icon: Icon(_shared ? Icons.check : Icons.share_outlined),
        label: Text(
          _shared ? 'Shared' : 'Copy & Share Message',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
    );
  }
}
