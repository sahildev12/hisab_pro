import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/format.dart';
import '../core/money.dart';
import '../core/parse_number.dart';
import '../core/storage.dart';
import '../core/validate_rate.dart';
import '../theme/app_theme.dart';

class CalculationDefaultsScreen extends StatefulWidget {
  const CalculationDefaultsScreen({
    super.key,
    required this.initialSettings,
  });

  final AppSettings initialSettings;

  @override
  State<CalculationDefaultsScreen> createState() =>
      _CalculationDefaultsScreenState();
}

class _CalculationDefaultsScreenState extends State<CalculationDefaultsScreen> {
  late final TextEditingController _passingController;
  late final TextEditingController _deductionController;
  String? _passingError;
  String? _deductionError;
  bool _deductionLinked = true;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _passingController = TextEditingController(
      text: formatPlainNumber(widget.initialSettings.defaultPassingRate),
    );
    _deductionController = TextEditingController(
      text: formatPlainNumber(
        widget.initialSettings.defaultAmountDeductionRate,
      ),
    );
  }

  @override
  void dispose() {
    _passingController.dispose();
    _deductionController.dispose();
    super.dispose();
  }

  void _onPassingChanged(String value) {
    setState(() {
      _passingError = null;
      _saved = false;
      if (_deductionLinked) {
        final parsed = tryParseDecimal(value);
        if (parsed != null) {
          _deductionController.text =
              formatPlainNumber(suggestedAmountDeduction(parsed));
        }
      }
    });
  }

  void _onDeductionChanged(String _) {
    setState(() {
      _deductionError = null;
      _deductionLinked = false;
      _saved = false;
    });
  }

  void _save() {
    final passingValidation = validatePassingRate(_passingController.text);
    final deductionValidation = validateDeductionRate(_deductionController.text);

    setState(() {
      _passingError =
          passingValidation.isValid ? null : passingValidation.errorMessage;
      _deductionError = deductionValidation.isValid
          ? null
          : deductionValidation.errorMessage;
    });

    if (!passingValidation.isValid || !deductionValidation.isValid) return;

    final updated = widget.initialSettings.copyWith(
      defaultPassingRate: parsePassingRate(_passingController.text),
      defaultAmountDeductionRate: parseDeductionRate(_deductionController.text),
    );

    setState(() => _saved = true);
    Navigator.pop(context, updated);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Calculation Defaults')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Default Percentages',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            _rateCard(
              icon: Icons.calculate_outlined,
              label: 'Passing Rate',
              hint: 'Used with Total Bracket (e.g. 89.6 × 96)',
              controller: _passingController,
              error: _passingError,
              onChanged: _onPassingChanged,
            ),
            const SizedBox(height: 14),
            _rateCard(
              icon: Icons.remove_circle_outline,
              label: 'Amount Deduction',
              hint: 'Deducted from Total Amount (e.g. 56000 × 4%)',
              controller: _deductionController,
              error: _deductionError,
              onChanged: _onDeductionChanged,
            ),
            const SizedBox(height: 12),
            Text(
              'These defaults apply to new calculations only.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.secondaryText,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _save,
              style: fullWidthPrimaryButtonStyle(),
              child: const Text('Save Settings'),
            ),
            if (_saved) ...[
              const SizedBox(height: 12),
              Text(
                'Settings saved successfully!',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: AppColors.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _rateCard({
    required IconData icon,
    required String label,
    required String hint,
    required TextEditingController controller,
    required String? error,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: surfaceDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primaryBlue, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            hint,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.secondaryText,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            decoration: InputDecoration(
              suffixText: '%',
              errorText: error,
            ),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
