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
    required this.onReorder,
    this.onReset,
    this.errorRowIndex,
    this.canAddRow = true,
  });

  final List<RowData> rows;
  final void Function(int index, RowData row) onRowChanged;
  final ValueChanged<int> onDeleteRow;
  final VoidCallback onAddRow;
  final VoidCallback onAddCustomEntry;
  final void Function(int oldIndex, int newIndex) onReorder;
  final VoidCallback? onReset;
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
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
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
                if (onReset != null) ...[
                  TextButton(
                    onPressed: onReset,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      foregroundColor: AppColors.secondaryText,
                    ),
                    child: Text(
                      'Reset',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  '$_activeCount rows',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.secondaryText,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: _TableHeader(),
          ),
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            itemCount: rows.length,
            onReorder: onReorder,
            itemBuilder: (context, index) {
              final row = rows[index];
              return Padding(
                key: ValueKey(row.id),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: _StaticRowEntry(
                  index: index,
                  row: row,
                  hasError: errorRowIndex == index,
                  onChanged: (updated) => onRowChanged(index, updated),
                  onDelete: () => onDeleteRow(index),
                ),
              );
            },
          ),
          Row(
            children: [
              Expanded(
                child: Material(
                  color: AppColors.lightBlue,
                  child: InkWell(
                    onTap: canAddRow ? onAddRow : null,
                    child: SizedBox(
                      height: 42,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add,
                            size: 16,
                            color: canAddRow
                                ? AppColors.primaryBlue
                                : AppColors.stone,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Add Row',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: canAddRow
                                  ? AppColors.primaryBlue
                                  : AppColors.stone,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Material(
                  color: AppColors.surfaceSoft,
                  child: InkWell(
                    onTap: onAddCustomEntry,
                    child: SizedBox(
                      height: 42,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.edit_outlined,
                            size: 16,
                            color: AppColors.primaryBlue,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'Custom Name',
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryBlue,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
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
          SizedBox(width: 28),
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
          SizedBox(width: 44),
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
    required this.index,
    required this.row,
    required this.hasError,
    required this.onChanged,
    required this.onDelete,
  });

  final int index;
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
    if (oldWidget.row.id != widget.row.id) {
      _sync(_amountController, widget.row.amount);
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
          ReorderableDragStartListener(
            index: widget.index,
            child: const Padding(
              padding: EdgeInsets.only(right: 4),
              child: Icon(
                Icons.drag_handle,
                color: AppColors.slate,
                size: 22,
              ),
            ),
          ),
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
          ),
        ],
      ),
    );
  }
}
