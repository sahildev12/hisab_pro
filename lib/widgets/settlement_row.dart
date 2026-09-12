import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/settlement_type.dart';
import '../theme/app_theme.dart';
import 'custom_rate_dropdown.dart';

class SettlementRow extends StatelessWidget {
  const SettlementRow({
    super.key,
    required this.value,
    required this.bracketRate,
    required this.onSettlementChanged,
    required this.onRateChanged,
  });

  final SettlementType value;
  final int bracketRate;
  final ValueChanged<SettlementType> onSettlementChanged;
  final ValueChanged<int> onRateChanged;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final stackRate = width < 360;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Settlement', style: sectionLabelStyle()),
        const SizedBox(height: 8),
        if (stackRate) ...[
          _segmentedControl(),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: CustomRateDropdown(
              value: bracketRate,
              onChanged: onRateChanged,
            ),
          ),
        ] else
          Row(
            children: [
              Expanded(child: _segmentedControl()),
              const SizedBox(width: 12),
              CustomRateDropdown(
                value: bracketRate,
                onChanged: onRateChanged,
              ),
            ],
          ),
      ],
    );
  }

  Widget _segmentedControl() {
    return Row(
      children: SettlementType.values.map((type) {
        final selected = value == type;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: type == SettlementType.lene ? 4 : 0,
              left: type == SettlementType.dene ? 4 : 0,
            ),
            child: Material(
              color: selected ? AppColors.primaryBlue : AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: () => onSettlementChanged(type),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected ? AppColors.primaryBlue : AppColors.border,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        type == SettlementType.lene
                            ? Icons.arrow_upward_rounded
                            : Icons.arrow_downward_rounded,
                        size: 14,
                        color: selected ? Colors.white : AppColors.primaryText,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        type.label,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: selected ? Colors.white : AppColors.primaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
