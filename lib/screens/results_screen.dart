import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import '../core/copy_message.dart';
import '../core/share_message.dart';
import '../core/storage.dart';
import '../models/calculation_result.dart';
import '../models/row_data.dart';
import '../theme/app_theme.dart';
import '../widgets/copy_button.dart';
import '../widgets/result_card.dart';

class ResultsScreen extends StatelessWidget {
  const ResultsScreen({
    super.key,
    required this.storage,
    required this.title,
    required this.rows,
    required this.result,
    required this.passingRate,
    required this.amountDeductionRate,
    required this.persistentHeader,
    required this.onEdit,
    required this.onBackWithNewCalculation,
  });

  final StorageService storage;
  final String persistentHeader;
  final String title;
  final List<RowData> rows;
  final CalculationResult result;
  final Decimal passingRate;
  final Decimal amountDeductionRate;
  final VoidCallback onEdit;
  final Future<void> Function() onBackWithNewCalculation;

  @override
  Widget build(BuildContext context) {
    final message = buildCopyMessage(
      title: title,
      rows: rows,
      result: result,
      persistentHeader: persistentHeader,
    );

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Result'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Share',
            onPressed: () async {
              await shareCalculationMessage(message);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Ready to share!'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ResultCard(title: title, result: result),
                const SizedBox(height: 20),
                CopyButton(message: message),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () async {
                    await onBackWithNewCalculation();
                  },
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: const Text('Back with New Calculation'),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () async {
                    await storage.saveDraft(
                      DraftState(
                        title: title,
                        rows: rows,
                        passingRate: passingRate,
                        amountDeductionRate: amountDeductionRate,
                        lastView: 'main',
                      ),
                    );
                    onEdit();
                  },
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Edit Calculation'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
