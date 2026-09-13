import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/calculate.dart';
import '../core/commission.dart';
import '../core/copy_message.dart';
import '../core/smart_text_parser.dart';
import '../core/storage.dart';
import '../core/validate.dart';
import '../models/calculation_group.dart';
import '../models/calculation_result.dart';
import '../theme/app_theme.dart';
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

  @override
  void initState() {
    super.initState();
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
    final data = await Clipboard.getData('text/plain');
    if (data?.text != null) {
      _textController.text = data!.text!;
    }
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
    return SmartTextParser.resolveRates(
      parsed: parsed,
      groupPassingRate: defaults.passingRate,
      groupDeductionRate: defaults.amountDeductionRate,
    );
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
    final rates = _resolveRates(parsed);
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

    final commissionTracking = widget.settings.defaultCommissionTracking;
    final storedBalance = await widget.storage.getCommissionBalance(
      commissionOwnerId(parsed.title),
    );

    final result = calculateSettlement(
      parsed.rows,
      passingRate: rates.passingRate,
      amountDeductionRate: rates.amountDeductionRate,
      commissionTracking: commissionTracking,
      storedCommissionBalance: storedBalance,
    );

    if (!mounted) return;
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

    await Clipboard.setData(ClipboardData(text: message));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(milliseconds: 1800),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Paste Calculation'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.primaryText,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  'Paste your calculation message',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryText,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _pasteFromClipboard,
                  icon: const Icon(Icons.content_paste, size: 18),
                  label: const Text('Paste'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _textController,
              maxLines: 14,
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
                  borderSide: const BorderSide(color: AppColors.border),
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
                      'Calculation couldn\'t be completed.',
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
                          e.lineNumber > 0
                              ? 'Line ${e.lineNumber}: ${e.message}\n"${e.lineText.trim()}"'
                              : e.message,
                          style: GoogleFonts.inter(fontSize: 13),
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
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _isCalculating ? null : _parseAndCalculate,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                minimumSize: const Size.fromHeight(AppSpacing.buttonHeight),
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
            if (_copyMessage != null) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _copyResult,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(AppSpacing.buttonHeight),
                ),
                icon: const Icon(Icons.copy_outlined, size: 18),
                label: const Text('Copy'),
              ),
            ],
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _reset,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(AppSpacing.buttonHeight),
              ),
              child: const Text('Reset'),
            ),
          ],
        ),
      ),
    );
  }
}
