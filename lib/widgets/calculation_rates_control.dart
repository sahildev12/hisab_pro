import 'package:decimal/decimal.dart';

import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';



import '../core/format.dart';

import '../core/money.dart';

import '../core/rate_usage.dart';

import '../core/validate_rate.dart';

import '../theme/app_theme.dart';

import 'hisab_pro_modal.dart';

import 'rate_edit_modal.dart';



class CalculationRates {

  const CalculationRates({

    required this.passingRate,

    required this.amountDeductionRate,

  });



  final Decimal passingRate;

  final Decimal amountDeductionRate;

}



class CalculationRatesControl extends StatelessWidget {

  CalculationRatesControl({

    super.key,

    required this.rates,

    required this.onRatesChanged,

    this.deductionLinkedToPassing = true,

    this.onDeductionLinkChanged,

    this.commissionTracking = false,

    this.onCommissionTrackingChanged,

    RateUsageService? rateUsageService,

  }) : _rateUsageService = rateUsageService ?? RateUsageService();



  final CalculationRates rates;

  final ValueChanged<CalculationRates> onRatesChanged;

  final bool deductionLinkedToPassing;

  final ValueChanged<bool>? onDeductionLinkChanged;

  final bool commissionTracking;

  final ValueChanged<bool>? onCommissionTrackingChanged;

  final RateUsageService _rateUsageService;



  static final _passingPresets = <Decimal>[

    Decimal.parse('90'),

    Decimal.parse('92'),

    Decimal.parse('95'),

    Decimal.parse('96'),

    Decimal.parse('98'),

  ];



  static final _commissionPresets = <Decimal>[

    Decimal.parse('2'),

    Decimal.parse('4'),

    Decimal.parse('5'),

    Decimal.parse('10'),

  ];



  void _showSuccess(BuildContext context, String message) {

    ScaffoldMessenger.of(context).showSnackBar(

      SnackBar(

        content: Text(message),

        behavior: SnackBarBehavior.floating,

        duration: const Duration(seconds: 2),

      ),

    );

  }



  void _showCommissionInfo(BuildContext context) {

    showHisabProModal<void>(

      context: context,

      builder: (dialogContext) {

        return HisabProModalCard(

          child: Column(

            crossAxisAlignment: CrossAxisAlignment.stretch,

            mainAxisSize: MainAxisSize.min,

            children: [

              Row(

                children: [

                  Container(

                    width: 48,

                    height: 48,

                    decoration: BoxDecoration(

                      color: HisabProModalColors.softBlue,

                      borderRadius: BorderRadius.circular(14),

                    ),

                    child: const Icon(

                      Icons.payments_outlined,

                      color: HisabProModalColors.primary,

                    ),

                  ),

                  const SizedBox(width: 12),

                  Expanded(

                    child: Text(

                      'Commission',

                      style: GoogleFonts.inter(

                        fontSize: 20,

                        fontWeight: FontWeight.w700,

                        color: HisabProModalColors.navy,

                      ),

                    ),

                  ),

                  IconButton(

                    onPressed: () => Navigator.pop(dialogContext),

                    icon: const Icon(Icons.close),

                    tooltip: 'Close',

                  ),

                ],

              ),

              const SizedBox(height: 12),

              Text(

                'Commission is calculated from Total Amount × Commission Rate. '

                'When Keep Commission Separate is enabled, it is saved to the '

                'commission balance and not deducted from today\'s total.',

                style: GoogleFonts.inter(

                  fontSize: 15,

                  height: 1.45,

                  color: HisabProModalColors.muted,

                ),

              ),

              const SizedBox(height: 20),

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

                  child: const Text('Got it'),

                ),

              ),

            ],

          ),

        );

      },

    );

  }



  Future<void> _editPassing(BuildContext context) async {

    final updated = await showRateEditModal(

      context: context,

      usageService: _rateUsageService,

      config: RateEditModalConfig(

        title: 'Passing Rate',

        subtitle: 'Enter the passing rate for this calculation',

        fieldLabel: 'Passing Rate',

        initialValue: rates.passingRate,

        defaultPresets: _passingPresets,

        kind: RateUsageKind.passing,

        validate: validatePassingRate,

        parse: parsePassingRate,

        successMessage: '✓ Passing rate updated',

      ),

    );

    if (updated == null || !context.mounted) return;



    final newDeduction = deductionLinkedToPassing

        ? suggestedAmountDeduction(updated)

        : rates.amountDeductionRate;



    onRatesChanged(

      CalculationRates(

        passingRate: updated,

        amountDeductionRate: newDeduction,

      ),

    );

    _showSuccess(context, '✓ Passing rate updated');

  }



  Future<void> _editDeduction(BuildContext context) async {

    final updated = await showRateEditModal(

      context: context,

      usageService: _rateUsageService,

      config: RateEditModalConfig(

        title: 'Commission Rate',

        subtitle: 'Enter the commission rate for this calculation',

        fieldLabel: 'Commission Rate',

        initialValue: rates.amountDeductionRate,

        defaultPresets: _commissionPresets,

        kind: RateUsageKind.commission,

        validate: validateDeductionRate,

        parse: parseDeductionRate,

        successMessage: '✓ Commission rate updated',

      ),

    );

    if (updated == null || !context.mounted) return;



    onDeductionLinkChanged?.call(false);

    onRatesChanged(

      CalculationRates(

        passingRate: rates.passingRate,

        amountDeductionRate: updated,

      ),

    );

    _showSuccess(context, '✓ Commission rate updated');

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

                label: 'Commission / Deduction',

                rate: rates.amountDeductionRate,

                onEdit: () => _editDeduction(context),

              ),

            ],

          ),

          if (onCommissionTrackingChanged != null) ...[

            const SizedBox(height: 8),

            Container(

              padding: const EdgeInsets.fromLTRB(10, 6, 8, 6),

              decoration: BoxDecoration(

                color: commissionTracking

                    ? AppColors.successLight

                    : AppColors.surfaceSoft,

                borderRadius: BorderRadius.circular(12),

                border: Border.all(

                  color: commissionTracking

                      ? AppColors.success.withValues(alpha: 0.25)

                      : AppColors.hairlineSoft,

                ),

              ),

              child: Row(

                children: [

                  Expanded(

                    child: Row(

                      children: [

                        Flexible(

                          child: Text(

                            'Keep Commission Separate',

                            style: GoogleFonts.inter(

                              fontSize: 13,

                              fontWeight: FontWeight.w600,

                              color: AppColors.inkDeep,

                            ),

                          ),

                        ),

                        IconButton(

                          visualDensity: VisualDensity.compact,

                          padding: EdgeInsets.zero,

                          constraints: const BoxConstraints(

                            minWidth: 24,

                            minHeight: 24,

                          ),

                          icon: Icon(

                            Icons.info_outline,

                            size: 15,

                            color: AppColors.slate,

                          ),

                          onPressed: () => _showCommissionInfo(context),

                        ),

                      ],

                    ),

                  ),

                  Switch.adaptive(

                    value: commissionTracking,

                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,

                    activeThumbColor: Colors.white,

                    activeTrackColor: AppColors.success,

                    onChanged: onCommissionTrackingChanged,

                  ),

                ],

              ),

            ),

          ],

        ],

      ),

    );

  }

}


