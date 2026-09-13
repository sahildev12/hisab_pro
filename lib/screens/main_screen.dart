import 'dart:async';



import 'package:decimal/decimal.dart';

import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';



import '../core/calculate.dart';

import '../core/money.dart' show suggestedAmountDeduction;

import '../core/storage.dart';

import '../core/validate.dart';

import '../models/calculation_result.dart';

import '../models/history_entry.dart';

import '../models/row_data.dart';

import '../theme/app_theme.dart';

import '../widgets/action_buttons.dart';

import '../widgets/calculation_rates_control.dart';



import '../widgets/empty_state.dart';

import '../widgets/header.dart';
import '../widgets/hisab_pro_modal.dart';
import '../widgets/total_commission_modal.dart';


import '../widgets/persistent_header_input.dart';

import '../widgets/quick_summary_strip.dart';

import '../widgets/row_table.dart';

import '../widgets/title_input.dart';

import 'history_screen.dart';

import 'settings_screen.dart';



class MainScreen extends StatefulWidget {

  const MainScreen({

    super.key,

    required this.storage,

    required this.initialTitle,

    required this.initialPersistentHeader,

    required this.initialRows,

    required this.initialPassingRate,

    required this.initialAmountDeductionRate,

    required this.initialCommissionTracking,

    required this.storedCommissionBalance,

    required this.settings,

    required this.entryNames,

    required this.onDraftChanged,

    required this.onPersistentHeaderChanged,

    required this.onCalculate,

    required this.onNewCalculation,

    required this.onSettingsChanged,

    required this.onOpenHistoryEntry,

    this.onDeleteHistoryEntry,

  });



  final StorageService storage;

  final String initialTitle;

  final String initialPersistentHeader;

  final List<RowData> initialRows;

  final Decimal initialPassingRate;

  final Decimal initialAmountDeductionRate;

  final bool initialCommissionTracking;

  final Decimal storedCommissionBalance;

  final AppSettings settings;

  final List<String> entryNames;

  final void Function({

    required String title,

    required List<RowData> rows,

    required Decimal passingRate,

    required Decimal amountDeductionRate,

    required bool commissionTracking,

  }) onDraftChanged;

  final ValueChanged<String> onPersistentHeaderChanged;

  final void Function(

    String title,

    List<RowData> rows,

    CalculationResult result,

    Decimal passingRate,

    Decimal amountDeductionRate,

  ) onCalculate;

  final Future<void> Function() onNewCalculation;

  final ValueChanged<AppSettings> onSettingsChanged;

  final ValueChanged<HistoryEntry> onOpenHistoryEntry;

  final ValueChanged<String>? onDeleteHistoryEntry;



  @override

  State<MainScreen> createState() => _MainScreenState();

}



class _MainScreenState extends State<MainScreen> {

  late final TextEditingController _titleController;

  late final TextEditingController _persistentHeaderController;

  late List<RowData> _rows;

  late Decimal _passingRate;

  late Decimal _amountDeductionRate;

  late bool _commissionTracking;

  bool _deductionLinkedToPassing = true;

  String? _errorMessage;

  int? _errorRowIndex;

  Timer? _saveTimer;

  Timer? _headerSaveTimer;

  CalculationResult? _preview;

  String _saveStatus = '';



  bool get _hasRowData => _rows.any((row) => !isRowEmpty(row));



  @override

  void initState() {

    super.initState();

    _titleController = TextEditingController(text: widget.initialTitle);

    _persistentHeaderController = TextEditingController(

      text: widget.initialPersistentHeader,

    );

    _rows = List<RowData>.from(widget.initialRows);

    _passingRate = widget.initialPassingRate;

    _amountDeductionRate = widget.initialAmountDeductionRate;

    _commissionTracking = widget.initialCommissionTracking;

    _deductionLinkedToPassing = _amountDeductionRate ==

        suggestedAmountDeduction(_passingRate);

    _updatePreview();

  }



  @override

  void didUpdateWidget(MainScreen oldWidget) {

    super.didUpdateWidget(oldWidget);

    if (oldWidget.storedCommissionBalance != widget.storedCommissionBalance) {

      _updatePreview();

    }

  }



  @override

  void dispose() {

    _saveTimer?.cancel();

    _headerSaveTimer?.cancel();

    _titleController.dispose();

    _persistentHeaderController.dispose();

    super.dispose();

  }



  RowData _newRow() =>

      RowData.empty(id: DateTime.now().microsecondsSinceEpoch.toString());



  void _scheduleSave() {

    setState(() => _saveStatus = 'Saving…');

    _saveTimer?.cancel();

    _saveTimer = Timer(const Duration(milliseconds: 400), _persist);

  }



  void _scheduleHeaderSave() {

    _headerSaveTimer?.cancel();

    _headerSaveTimer = Timer(const Duration(milliseconds: 400), () {

      widget.onPersistentHeaderChanged(_persistentHeaderController.text);

    });

  }



  Future<void> _persist() async {

    await widget.storage.saveDraft(

      DraftState(

        title: _titleController.text,

        rows: _rows,

        passingRate: _passingRate,

        amountDeductionRate: _amountDeductionRate,

        commissionTracking: _commissionTracking,

        lastView: 'main',

      ),

    );

    widget.onDraftChanged(

      title: _titleController.text,

      rows: _rows,

      passingRate: _passingRate,

      amountDeductionRate: _amountDeductionRate,

      commissionTracking: _commissionTracking,

    );

    if (mounted) setState(() => _saveStatus = 'Saved');

  }



