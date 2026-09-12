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
              child: _secondaryButton(
                onPressed: onClearAll,
                icon: Icons.delete_outline,
                label: 'Clear All',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _secondaryButton(
                onPressed: onNewCalculation,
                icon: Icons.note_add_outlined,
                label: 'New Calc.',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: onCalculate,
          style: fullWidthPrimaryButtonStyle(),
          icon: const Icon(Icons.calculate_outlined, size: 20),
          label: const Text('Calculate'),
        ),
      ],
    );
  }

  Widget _secondaryButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
  }) {
    return SizedBox(
      height: 44,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 17),
        label: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
