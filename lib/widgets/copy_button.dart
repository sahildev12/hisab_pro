import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

class CopyButton extends StatefulWidget {
  const CopyButton({super.key, required this.message});

  final String message;

  @override
  State<CopyButton> createState() => _CopyButtonState();
}

class _CopyButtonState extends State<CopyButton> {
  bool _copied = false;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.message));
    setState(() => _copied = true);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Message copied!'),
          duration: Duration(milliseconds: 1800),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    await Future<void>.delayed(const Duration(milliseconds: 1800));
    if (mounted) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSpacing.buttonHeight,
      child: ElevatedButton.icon(
        onPressed: _copy,
        icon: Icon(_copied ? Icons.check : Icons.copy_all_outlined),
        label: Text(
          _copied ? '✓ Copied' : '📋 Copy Message',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor:
              _copied ? AppColors.success : AppColors.success,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
    );
  }
}
