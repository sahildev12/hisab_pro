import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../hisab_pro_modal.dart';
import 'result_page_theme.dart';
import 'result_tinted_card.dart';

class WhatsappPreviewRow extends StatelessWidget {
  const WhatsappPreviewRow({
    super.key,
    required this.message,
    this.onCopyAndShare,
  });

  final String message;
  final Future<void> Function()? onCopyAndShare;

  @override
  Widget build(BuildContext context) {
    return ResultTintedCard(
      tint: ResultTint.neutral,
      onTap: () => _openPreview(context),
      child: ResultTintedRow(
        icon: Icons.chat_bubble_outline_rounded,
        iconColor: ResultPageColors.whatsapp,
        label: 'WhatsApp Preview',
        labelStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: ResultPageColors.navy,
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: ResultPageColors.muted,
          size: 20,
        ),
      ),
    );
  }

  void _openPreview(BuildContext context) {
    showHisabProModal<void>(
      context: context,
      builder: (dialogContext) {
        return HisabProModalCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.chat_bubble_outline_rounded,
                      color: ResultPageColors.whatsapp,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'WhatsApp Preview',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: HisabProModalColors.navy,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    icon: const Icon(Icons.close_rounded, size: 20),
                    color: HisabProModalColors.muted,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ResultPageColors.tintedBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: ResultPageColors.tintedBorder),
                ),
                child: SelectableText(
                  message,
                  style: GoogleFonts.robotoMono(
                    fontSize: 13,
                    height: 1.6,
                    color: ResultPageColors.navy,
                  ),
                ),
              ),
              if (onCopyAndShare != null) ...[
                const SizedBox(height: 16),
                SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await onCopyAndShare!();
                      if (dialogContext.mounted) {
                        Navigator.pop(dialogContext);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: HisabProModalColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.ios_share_rounded, size: 18),
                    label: Text(
                      'Copy & Share Message',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
