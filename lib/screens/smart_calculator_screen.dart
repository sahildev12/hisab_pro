import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/calculate.dart' show calculateSettlement, defaultAmountDeductionRate, defaultPassingRate;
import '../core/clipboard_reader.dart';
import '../core/commission.dart';
import '../core/copy_message.dart';
import '../core/format.dart';
import '../core/smart_text_parser.dart';
import '../core/storage.dart';
import '../core/validate.dart';
import '../models/calculation_group.dart';
import '../models/calculation_result.dart';
import '../models/paste_recent_entry.dart';
import '../theme/app_theme.dart';
import '../core/share_message.dart';
import '../widgets/commission_balance_card.dart';
import '../widgets/hisab_pro_modal.dart';
import '../widgets/paste_result_summary.dart';

class SmartCalculatorScreen extends StatefulWidget {
  const SmartCalculatorScreen({
    super.key,
    required this.storage,
    required this.settings,
    required this.groups,
    required this.entryNames,
    this.initialGroup,
    this.onComplete,
  });

  final StorageService storage;
  final AppSettings settings;
  final List<CalculationGroup> groups;
  final List<String> entryNames;
  final CalculationGroup? initialGroup;
  final VoidCallback? onComplete;

  @override
  State<SmartCalculatorScreen> createState() => _SmartCalculatorScreenState();
}

class _SmartCalculatorScreenState extends State<SmartCalculatorScreen> {
  final _textController = TextEditingController();
  SmartParseResult? _parsed;
  CalculationResult? _result;
  List<SmartParseLineError> _errors = [];
  String _persistentHeader = '';
  bool _isCalculating = false;
  bool _commissionTracking = false;
  Decimal _passingRate = defaultPassingRate;
  Decimal _amountDeductionRate = defaultAmountDeductionRate;

  bool get _commissionEnabled => widget.settings.commissionEnabled;

  @override
  void initState() {
    super.initState();
    _commissionTracking = _commissionEnabled &&
        widget.settings.defaultCommissionTracking;
    _passingRate = widget.settings.defaultPassingRate;
    _amountDeductionRate = widget.settings.defaultAmountDeductionRate;
    _textController.addListener(_persistDraft);
    _loadInitialState();
  }

  Future<void> _loadInitialState() async {
    _persistentHeader = await widget.storage.loadPersistentHeader();
    final savedText = await widget.storage.loadPasteCalculationDraft();
    if (!mounted || savedText == null || savedText.isEmpty) return;

    _textController.text = savedText;
    await _parseAndCalculate(silent: true);
  }

  void _persistDraft() {
    widget.storage.savePasteCalculationDraft(_textController.text);
  }

