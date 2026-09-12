import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/copy_message.dart';
import '../core/format.dart';
import '../core/history_helpers.dart';
import '../theme/app_theme.dart';
import '../widgets/copy_button.dart';
import '../widgets/result_card.dart';

class HistoryDetailScreen extends StatelessWidget {
  const HistoryDetailScreen({
    super.key,
    required this.item,
    required this.persistentHeader,
    required this.onEdit,
  });

  final HistoryDisplayItem item;
  final String persistentHeader;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final entry = item.entry;
    final result = item.result;
    final title = item.displayTitle.replaceAll(' (Draft)', '').trim();

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: const Text('Calculation Detail'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (item.isDraft)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'DRAFT — not yet finalized',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ),
                Text(
                  item.displayTitle,
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF17365D),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formatHistoryDate(entry.savedAt),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 16),
                _metadataRow(item),
                const SizedBox(height: 20),
                if (result != null) ...[
                  ResultCard(title: title, result: result),
                  const SizedBox(height: 16),
                  CopyButton(
                    message: buildCopyMessage(
                      title: title,
                      rows: entry.rows,
                      result: result,
                      persistentHeader: persistentHeader,
                    ),
                  ),
                ] else
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Text(
                      'This calculation is incomplete. Add rows and calculate to see the result.',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF64748B),
                        fontSize: 14,
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Edit Calculation'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _metadataRow(HistoryDisplayItem item) {
    return Row(
      children: [
        _metaCell('Passing', formatRate(item.entry.passingRate)),
        _metaCell('Deduction', formatRate(item.entry.amountDeductionRate)),
        _metaCell('Rows', '${item.rowCount}'),
      ],
    );
  }

  Widget _metaCell(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF17365D),
            ),
          ),
        ],
      ),
    );
  }
}
