import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/format.dart';
import '../core/money.dart';
import '../core/validate_rate.dart';
import '../theme/app_theme.dart';

class CalculationRates {
  const CalculationRates({
    required this.passingRate,
    required this.amountDeductionRate,
  });

  final Decimal passingRate;
  final Decimal amountDeductionRate;
}

class CalculationRatesControl extends StatelessWidget {
  const CalculationRatesControl({
    super.key,
    required this.rates,
    required this.onRatesChanged,
    this.deductionLinkedToPassing = true,
    this.onDeductionLinkChanged,
  });

  final CalculationRates rates;
  final ValueChanged<CalculationRates> onRatesChanged;
  final bool deductionLinkedToPassing;
  final ValueChanged<bool>? onDeductionLinkChanged;

  Future<Decimal?> _editRate(
    BuildContext context, {
    required String title,
    required String label,
    required Decimal initial,
    required RateValidationResult Function(String) validate,
    required Decimal Function(String) parse,
  }) async {
    final controller = TextEditingController(text: formatPlainNumber(initial));
    String? error;

    return showDialog<Decimal>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(title),
              content: TextField(
                controller: controller,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                decoration: InputDecoration(
                  labelText: label,
                  suffixText: '%',
                  errorText: error,
                ),
                onChanged: (_) => setState(() => error = null),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    final validation = validate(controller.text);
                    if (!validation.isValid) {
                      setState(() => error = validation.errorMessage);
                      return;
                    }
                    Navigator.pop(context, parse(controller.text));
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _editPassing(BuildContext context) async {
    final updated = await _editRate(
      context,
      title: 'Passing Rate',
      label: 'Passing Rate',
      initial: rates.passingRate,
      validate: validatePassingRate,
      parse: parsePassingRate,
    );
    if (updated == null) return;

    final newDeduction = deductionLinkedToPassing
        ? suggestedAmountDeduction(updated)
        : rates.amountDeductionRate;

    onRatesChanged(
      CalculationRates(
        passingRate: updated,
        amountDeductionRate: newDeduction,
      ),
    );
  }

  Future<void> _editDeduction(BuildContext context) async {
    final updated = await _editRate(
      context,
      title: 'Amount Deduction',
      label: 'Amount Deduction',
      initial: rates.amountDeductionRate,
      validate: validateDeductionRate,
      parse: parseDeductionRate,
    );
    if (updated == null) return;

    onDeductionLinkChanged?.call(false);
    onRatesChanged(
      CalculationRates(
        passingRate: rates.passingRate,
        amountDeductionRate: updated,
      ),
    );
  }

  Widget _rateTile({
    required String label,
    required Decimal rate,
    required VoidCallback onEdit,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceSoft,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.hairlineSoft),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.slate,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    formatRate(rate),
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.inkDeep,
                    ),
                  ),
                ],
              ),
            ),
            InkWell(
              onTap: onEdit,
              borderRadius: BorderRadius.circular(20),
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Icon(
                  Icons.edit_outlined,
                  size: 16,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: surfaceDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Calculation Rates',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.slate,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _rateTile(
                label: 'Passing Rate',
                rate: rates.passingRate,
                onEdit: () => _editPassing(context),
              ),
              const SizedBox(width: 10),
              _rateTile(
                label: 'Amount Deduction',
                rate: rates.amountDeductionRate,
                onEdit: () => _editDeduction(context),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