  @override
  void dispose() {
    _textController.removeListener(_persistDraft);
    widget.storage.savePasteCalculationDraft(_textController.text);
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pasteFromClipboard() async {
    String? text;
    try {
      text = await readClipboardText();
    } catch (_) {
      text = null;
    }

    if (text != null && text.trim().isNotEmpty) {
      setState(() {
        _textController.text = text!.trim();
        _errors = [];
      });
      await widget.storage.savePasteCalculationDraft(_textController.text);
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          kIsWeb
              ? 'Allow clipboard access, or tap the box and paste manually.'
              : 'Nothing to paste. Copy a calculation message first.',
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  String _formatError(SmartParseLineError error) {
    if (error.lineNumber <= 0 || error.lineText.trim().isEmpty) {
      return error.message;
    }
    return 'Line ${error.lineNumber}: ${error.message}\n"${error.lineText.trim()}"';
  }

  InputBorder _pasteFieldBorder({required bool focused, required bool hasError}) {
    final color = hasError
        ? AppColors.danger
        : AppColors.danger.withValues(alpha: 0.65);
    final width = hasError ? 2.0 : 1.5;

    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  Future<void> _reset() async {
    await widget.storage.clearPasteCalculationDraft();
    setState(() {
      _textController.clear();
      _parsed = null;
      _result = null;
      _errors = [];
      _isCalculating = false;
    });
  }

  ({Decimal passingRate, Decimal amountDeductionRate}) _resolveRates(
    SmartParseResult parsed,
  ) {
    final defaults = (
      passingRate: widget.settings.defaultPassingRate,
      amountDeductionRate: widget.settings.defaultAmountDeductionRate,
    );
    final resolved = SmartTextParser.resolveRates(
      parsed: parsed,
      groupPassingRate: defaults.passingRate,
      groupDeductionRate: defaults.amountDeductionRate,
    );
    _passingRate = resolved.passingRate;
    _amountDeductionRate = resolved.amountDeductionRate;
    return resolved;
  }

  Future<void> _clearCommission() async {
    if (_parsed == null) return;
    final confirmed = await showHisabProConfirmDialog(
      context: context,
      title: 'Clear commission balance?',
      message: 'This resets the saved commission balance for this title.',
      confirmLabel: 'Clear',
      destructive: true,
    );
    if (confirmed != true || !mounted) return;

    final ownerId = commissionOwnerId(_parsed!.title);
    await widget.storage.setCommissionBalance(ownerId, Decimal.zero);
    if (_parsed != null) await _parseAndCalculate(silent: true);
  }

  Future<void> _parseAndCalculate({bool silent = false}) async {
    if (!silent) {
      await widget.storage.savePasteCalculationDraft(_textController.text);
    }

    setState(() {
      _isCalculating = true;
      _errors = [];
      _parsed = null;
      _result = null;
    });

    final output = SmartTextParser.parse(
      _textController.text,
      allowedEntryNames: widget.entryNames,
    );

    if (output.errors.isNotEmpty || output.result == null) {
      setState(() {
        _errors = output.errors;
        _isCalculating = false;
      });
      return;
    }

    final parsed = output.result!;
    _resolveRates(parsed);
    final validation = validateRows(parsed.rows, allowedNames: widget.entryNames);

    if (!validation.isValid) {
      setState(() {
        _errors = [
          SmartParseLineError(
            lineNumber: validation.rowIndex != null
                ? validation.rowIndex! + 1
                : 0,
            lineText: '',
            message: validation.errorMessage ?? 'Validation failed.',
          ),
        ];
        _isCalculating = false;
      });
      return;
    }

    final ownerId = commissionOwnerId(parsed.title);
    final storedBalance = await widget.storage.getCommissionBalance(ownerId);

    var result = calculateSettlement(
      parsed.rows,
      passingRate: _passingRate,
      amountDeductionRate: _amountDeductionRate,
      commissionTracking: _commissionTracking,
      storedCommissionBalance: storedBalance,
    );

    if (_commissionTracking && !silent) {
      await widget.storage.setCommissionBalance(ownerId, result.commissionBalance);
    }

    if (!mounted) return;

    if (!silent) {
      await widget.storage.addPasteRecent(
        text: _textController.text,
        title: parsed.title,
      );
    }
    setState(() {
      _parsed = parsed;
      _result = result;
      _errors = [];
      _isCalculating = false;
    });
    if (!silent) {
      widget.onComplete?.call();
    }
  }

  Future<void> _loadRecent(PasteRecentEntry entry) async {
    _textController.text = entry.text;
    await widget.storage.savePasteCalculationDraft(entry.text);
    if (!mounted) return;
    Navigator.pop(context);
    await _parseAndCalculate();
  }

  Future<void> _openRecents() async {
    var recents = await widget.storage.loadPasteRecents();
    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Recent',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryText,
                          ),
                        ),
                        const Spacer(),
                        if (recents.isNotEmpty)
                          TextButton(
                            onPressed: () async {
                              final confirmed =
                                  await showHisabProConfirmDialog(
                                context: context,
                                title: 'Clear all recent?',
                                message:
                                    'This will remove all saved paste calculations from Recent.',
                                confirmLabel: 'Clear all',
                                destructive: true,
                              );
                              if (confirmed != true) return;
                              await widget.storage.clearPasteRecents();
                              recents = [];
                              setSheetState(() {});
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.danger,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                            ),
                            child: Text(
                              'Clear all',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (recents.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          'No recent paste calculations yet.',
                          textAlign: TextAlign.center,
                          style:
                              GoogleFonts.inter(color: AppColors.secondaryText),
                        ),
                      )
                    else
                      Flexible(
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: recents.length,
                          separatorBuilder: (_, __) =>
                              const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final entry = recents[index];
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                entry.title.isNotEmpty
                                    ? entry.title
                                    : entry.preview,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                '${formatHistoryCardDate(entry.savedAt)} • ${entry.preview}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppColors.secondaryText,
                                ),
                              ),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: AppColors.danger,
                                  size: 20,
                                ),
                                onPressed: () async {
                                  await widget.storage
                                      .deletePasteRecent(entry.id);
                                  recents =
                                      await widget.storage.loadPasteRecents();
                                  setSheetState(() {});
                                },
                              ),
                              onTap: () => _loadRecent(entry),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String? get _copyMessage {
    if (_parsed == null || _result == null) return null;
    return buildPasteCopyMessage(
      title: _parsed!.title,
      rows: _parsed!.rows,
      result: _result!,
      persistentHeader: _persistentHeader,
    );
  }

  Future<void> _copyResult() async {
    final message = _copyMessage;
    if (message == null) return;

    await copyCalculationMessage(message);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(milliseconds: 1800),
      ),
    );
  }

  Future<void> _shareResult() async {
    final message = _copyMessage;
    if (message == null) return;

    await shareOnlyCalculationMessage(message);
  }

  Widget _buildCopyShareRow({required bool enabled}) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: enabled ? _copyResult : null,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryBlue,
              backgroundColor: AppColors.surface,
              side: const BorderSide(color: AppColors.border),
              minimumSize: const Size.fromHeight(AppSpacing.buttonHeight),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.copy_outlined, size: 18),
            label: const Text('Copy'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: enabled ? _shareResult : null,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryBlue,
              backgroundColor: AppColors.surface,
              side: const BorderSide(color: AppColors.border),
              minimumSize: const Size.fromHeight(AppSpacing.buttonHeight),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.share_outlined, size: 18),
            label: const Text('Share'),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final canCopyShare = _copyMessage != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Paste Calculation'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.primaryText,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Recent',
            onPressed: _openRecents,
            icon: const Icon(Icons.history_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pagePadding,
                AppSpacing.pagePadding,
                AppSpacing.pagePadding,
                12,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _reset,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryBlue,
                      backgroundColor: AppColors.surface,
                      side: const BorderSide(color: AppColors.border),
                      minimumSize:
                          const Size.fromHeight(AppSpacing.buttonHeight),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.clear_all_rounded, size: 18),
                    label: const Text('Clear All'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _pasteFromClipboard,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      minimumSize:
                          const Size.fromHeight(AppSpacing.buttonHeight),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.content_paste_rounded, size: 18),
                    label: const Text('Paste'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _textController,
              maxLines: 14,
              onChanged: (_) {
                if (_errors.isNotEmpty) {
                  setState(() => _errors = []);
                }
              },
              decoration: InputDecoration(
                hintText: 'Required — paste lines like: Sb. 2580 255',
                hintStyle: GoogleFonts.inter(
                  color: AppColors.secondaryText,
                  fontSize: 14,
                ),
                filled: true,
                fillColor: AppColors.surface,
                enabledBorder: _pasteFieldBorder(
                  focused: false,
                  hasError: _errors.isNotEmpty,
                ),
                focusedBorder: _pasteFieldBorder(
                  focused: true,
                  hasError: _errors.isNotEmpty,
                ),
                errorBorder: _pasteFieldBorder(
                  focused: false,
                  hasError: true,
                ),
                focusedErrorBorder: _pasteFieldBorder(
                  focused: true,
                  hasError: true,
                ),
              ),
            ),
            if (_errors.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.danger.withValues(alpha: 0.25),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Please check your pasted message',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        color: AppColors.danger,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._errors.map(
                      (e) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          _formatError(e),
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.primaryText,
                            height: 1.45,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (_result != null) ...[
              const SizedBox(height: 16),
              PasteResultSummary(result: _result!),
              if (_commissionEnabled && _result!.showsCommissionInfo) ...[
                const SizedBox(height: 12),
                CommissionBalanceCard(
                  result: _result!,
                  onClear:
                      _result!.commissionTracking ? _clearCommission : null,
                ),
              ],
            ],
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pagePadding,
                8,
                AppSpacing.pagePadding,
                AppSpacing.pagePadding,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton(
                    onPressed: _isCalculating ? null : _parseAndCalculate,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      minimumSize:
                          const Size.fromHeight(AppSpacing.buttonHeight),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isCalculating
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Calculate'),
                  ),
                  const SizedBox(height: 8),
                  _buildCopyShareRow(enabled: canCopyShare),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
