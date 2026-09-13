import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/format.dart';
import '../core/rate_usage.dart';
import '../core/validate_rate.dart';
import 'dismiss_keyboard.dart';
import 'hisab_pro_modal.dart';

class RateEditModalConfig {
  const RateEditModalConfig({
    required this.title,
    required this.subtitle,
    required this.fieldLabel,
    required this.initialValue,
    required this.defaultPresets,
    required this.kind,
    required this.validate,
    required this.parse,
    this.successMessage,
  });

  final String title;
  final String subtitle;
  final String fieldLabel;
  final Decimal initialValue;
  final List<Decimal> defaultPresets;
  final RateUsageKind kind;
  final RateValidationResult Function(String) validate;
  final Decimal Function(String) parse;
  final String? successMessage;
}

Future<Decimal?> showRateEditModal({
  required BuildContext context,
  required RateEditModalConfig config,
  RateUsageService? usageService,
}) {
  return showHisabProModal<Decimal>(
    context: context,
    builder: (dialogContext) {
      return _RateEditModalContent(
        config: config,
        usageService: usageService ?? RateUsageService(),
      );
    },
  );
}

class _RateEditModalContent extends StatefulWidget {
  const _RateEditModalContent({
    required this.config,
    required this.usageService,
  });

  final RateEditModalConfig config;
  final RateUsageService usageService;

  @override
  State<_RateEditModalContent> createState() => _RateEditModalContentState();
}

class _RateEditModalContentState extends State<_RateEditModalContent> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  String? _errorText;
  List<Decimal> _frequentRates = [];
  bool _loadingFrequent = true;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: formatPlainNumber(widget.config.initialValue),
    );
    _focusNode = FocusNode();
    _focusNode.addListener(() => setState(() {}));
    _loadFrequentRates();
  }

  Future<void> _loadFrequentRates() async {
    final rates = await widget.usageService.getMostUsedRates(widget.config.kind);
    if (mounted) {
      setState(() {
        _frequentRates = rates;
        _loadingFrequent = false;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _selectPreset(Decimal rate) {
    _controller.text = formatPlainNumber(rate);
    setState(() => _errorText = null);
  }

  void _close() => Navigator.of(context).pop();

  Future<void> _save() async {
    final validation = widget.config.validate(_controller.text);
    if (!validation.isValid) {
      setState(() => _errorText = validation.errorMessage);
      return;
    }

    final value = widget.config.parse(_controller.text);
    await widget.usageService.recordUsage(widget.config.kind, value);

    if (!mounted) return;
    Navigator.of(context).pop(value);

    final message = widget.config.successMessage;
    if (message != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final focused = _focusNode.hasFocus;

    return HisabProModalCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          _buildInput(focused),
          if (_errorText != null) ...[
            const SizedBox(height: 8),
            Text(
              _errorText!,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFFE41E3F),
              ),
            ),
          ],
          const SizedBox(height: 16),
          if (!_loadingFrequent && _frequentRates.isNotEmpty) ...[
            _presetSection(
              label: 'Your most used',
              rates: _frequentRates,
            ),
            const SizedBox(height: 12),
          ],
          _presetSection(
            label: 'Quick presets',
            rates: widget.config.defaultPresets,
          ),
          const SizedBox(height: 16),
          _buildActions(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: HisabProModalColors.softBlue,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.percent_rounded,
            color: HisabProModalColors.primary,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.config.title,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: HisabProModalColors.navy,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                widget.config.subtitle,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: HisabProModalColors.muted,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: _close,
          tooltip: 'Close',
          icon: const Icon(Icons.close, size: 20),
          color: HisabProModalColors.muted,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        ),
      ],
    );
  }

  Widget _buildInput(bool focused) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.config.fieldLabel,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: HisabProModalColors.navy,
          ),
        ),
        const SizedBox(height: 8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: focused
                  ? HisabProModalColors.primary
                  : HisabProModalColors.inputBorder,
              width: focused ? 2 : 1,
            ),
            boxShadow: focused
                ? const [
                    BoxShadow(
                      color: Color(0x1A2563EB),
                      blurRadius: 0,
                      spreadRadius: 3,
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: HisabProModalColors.navy,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                    isCollapsed: true,
                  ),
                  onTapOutside: (_) => DismissKeyboard.unfocus(),
                  onChanged: (_) => setState(() => _errorText = null),
                  onSubmitted: (_) => _save(),
                ),
              ),
              Text(
                '%',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: HisabProModalColors.muted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _presetSection({
    required String label,
    required List<Decimal> rates,
  }) {
    final current = _controller.text.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: HisabProModalColors.muted,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: rates.map((rate) {
              final text = formatPlainNumber(rate);
              final selected = current == text;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _PresetChip(
                  label: '$text%',
                  selected: selected,
                  onTap: () => _selectPreset(rate),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildActions() {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 48,
            child: OutlinedButton(
              onPressed: _close,
              style: OutlinedButton.styleFrom(
                foregroundColor: HisabProModalColors.navy,
                backgroundColor: Colors.white,
                side: const BorderSide(color: HisabProModalColors.inputBorder),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: const Text('Cancel'),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: HisabProModalColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: const Text('Save'),
            ),
          ),
        ),
      ],
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? HisabProModalColors.primary
              : HisabProModalColors.chipBg,
          borderRadius: BorderRadius.circular(21),
          border: Border.all(
            color: selected
                ? HisabProModalColors.primary
                : HisabProModalColors.border,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : HisabProModalColors.navy,
          ),
        ),
      ),
    );
  }
}
