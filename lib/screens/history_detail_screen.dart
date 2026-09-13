import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/copy_message.dart';
import '../core/format.dart';
import '../core/history_helpers.dart';
import '../core/share_message.dart';
import '../models/calculation_result.dart';
import '../widgets/hisab_page_header.dart';
import '../widgets/result_page/result_calculation_details.dart';
import '../widgets/result_page/result_commission_card.dart';
import '../widgets/result_page/result_hero_card.dart';
import '../widgets/result_page/result_page_theme.dart';
import '../widgets/result_page/result_summary_card.dart';
import '../widgets/result_page/whatsapp_preview_sheet.dart';

class HistoryDetailScreen extends StatefulWidget {
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
  State<HistoryDetailScreen> createState() => _HistoryDetailScreenState();
}

class _HistoryDetailScreenState extends State<HistoryDetailScreen> {
  bool _copied = false;

  HistoryDisplayItem get item => widget.item;

  String get _title => item.listTitle;

  String? get _message {
    final result = item.result;
    if (result == null) return null;
    return buildCopyMessage(
      title: _title,
      rows: item.entry.rows,
      result: result,
      persistentHeader: widget.persistentHeader,
    );
  }

  Future<void> _copyAndShare() async {
    final message = _message;
    if (message == null) return;
    await shareCalculationMessage(message);
    if (!mounted) return;
    setState(() => _copied = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✓ Message Copied'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(milliseconds: 1800),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 1800));
    if (mounted) setState(() => _copied = false);
  }

  Future<void> _shareOnly() async {
    final message = _message;
    if (message == null) return;
    await shareCalculationMessage(message);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ready to share'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(milliseconds: 1600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final result = item.result;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: ResultPageColors.canvas,
      body: Column(
        children: [
          HisabPageHeader(
            title: 'View History',
            subtitle: formatHistoryDate(item.entry.savedAt),
            onBack: () => Navigator.pop(context),
            actions: [
              if (result != null)
                HisabHeaderIconButton(
                  icon: Icons.share_outlined,
                  tooltip: 'Share',
                  onPressed: _shareOnly,
                ),
            ],
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                ResultPageLayout.pagePadding,
                4,
                ResultPageLayout.pagePadding,
                bottomInset > 0 ? bottomInset + 12 : 16,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 700),
                  child: result != null
                      ? _buildResultContent(result)
                      : _buildIncompleteContent(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultContent(CalculationResult result) {
    final message = _message!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (item.isDraft) ...[
          _draftBanner(),
          const SizedBox(height: ResultPageLayout.sectionGap),
        ],
        Text(
          _title,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: ResultPageColors.navy,
          ),
        ),
        const SizedBox(height: ResultPageLayout.titleTopGap),
        _metadataStrip(),
        const SizedBox(height: ResultPageLayout.sectionGap),
        ResultHeroCard(result: result),
        const SizedBox(height: ResultPageLayout.sectionGap),
        ResultSummaryCard(result: result),
        if (result.commissionTracking) ...[
          const SizedBox(height: ResultPageLayout.sectionGap),
          ResultCommissionCard(result: result),
        ],
        const SizedBox(height: ResultPageLayout.sectionGap),
        ResultCalculationDetails(
          result: result,
          initiallyExpanded: false,
        ),
        const SizedBox(height: ResultPageLayout.sectionGap),
        WhatsappPreviewRow(
          message: message,
          onCopyAndShare: _copyAndShare,
        ),
        const SizedBox(height: ResultPageLayout.sectionGap),
        _primaryCopyButton(),
        const SizedBox(height: ResultPageLayout.actionGap),
        _editButton(),
      ],
    );
  }

  Widget _buildIncompleteContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (item.isDraft) ...[
          _draftBanner(),
          const SizedBox(height: ResultPageLayout.sectionGap),
        ],
        Text(
          item.listTitle,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: ResultPageColors.navy,
          ),
        ),
        const SizedBox(height: ResultPageLayout.titleTopGap),
        _metadataStrip(),
        const SizedBox(height: ResultPageLayout.sectionGap),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: ResultPageLayout.cardDecoration(),
          child: Text(
            'This calculation is incomplete. Add rows and calculate to see the result.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: ResultPageColors.muted,
              height: 1.4,
            ),
          ),
        ),
        const SizedBox(height: ResultPageLayout.sectionGap),
        _editButton(),
      ],
    );
  }

  Widget _draftBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: ResultPageColors.tintedBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ResultPageColors.tintedBorder),
      ),
      child: Text(
        'DRAFT — not yet finalized',
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: ResultPageColors.muted,
        ),
      ),
    );
  }

  Widget _metadataStrip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: ResultPageColors.tintedBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: ResultPageColors.tintedBorder),
      ),
      child: Row(
        children: [
          _metaCell('Passing', formatRate(item.entry.passingRate)),
          _metaCell('Commission', formatRate(item.entry.amountDeductionRate)),
          _metaCell('Rows', '${item.rowCount}'),
        ],
      ),
    );
  }

  Widget _metaCell(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: ResultPageColors.muted,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: ResultPageColors.navy,
            ),
          ),
        ],
      ),
    );
  }

  Widget _primaryCopyButton() {
    return SizedBox(
      height: ResultPageLayout.primaryButtonHeight,
      child: ElevatedButton(
        onPressed: _copyAndShare,
        style: ElevatedButton.styleFrom(
          backgroundColor: _copied
              ? ResultPageColors.success
              : ResultPageColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _copied ? Icons.check_rounded : Icons.ios_share_rounded,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              _copied ? '✓ Message Copied' : 'Copy & Share Message',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _editButton() {
    return SizedBox(
      height: ResultPageLayout.secondaryButtonHeight,
      child: OutlinedButton(
        onPressed: widget.onEdit,
        style: OutlinedButton.styleFrom(
          foregroundColor: ResultPageColors.navy,
          backgroundColor: ResultPageColors.card,
          side: const BorderSide(color: ResultPageColors.border),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.edit_outlined, size: 15),
            const SizedBox(width: 6),
            Text(
              'Edit Calculation',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
