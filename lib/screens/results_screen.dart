import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/copy_message.dart';
import '../core/share_message.dart';
import '../core/storage.dart';
import '../models/calculation_result.dart';
import '../models/row_data.dart';
import '../widgets/hisab_pro_modal.dart';
import '../widgets/result_page/result_calculation_details.dart';
import '../widgets/result_page/result_commission_card.dart';
import '../widgets/result_page/result_hero_card.dart';
import '../widgets/result_page/result_page_header.dart';
import '../widgets/result_page/result_page_theme.dart';
import '../widgets/result_page/result_summary_card.dart';
import '../widgets/result_page/whatsapp_preview_sheet.dart';

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({
    super.key,
    required this.storage,
    required this.title,
    required this.rows,
    required this.result,
    required this.passingRate,
    required this.amountDeductionRate,
    required this.commissionTracking,
    required this.storedCommissionBalance,
    required this.persistentHeader,
    required this.calculatedAt,
    required this.onBack,
    required this.onEdit,
    required this.onBackWithNewCalculation,
    this.onClearCommission,
    this.onViewHistory,
    this.onDeleteCalculation,
  });

  final StorageService storage;
  final String persistentHeader;
  final String title;
  final List<RowData> rows;
  final CalculationResult result;
  final Decimal passingRate;
  final Decimal amountDeductionRate;
  final bool commissionTracking;
  final Decimal storedCommissionBalance;
  final DateTime calculatedAt;
  final VoidCallback onBack;
  final VoidCallback onEdit;
  final Future<void> Function() onBackWithNewCalculation;
  final Future<void> Function()? onClearCommission;
  final VoidCallback? onViewHistory;
  final Future<void> Function()? onDeleteCalculation;

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  bool _copied = false;

  String get _message => buildCopyMessage(
        title: widget.title,
        rows: widget.rows,
        result: widget.result,
        persistentHeader: widget.persistentHeader,
      );

  Future<void> _copyAndShare() async {
    await shareCalculationMessage(_message);
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
    await shareCalculationMessage(_message);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ready to share'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(milliseconds: 1600),
      ),
    );
  }

  Future<void> _confirmDelete() async {
    if (widget.onDeleteCalculation == null) return;
    final confirmed = await showHisabProConfirmDialog(
      context: context,
      title: 'Delete Calculation?',
      message:
          'This calculation will be removed from history. This cannot be undone.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (confirmed == true) {
      await widget.onDeleteCalculation!();
    }
  }

  Future<void> _editCalculation() async {
    await widget.storage.saveDraft(
      DraftState(
        title: widget.title,
        rows: widget.rows,
        passingRate: widget.passingRate,
        amountDeductionRate: widget.amountDeductionRate,
        commissionTracking: widget.commissionTracking,
        lastView: 'main',
      ),
    );
    widget.onEdit();
  }

  @override
  Widget build(BuildContext context) {
    final displayTitle =
        widget.title.trim().isEmpty ? 'Calculation' : widget.title.trim();
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: ResultPageColors.canvas,
      body: Column(
        children: [
          ResultPageHeader(
            onBack: widget.onBack,
            onShare: _shareOnly,
            onViewHistory: widget.onViewHistory,
            onDelete: widget.onDeleteCalculation == null
                ? null
                : _confirmDelete,
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        displayTitle,
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
                      ResultHeroCard(result: widget.result),
                      const SizedBox(height: ResultPageLayout.sectionGap),
                      ResultSummaryCard(result: widget.result),
                      if (widget.result.commissionTracking) ...[
                        const SizedBox(height: ResultPageLayout.sectionGap),
                        ResultCommissionCard(result: widget.result),
                      ],
                      const SizedBox(height: ResultPageLayout.sectionGap),
                      ResultCalculationDetails(
                        result: widget.result,
                        initiallyExpanded: false,
                      ),
                      const SizedBox(height: ResultPageLayout.sectionGap),
                      WhatsappPreviewRow(
                        message: _message,
                        onCopyAndShare: _copyAndShare,
                      ),
                      const SizedBox(height: ResultPageLayout.sectionGap),
                      _primaryCopyButton(),
                      const SizedBox(height: ResultPageLayout.actionGap),
                      Row(
                        children: [
                          Expanded(
                            child: _secondaryButton(
                              label: 'Edit Calculation',
                              icon: Icons.edit_outlined,
                              onPressed: _editCalculation,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _secondaryButton(
                              label: 'New Calculation',
                              icon: Icons.add_circle_outline_rounded,
                              onPressed: widget.onBackWithNewCalculation,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
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

  Widget _secondaryButton({
    required String label,
    required IconData icon,
    required Future<void> Function() onPressed,
  }) {
    return SizedBox(
      height: ResultPageLayout.secondaryButtonHeight,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: ResultPageColors.navy,
          backgroundColor: ResultPageColors.card,
          side: const BorderSide(color: ResultPageColors.border),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
