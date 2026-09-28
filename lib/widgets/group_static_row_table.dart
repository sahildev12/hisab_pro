import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/validate.dart';
import '../models/row_data.dart';
import '../theme/app_theme.dart';
import 'dismiss_keyboard.dart';

class GroupStaticRowTable extends StatelessWidget {
  const GroupStaticRowTable({
    super.key,
    required this.rows,
    required this.onRowChanged,
    required this.onDeleteRow,
    required this.onAddRow,
    required this.onAddCustomEntry,
    this.onReset,
    this.onResetDigits,
    this.errorRowIndex,
    this.canAddRow = true,
  });

  final List<RowData> rows;
  final void Function(int index, RowData row) onRowChanged;
  final ValueChanged<int> onDeleteRow;
  final VoidCallback onAddRow;
  final VoidCallback onAddCustomEntry;
  final VoidCallback? onReset;
  final VoidCallback? onResetDigits;
  final int? errorRowIndex;
  final bool canAddRow;

  int get _activeCount => rows.where((row) => !isRowEmpty(row)).length;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: surfaceDecoration(context),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Text(
                      'Entries',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryText,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '$_activeCount rows',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],
                ),
                if (onResetDigits != null || onReset != null) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      if (onResetDigits != null)
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: onResetDigits,
                            icon: const Icon(
                              Icons.pin_outlined,
                              size: 18,
                            ),
                            label: const Text('Reset Digits'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primaryBlue,
                              minimumSize: const Size(0, 40),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              textStyle: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      if (onResetDigits != null && onReset != null)
                        const SizedBox(width: 8),
                      if (onReset != null)
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: onReset,
                            icon: const Icon(
                              Icons.restart_alt_rounded,
                              size: 18,
                            ),
                            label: const Text('Reset All'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.secondaryText,
                              minimumSize: const Size(0, 40),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              textStyle: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: _TableHeader(),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: rows.length,
            itemBuilder: (context, index) {
              final row = rows[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: _StaticRowEntry(
                  row: row,
                  hasError: errorRowIndex == index,
                  onChanged: (updated) => onRowChanged(index, updated),
                  onDelete: () => onDeleteRow(index),
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: canAddRow ? onAddRow : null,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryBlue,
                      backgroundColor: AppColors.lightBlue,
                      side: BorderSide(
                        color: canAddRow
                            ? AppColors.primaryBlue.withValues(alpha: 0.25)
                            : AppColors.border,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: Icon(
                      Icons.add_rounded,
                      size: 16,
                      color: canAddRow ? AppColors.primaryBlue : AppColors.stone,
                    ),
                    label: Text(
                      'Add Row',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onAddCustomEntry,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryBlue,
                      backgroundColor: AppColors.surface,
                      side: const BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: Text(
                      'Custom Name',
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: const Row(
        children: [
          Expanded(
            flex: 3,
            child: _HeaderLabel('Name'),
          ),
          SizedBox(width: 8),
          Expanded(
            flex: 4,
            child: _HeaderLabel('Amount'),
          ),
          SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: _HeaderLabel('Bracket'),
          ),
          SizedBox(width: 40),
        ],
      ),
    );
  }
}

class _HeaderLabel extends StatelessWidget {
  const _HeaderLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.secondaryText,
      ),
    );
  }
}

class _StaticRowEntry extends StatefulWidget {
  const _StaticRowEntry({
    required this.row,
    required this.hasError,
    required this.onChanged,
    required this.onDelete,
  });

  final RowData row;
  final bool hasError;
  final ValueChanged<RowData> onChanged;
  final VoidCallback onDelete;

  @override
  State<_StaticRowEntry> createState() => _StaticRowEntryState();
}

class _StaticRowEntryState extends State<_StaticRowEntry> {
  late final TextEditingController _amountController;
  late final TextEditingController _bracketController;

  static final _amountFormatter =
      FilteringTextInputFormatter.allow(RegExp(r'[0-9,]'));
  static final _bracketFormatter =
      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'));

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(text: widget.row.amount);
    _bracketController = TextEditingController(text: widget.row.bracket);
  }

  @override
  void didUpdateWidget(covariant _StaticRowEntry oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.row.id != widget.row.id ||
        oldWidget.row.amount != widget.row.amount) {
      _sync(_amountController, widget.row.amount);
    }
    if (oldWidget.row.id != widget.row.id ||
        oldWidget.row.bracket != widget.row.bracket) {
      _sync(_bracketController, widget.row.bracket);
    }
  }

  void _sync(TextEditingController controller, String value) {
    if (controller.text != value) controller.text = value;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _bracketController.dispose();
    super.dispose();
  }

  void _emit() {
    widget.onChanged(
      widget.row.copyWith(
        amount: _amountController.text,
        bracket: _bracketController.text,
      ),
    );
  }

  InputDecoration _cellDecoration() {
    final borderColor = widget.hasError ? AppColors.danger : AppColors.border;
    return InputDecoration(
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      filled: true,
      fillColor: AppColors.surface,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: widget.hasError ? AppColors.danger : AppColors.primaryBlue,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      color: AppColors.surface,
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Container(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surfaceSoft,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                widget.row.name,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryText,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 4,
            child: TextField(
              controller: _amountController,
              onChanged: (_) => _emit(),
              onTapOutside: (_) => DismissKeyboard.unfocus(),
              keyboardType: TextInputType.number,
              inputFormatters: [_amountFormatter],
              decoration: _cellDecoration(),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: TextField(
              controller: _bracketController,
              onChanged: (_) => _emit(),
              onTapOutside: (_) => DismissKeyboard.unfocus(),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [_bracketFormatter],
              decoration: _cellDecoration(),
            ),
          ),
          IconButton(
            onPressed: widget.onDelete,
            icon: const Icon(Icons.delete_outline, color: AppColors.danger),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}
