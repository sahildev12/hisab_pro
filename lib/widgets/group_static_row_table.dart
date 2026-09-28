import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/validate.dart';
import '../models/row_data.dart';
import '../theme/app_theme.dart';
import 'dismiss_keyboard.dart';

/// Header chrome for the entries card (title, counts, reset buttons, columns).
class GroupEntriesHeader extends StatelessWidget {
  const GroupEntriesHeader({
    super.key,
    required this.rows,
    this.onReset,
    this.onResetDigits,
  });

  final List<RowData> rows;
  final VoidCallback? onReset;
  final VoidCallback? onResetDigits;

  int get _activeCount => rows.where((row) => !isRowEmpty(row)).length;

  @override
  Widget build(BuildContext context) {
    return Column(
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
                    icon: const Icon(Icons.pin_outlined, size: 18),
                    label: const Text('Reset Digits'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryBlue,
                      minimumSize: const Size(0, 40),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
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
                    icon: const Icon(Icons.restart_alt_rounded, size: 18),
                    label: const Text('Reset All'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.secondaryText,
                      minimumSize: const Size(0, 40),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
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
        const _TableHeader(),
      ],
    );
  }
}

/// Add-row actions shown below the entry list.
class GroupEntriesFooter extends StatelessWidget {
  const GroupEntriesFooter({
    super.key,
    required this.onAddRow,
    required this.onAddCustomEntry,
    this.canAddRow = true,
  });

  final VoidCallback onAddRow;
  final VoidCallback onAddCustomEntry;
  final bool canAddRow;

  @override
  Widget build(BuildContext context) {
    return Row(
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
    );
  }
}

class GroupEntryRow extends StatefulWidget {
  const GroupEntryRow({
    super.key,
    required this.row,
    required this.hasError,
    required this.onChanged,
    required this.onDelete,
    this.onMoveUp,
    this.onMoveDown,
  });

  final RowData row;
  final bool hasError;
  final void Function(RowData row) onChanged;
  final VoidCallback onDelete;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;

  @override
  State<GroupEntryRow> createState() => _GroupEntryRowState();
}

class _GroupEntryRowState extends State<GroupEntryRow> {
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
  void didUpdateWidget(covariant GroupEntryRow oldWidget) {
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
    if (controller.text == value) return;
    controller.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
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

  Widget _nameCell() {
    return Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        widget.row.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppColors.primaryText,
        ),
      ),
    );
  }

  Widget _moveButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required String tooltip,
  }) {
    return SizedBox(
      width: 30,
      height: 24,
      child: IconButton(
        onPressed: onPressed,
        tooltip: tooltip,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 30, minHeight: 24),
        visualDensity: VisualDensity.compact,
        icon: Icon(
          icon,
          size: 18,
          color: onPressed != null ? AppColors.secondaryText : AppColors.stone,
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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(flex: 3, child: _nameCell()),
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
          const SizedBox(width: 4),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _moveButton(
                icon: Icons.keyboard_arrow_up_rounded,
                onPressed: widget.onMoveUp,
                tooltip: 'Move up',
              ),
              _moveButton(
                icon: Icons.keyboard_arrow_down_rounded,
                onPressed: widget.onMoveDown,
                tooltip: 'Move down',
              ),
            ],
          ),
          SizedBox(
            width: 36,
            child: IconButton(
              onPressed: widget.onDelete,
              icon: const Icon(Icons.delete_outline, color: AppColors.danger),
              visualDensity: VisualDensity.compact,
              tooltip: 'Delete entry',
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
          Expanded(flex: 3, child: _HeaderLabel('Name')),
          SizedBox(width: 8),
          Expanded(flex: 4, child: _HeaderLabel('Amount')),
          SizedBox(width: 8),
          Expanded(flex: 3, child: _HeaderLabel('Bracket')),
          SizedBox(width: 34),
          SizedBox(width: 36),
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
