import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/validate.dart';
import 'dismiss_keyboard.dart';
import '../models/row_data.dart';
import '../theme/app_theme.dart';

class RowTable extends StatelessWidget {
  const RowTable({
    super.key,
    required this.rows,
    required this.entryNames,
    required this.onRowChanged,
    required this.onDeleteRow,
    required this.onAddRow,
    this.errorRowIndex,
  });

  final List<RowData> rows;
  final List<String> entryNames;
  final void Function(int index, RowData row) onRowChanged;
  final ValueChanged<int> onDeleteRow;
  final VoidCallback onAddRow;
  final int? errorRowIndex;

  int get _activeCount => rows.where((r) => !isRowEmpty(r)).length;

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
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: _TableHeader(),
          ),
          ...List.generate(rows.length, (index) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: _RowEntry(
                key: ValueKey(rows[index].id),
                index: index,
                row: rows[index],
                entryNames: entryNames,
                hasError: errorRowIndex == index,
                onChanged: (updated) => onRowChanged(index, updated),
                onDelete: () => onDeleteRow(index),
              ),
            );
          }),
          Material(
            color: AppColors.lightBlue,
            child: InkWell(
              onTap: onAddRow,
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add, size: 18, color: AppColors.primaryBlue),
                    const SizedBox(width: 6),
                    Text(
                      'Add Row',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader();

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

class _RowEntry extends StatefulWidget {
  const _RowEntry({
    super.key,
    required this.index,
    required this.row,
    required this.entryNames,
    required this.hasError,
    required this.onChanged,
    required this.onDelete,
  });

  final int index;
  final RowData row;
  final List<String> entryNames;
  final bool hasError;
  final ValueChanged<RowData> onChanged;
  final VoidCallback onDelete;

  @override
  State<_RowEntry> createState() => _RowEntryState();
}

class _RowEntryState extends State<_RowEntry> {
  late final TextEditingController _amountController;
  late final TextEditingController _bracketController;

  static final _amountFormatter = FilteringTextInputFormatter.allow(
    RegExp(r'[0-9,]'),
  );
  static final _bracketFormatter = FilteringTextInputFormatter.allow(
    RegExp(r'[0-9.,]'),
  );

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(text: widget.row.amount);
    _bracketController = TextEditingController(text: widget.row.bracket);
  }

  @override
  void didUpdateWidget(covariant _RowEntry oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.row.id != widget.row.id) {
      _sync(_amountController, widget.row.amount);
      _sync(_bracketController, widget.row.bracket);
    }
  }

  void _sync(TextEditingController c, String v) {
    if (c.text != v) c.text = v;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _bracketController.dispose();
    super.dispose();
  }

  void _emit({String? name}) {
    widget.onChanged(
      widget.row.copyWith(
        name: name ?? widget.row.name,
        amount: _amountController.text,
        bracket: _bracketController.text,
      ),
    );
  }

  InputDecoration _cellDeco() {
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
    final selectedName =
        widget.row.name.isNotEmpty && widget.entryNames.contains(widget.row.name)
            ? widget.row.name
            : null;

    return Container(
      height: AppSpacing.rowHeight,
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 3,
            child: DropdownButtonFormField<String>(
              key: ValueKey('${widget.row.id}-${widget.row.name}'),
              initialValue: selectedName,
              isExpanded: true,
              isDense: true,
              decoration: _cellDeco(),
              hint: Text('—', style: GoogleFonts.inter(fontSize: 13)),
              items: widget.entryNames
                  .map((n) => DropdownMenuItem(value: n, child: Text(n)))
                  .toList(),
              onTap: DismissKeyboard.unfocus,
              onChanged: (v) {
                DismissKeyboard.unfocus();
                if (v != null) _emit(name: v);
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 4,
            child: TextField(
              controller: _amountController,
              decoration: _cellDeco(),
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              inputFormatters: [_amountFormatter],
              onTapOutside: (_) => DismissKeyboard.unfocus(),
              onChanged: (_) => _emit(),
              style: GoogleFonts.inter(fontSize: 13),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: TextField(
              controller: _bracketController,
              decoration: _cellDeco(),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textInputAction: TextInputAction.done,
              inputFormatters: [_bracketFormatter],
              onTapOutside: (_) => DismissKeyboard.unfocus(),
              onChanged: (_) => _emit(),
              style: GoogleFonts.inter(fontSize: 13),
            ),
          ),
          SizedBox(
            width: 44,
            child: IconButton(
              onPressed: widget.onDelete,
              icon: const Icon(Icons.delete_outline, size: 18),
              color: AppColors.danger,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            ),
          ),
        ],
      ),
    );
  }
}
