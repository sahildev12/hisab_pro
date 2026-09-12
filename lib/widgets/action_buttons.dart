import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class ActionButtons extends StatelessWidget {
  const ActionButtons({
    super.key,
    required this.onClearAll,
    required this.onCalculate,
    required this.onNewCalculation,
  });

  final VoidCallback onClearAll;
  final VoidCallback onCalculate;
  final VoidCallback onNewCalculation;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onClearAll,
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Clear All'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onNewCalculation,
                icon: const Icon(Icons.note_add_outlined, size: 18),
                label: const Text('New Calculation'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: AppSpacing.buttonHeight,
          child: ElevatedButton.icon(
            onPressed: onCalculate,
            icon: const Icon(Icons.calculate_outlined, size: 22),
            label: const Text('Calculate'),
          ),
        ),
      ],
    );
  }
}