  void _updatePreview() {

    if (!_hasRowData) {

      if (_preview != null) setState(() => _preview = null);

      return;

    }

    final validation = validateRows(_rows, allowedNames: widget.entryNames);

    if (!validation.isValid) {

      if (_preview != null) setState(() => _preview = null);

      return;

    }

    try {

      final result = calculateSettlement(

        _rows,

        passingRate: _passingRate,

        amountDeductionRate: _amountDeductionRate,

        commissionTracking: _commissionTracking,

        storedCommissionBalance: widget.storedCommissionBalance,

      );

      if (mounted) setState(() => _preview = result);

    } catch (_) {

      if (_preview != null) setState(() => _preview = null);

    }

  }



  void _onTitleChanged(String _) {

    if (_errorMessage != null || _errorRowIndex != null) {

      setState(() {

        _errorMessage = null;

        _errorRowIndex = null;

      });

    }

    _updatePreview();

    _scheduleSave();

  }



  void _onPersistentHeaderChanged(String _) {

    _scheduleHeaderSave();

  }



  void _onRatesChanged(CalculationRates rates) {

    setState(() {

      _passingRate = rates.passingRate;

      _amountDeductionRate = rates.amountDeductionRate;

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

    final confirmed = await showHisabProConfirmDialog(
      context: context,
      title: 'Clear all entries?',
      message: 'This cannot be undone.',
      confirmLabel: 'Clear All',
      destructive: true,
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

    final hasData = _titleController.text.trim().isNotEmpty || _hasRowData;

    if (hasData) {

      final confirmed = await showHisabProConfirmDialog(
        context: context,
        title: 'Start New Calculation?',
        message: 'Your current draft will be saved to History.',
        confirmLabel: 'Start New',
      );

      if (confirmed != true || !mounted) return;

    }

    await widget.onNewCalculation();

  }



  void _onCommissionTrackingChanged(bool value) {

    setState(() => _commissionTracking = value);

    _updatePreview();

    _scheduleSave();

  }



  void _calculate() {

    final validation = validateRows(_rows, allowedNames: widget.entryNames);

    if (!validation.isValid) {

      setState(() {

        _errorMessage = validation.errorMessage;

        _errorRowIndex = validation.rowIndex;

      });

      return;

    }

    try {

      final result = calculateSettlement(

        _rows,

        passingRate: _passingRate,

        amountDeductionRate: _amountDeductionRate,

        commissionTracking: _commissionTracking,

        storedCommissionBalance: widget.storedCommissionBalance,

      );

      widget.onCalculate(

        _titleController.text,

        _rows,

        result,

        _passingRate,

        _amountDeductionRate,

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



  void _openSettings() {

    Navigator.push(

      context,

      MaterialPageRoute(

        builder: (context) => SettingsScreen(

          storage: widget.storage,

          settings: widget.settings,

          onSettingsChanged: widget.onSettingsChanged,

          onOpenHistoryEntry: widget.onOpenHistoryEntry,

          onDeleteHistoryEntry: widget.onDeleteHistoryEntry,

        ),

      ),

    );

  }



  Future<void> _openTotalCommission() async {
    await showTotalCommissionModal(
      context: context,
      storage: widget.storage,
    );
  }

  void _openHistory() {

    Navigator.push(

      context,

      MaterialPageRoute(

        builder: (context) => HistoryScreen(

          storage: widget.storage,

          onEditEntry: widget.onOpenHistoryEntry,

          onDeleteEntry: widget.onDeleteHistoryEntry,

        ),

      ),

    );

  }



  @override

  Widget build(BuildContext context) {

    return Scaffold(

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

                    onSettingsTap: _openSettings,

                    onHistoryTap: _openHistory,

                    onCommissionTap: _openTotalCommission,

                  ),

                  if (_saveStatus.isNotEmpty) ...[

                    const SizedBox(height: 6),

                    Align(

                      alignment: Alignment.centerRight,

                      child: Text(

                        _saveStatus,

                        style: GoogleFonts.inter(

                          fontSize: 11,

                          color: AppColors.slate,

                        ),

                      ),

                    ),

                  ],

                  const SizedBox(height: AppSpacing.sectionGap),

                  PersistentHeaderInput(

                    controller: _persistentHeaderController,

                    onChanged: _onPersistentHeaderChanged,

                  ),

                  const SizedBox(height: AppSpacing.sectionGap),

                  TitleInput(

                    controller: _titleController,

                    onChanged: _onTitleChanged,

                  ),

                  const SizedBox(height: AppSpacing.sectionGap),

                  CalculationRatesControl(

                    rates: CalculationRates(

                      passingRate: _passingRate,

                      amountDeductionRate: _amountDeductionRate,

                    ),

                    deductionLinkedToPassing: _deductionLinkedToPassing,

                    onDeductionLinkChanged: (linked) {

                      setState(() => _deductionLinkedToPassing = linked);

                    },

                    onRatesChanged: _onRatesChanged,

                    commissionTracking: _commissionTracking,

                    onCommissionTrackingChanged: _onCommissionTrackingChanged,

                  ),

                  const SizedBox(height: AppSpacing.sectionGap),

                  if (_rows.isEmpty)

                    EmptyState(onAddRow: _addRow)

                  else ...[

                    RowTable(

                      rows: _rows,

                      entryNames: widget.entryNames,

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

                  ],

                  if (_rows.isNotEmpty) ...[

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


