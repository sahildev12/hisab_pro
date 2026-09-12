import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/copy_message.dart';
import '../core/storage.dart';
import '../models/calculation_result.dart';
import '../models/row_data.dart';
import '../models/settlement_type.dart';
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
    required this.settlementType,
    required this.bracketRate,
    required this.onBack,
  });

  final StorageService storage;
  final String title;
  final List<RowData> rows;
  final CalculationResult result;
  final SettlementType settlementType;
  final int bracketRate;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final message = buildCopyMessage(
      title: title,
      rows: rows,
      result: result,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: onBack,
          tooltip: 'Back / Edit',
        ),
        title: const Text('Result'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Share',
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: message));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Message copied to clipboard!'),
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
                OutlinedButton.icon(
                  onPressed: () async {
                    await storage.save(
                      SavedState(
                        title: title,
                        rows: rows,
                        lastView: 'main',
                        settlementType: settlementType,
                        bracketRate: bracketRate,
                      ),
                    );
                    onBack();
                  },
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Back / Edit'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
