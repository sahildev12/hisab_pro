import 'dart:async';

import 'package:flutter/material.dart';

import '../core/calculate.dart';
import '../core/storage.dart';
import '../core/validate.dart';
import '../models/calculation_result.dart';
import '../models/row_data.dart';
import '../models/settlement_type.dart';
import '../theme/app_theme.dart';
import '../widgets/action_buttons.dart';
import '../widgets/empty_state.dart';
import '../widgets/header.dart';
import '../widgets/live_preview.dart';
import '../widgets/quick_summary_strip.dart';
import '../widgets/row_table.dart';
import '../widgets/settlement_row.dart';
import '../widgets/title_input.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({
    super.key,
    required this.storage,
    required this.initialTitle,
    required this.initialRows,
    required this.initialSettlementType,
    required this.initialBracketRate,
    required this.onCalculate,
    required this.onNewCalculation,
  });

  final StorageService storage;
  final String initialTitle;
  final List<RowData> initialRows;
  final SettlementType initialSettlementType;
  final int initialBracketRate;
  final void Function(
    String title,
    List<RowData> rows,
    CalculationResult result,
    SettlementType settlementType,
    int bracketRate,
  ) onCalculate;
  final VoidCallback onNewCalculation;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late final TextEditingController _titleController;
  late List<RowData> _rows;
  late SettlementType _settlementType;
  late int _bracketRate;
  String? _errorMessage;
  int? _errorRowIndex;
  Timer? _saveTimer;
  CalculationResult? _preview;

  bool get _hasRowData => _rows.any((row) => !isRowEmpty(row));

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);
    _rows = List<RowData>.from(widget.initialRows);
    _settlementType = widget.initialSettlementType;
    _bracketRate = widget.initialBracketRate;
    _updatePreview();
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    _titleController.dispose();
    super.dispose();
  }

  RowData _newRow() =>
      RowData.empty(id: DateTime.now().microsecondsSinceEpoch.toString());

  void _scheduleSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 300), _persist);
  }

  Future<void> _persist() async {
    await widget.storage.save(
      SavedState(
        title: _titleController.text,
        rows: _rows,
        lastView: 'main',
        settlementType: _settlementType,
        bracketRate: _bracketRate,
      ),
    );
  }

  void _updatePreview() {
    if (!_hasRowData) {
      setState(() => _preview = null);
      return;
    }
    final validation = validateRows(_rows);
    if (!validation.isValid) {
      setState(() => _preview = null);
      return;
    }
    try {
      final result = calculate(
        _rows,
        multiplier: _bracketRate,
        settlementType: _settlementType,
      );
      setState(() => _preview = result);
    } catch (_) {
      setState(() => _preview = null);
    }
  }

  void _onTitleChanged(String _) {
    setState(() {
      _errorMessage = null;
      _errorRowIndex = null;
    });
    _updatePreview();
    _scheduleSave();
  }

  void _onSettlementChanged(SettlementType type) {
    setState(() {
      _settlementType = type;
      _errorMessage = null;
    });
    _updatePreview();
    _scheduleSave();
  }

  void _onBracketRateChanged(int rate) {
    setState(() {
      _bracketRate = rate;
      _errorMessage = null;
    });
    _updatePreview();
    _scheduleSave();
  }

  void _onRowChanged(int index, RowData row) {
    setState(() {
      _rows[index] = row;
      _errorMessage = null;
      _errorRowIndex = null;
    });
    _updatePreview();
    _scheduleSave();
  }

  void _addRow() {
    setState(() => _rows.add(_newRow()));
    _scheduleSave();
  }

  Future<void> _clearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear all entries?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _rows = [];
      _errorMessage = null;
      _errorRowIndex = null;
      _preview = null;
    });
    _scheduleSave();
  }

  Future<void> _newCalculation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start new calculation?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Start New'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await widget.storage.clear();
    widget.onNewCalculation();
  }

  void _calculate() {
    final validation = validateRows(_rows);
    if (!validation.isValid) {
      setState(() {
        _errorMessage = validation.errorMessage;
        _errorRowIndex = validation.rowIndex;
      });
      return;
    }
    try {
      final result = calculate(
        _rows,
        multiplier: _bracketRate,
        settlementType: _settlementType,
      );
      widget.onCalculate(
        _titleController.text,
        _rows,
        result,
        _settlementType,
        _bracketRate,
      );
    } catch (error) {
      setState(() {
        _errorMessage = error.toString();
        _errorRowIndex = null;
      });
    }
  }

  void _deleteRow(int index) {
    setState(() {
      _rows.removeAt(index);
      _errorMessage = null;
      _errorRowIndex = null;
    });
    _updatePreview();
    _scheduleSave();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.pagePadding,
            12,
            AppSpacing.pagePadding,
            24,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Header(
                    onSettingsTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Settings coming soon'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.sectionGap),
                  TitleInput(
                    controller: _titleController,
                    onChanged: _onTitleChanged,
                  ),
                  const SizedBox(height: AppSpacing.sectionGap),
                  SettlementRow(
                    value: _settlementType,
                    bracketRate: _bracketRate,
                    onSettlementChanged: _onSettlementChanged,
                    onRateChanged: _onBracketRateChanged,
                  ),
                  const SizedBox(height: AppSpacing.sectionGap),
                  if (_rows.isEmpty)
                    EmptyState(onAddRow: _addRow)
                  else ...[
                    RowTable(
                      rows: _rows,
                      onRowChanged: _onRowChanged,
                      onDeleteRow: _deleteRow,
                      onAddRow: _addRow,
                      errorRowIndex: _errorRowIndex,
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: AppColors.danger,
                          fontSize: 14,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    LivePreview(result: _preview),
                    if (_preview != null) ...[
                      const SizedBox(height: 12),
                      QuickSummaryStrip(result: _preview!),
                    ],
                  ],
                  const SizedBox(height: 20),
                  ActionButtons(
                    onClearAll: _clearAll,
                    onCalculate: _calculate,
                    onNewCalculation: _newCalculation,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
