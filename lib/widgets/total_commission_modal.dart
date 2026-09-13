import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/format.dart';
import '../core/storage.dart';
import 'hisab_pro_modal.dart';

Future<void> showTotalCommissionModal({
  required BuildContext context,
  required StorageService storage,
}) async {
  final balances = await storage.loadCommissionBalances();
  if (!context.mounted) return;

  final entries = balances.entries
      .where((e) => e.value > Decimal.zero)
      .toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  final total = entries.fold<Decimal>(
    Decimal.zero,
    (sum, entry) => sum + entry.value,
  );

  await showHisabProModal<void>(
    context: context,
    builder: (dialogContext) {
      return HisabProModalCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: HisabProModalColors.softBlue,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.currency_rupee_rounded,
                    color: HisabProModalColors.primary,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Commission',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: HisabProModalColors.navy,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Saved commission balances',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: HisabProModalColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  icon: const Icon(Icons.close, size: 22),
                  tooltip: 'Close',
                  color: HisabProModalColors.muted,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              formatMoney(total, showCurrency: true),
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 36,
                fontWeight: FontWeight.w800,
                color: HisabProModalColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            if (entries.isEmpty)
              Text(
                'No commission balance saved yet.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: HisabProModalColors.muted,
                ),
              )
            else
              ...entries.map((entry) {
                final label = entry.key == '__default__'
                    ? 'Untitled'
                    : entry.key;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _capitalizeLabel(label),
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: HisabProModalColors.navy,
                          ),
                        ),
                      ),
                      Text(
                        formatMoney(entry.value, showCurrency: true),
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: HisabProModalColors.navy,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            const SizedBox(height: 8),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(dialogContext),
                style: ElevatedButton.styleFrom(
                  backgroundColor: HisabProModalColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      );
    },
  );
}

String _capitalizeLabel(String key) {
  if (key.isEmpty) return 'Untitled';
  return key.split(' ').map((word) {
    if (word.isEmpty) return word;
    return '${word[0].toUpperCase()}${word.substring(1)}';
  }).join(' ');
}
