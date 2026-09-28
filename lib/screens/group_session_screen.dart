import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/entry_names.dart';
import '../constants/fixed_names.dart';
import '../core/calculate.dart';
import '../core/commission.dart';
import '../core/copy_message.dart';
import '../core/custom_entry_usage.dart';
import '../core/group_commission.dart';
import '../core/group_rows.dart';
import '../core/share_message.dart';
import '../core/smart_text_parser.dart';
import '../core/storage.dart';
import '../models/calculation_group.dart';
import '../models/calculation_result.dart';
import '../models/history_entry.dart';
import '../models/row_data.dart';
import '../theme/app_theme.dart';
import '../widgets/commission_balance_card.dart';
import '../widgets/group_static_row_table.dart';
import '../widgets/hisab_page_header.dart';
import '../widgets/hisab_pro_modal.dart';
import '../widgets/paste_result_summary.dart';
import '../widgets/persistent_header_input.dart';
import 'create_group_screen.dart';
import 'history_screen.dart';

class GroupSessionScreen extends StatefulWidget {
  const GroupSessionScreen({
    super.key,
    required this.storage,
    required this.settings,
    required this.group,
    required this.entryNames,
    required this.onSettingsChanged,
    this.onGroupUpdated,
    this.initialParsed,
    this.originalPastedText,
    this.autoCalculate = false,
    this.initialHistoryEntry,
  });

  final StorageService storage;
  final AppSettings settings;
  final CalculationGroup group;
  final List<String> entryNames;
  final ValueChanged<AppSettings> onSettingsChanged;
  final VoidCallback? onGroupUpdated;
  final SmartParseResult? initialParsed;
  final String? originalPastedText;
  final bool autoCalculate;
  final HistoryEntry? initialHistoryEntry;

  @override
  State<GroupSessionScreen> createState() => _GroupSessionScreenState();
}

class _GroupSessionScreenState extends State<GroupSessionScreen>
    with WidgetsBindingObserver {
  late CalculationGroup _group;
  late final TextEditingController _persistentHeaderController;

  bool _loading = true;
  bool _isCalculating = false;

  String _title = '';
  List<RowData> _rows = [];
  CalculationResult? _result;
  Decimal _passingRate = defaultPassingRate;
  Decimal _amountDeductionRate = defaultAmountDeductionRate;
  bool _commissionTracking = false;
  Decimal _storedCommissionBalance = Decimal.zero;
  String? _historyEntryId;
  String? _lastSavedHistoryEntryId;
  String? _editingHistoryEntryId;
  String? _originalPastedText;
  String? _errorMessage;
  int? _errorRowIndex;

  List<List<RowData>> _undoStack = [];
  List<List<RowData>> _redoStack = [];
  Timer? _undoPersistTimer;
  Timer? _draftSaveTimer;
  final _customEntryUsage = CustomEntryUsageService();

  /// True when rows changed since the last saved calculation, so the next
  /// calculation is recorded as a new history entry instead of overwriting.
  bool _changedSinceCalculation = false;

  bool get _commissionEnabled => _group.commissionEnabled;

  bool get _defaultCommissionTracking => _commissionEnabled;

  bool get _canUndo => _undoStack.isNotEmpty;

  bool get _canRedo => _redoStack.isNotEmpty;

  bool get _isUpdatingHistory => _editingHistoryEntryId != null;

  bool get _hasCalculationInput => _rows.any(
        (row) =>
            row.amount.trim().isNotEmpty || row.bracket.trim().isNotEmpty,
      );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _group = widget.group;
    _persistentHeaderController = TextEditingController();
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _undoPersistTimer?.cancel();
    _draftSaveTimer?.cancel();
    _saveDraft();
    _persistUndoHistory();
    _persistentHeaderController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _draftSaveTimer?.cancel();
      _undoPersistTimer?.cancel();
      _saveDraft();
      _persistUndoHistory();
    }
  }

  List<RowData> _cloneRows(List<RowData> rows) =>
      rows.map((row) => row.copyWith()).toList();

  Future<void> _persistUndoHistory() async {
    try {
      await widget.storage.saveGroupUndoHistory(
        _group.id,
        undo: _undoStack,
        redo: _redoStack,
      );
    } catch (_) {
      // Undo history is a convenience; losing it must not break editing.
    }
  }

  /// Writing the whole undo history is comparatively expensive, so it is
  /// batched instead of running on every keystroke.
  void _scheduleUndoPersist() {
    _undoPersistTimer?.cancel();
    _undoPersistTimer = Timer(
      const Duration(milliseconds: 700),
      _persistUndoHistory,
    );
  }

  /// Records the current rows as one undo step.
  ///
  /// Every edit gets its own step, so undo walks back a single digit at a time
  /// rather than clearing a whole number.
  void _pushUndoSnapshot() {
    _undoStack.add(_cloneRows(_rows));
    if (_undoStack.length > undoHistoryLimit) {
      _undoStack.removeAt(0);
    }
    _redoStack.clear();
    _scheduleUndoPersist();
  }

  void _clearUndoHistory() {
    _undoStack = [];
    _redoStack = [];
    _scheduleUndoPersist();
  }

  void _undo() {
    if (_undoStack.isEmpty) return;
    final previous = _undoStack.removeLast();
    _redoStack.add(_cloneRows(_rows));
    if (_redoStack.length > undoHistoryLimit) {
      _redoStack.removeAt(0);
    }
    _scheduleUndoPersist();
    _applyRestoredRows(previous);
  }

  void _redo() {
    if (_redoStack.isEmpty) return;
    final next = _redoStack.removeLast();
    _undoStack.add(_cloneRows(_rows));
    if (_undoStack.length > undoHistoryLimit) {
      _undoStack.removeAt(0);
    }
    _scheduleUndoPersist();
    _applyRestoredRows(next);
  }

  void _applyRestoredRows(List<RowData> rows) {
    setState(() {
      _rows = rows;
      _errorMessage = null;
      _errorRowIndex = null;
      _markRowsChanged();
    });
    _updateLiveResult();
    _saveDraft();
  }

  /// Marks the rows as edited since the last calculation.
  ///
  /// The previous calculation is already stored in history, so the next one
  /// must start a new record instead of rewriting it.
  void _markRowsChanged() {
    if (_changedSinceCalculation) return;
    if (_editingHistoryEntryId == null) {
      _historyEntryId = null;
    } else {
      _historyEntryId = _editingHistoryEntryId;
    }
    _changedSinceCalculation = true;
  }

  /// True when the saved draft carries user work worth restoring.
  bool _draftHasWork(DraftState draft) {
    if (draft.rows.isEmpty) return false;
    if (draft.lastView == 'results') return true;

    final hasTypedData = draft.rows.any(
      (row) =>
          row.amount.trim().isNotEmpty || row.bracket.trim().isNotEmpty,
    );
    if (hasTypedData) return true;

    final defaultNames = fixedNames.toSet();
    if (draft.rows.length != fixedNames.length) return true;
    if (draft.rows.any((row) => !defaultNames.contains(row.name.trim()))) {
      return true;
    }

    final draftNames = draft.rows.map((row) => row.name.trim()).toList();
    return !listEquals(draftNames, fixedNames);
  }

  /// Rates always come from the group definition; they are not editable here.
  void _syncGroupMeta() {
    _title = _group.name;
    _passingRate = _group.passingRate;
    _amountDeductionRate = _group.amountDeductionRate;
  }

  Future<void> _load() async {
    final header = await widget.storage.loadPersistentHeader();
    _persistentHeaderController.text = header;

    final draft = await widget.storage.loadGroupDraft(
      _group.id,
      fallbackPassingRate: _group.passingRate,
      fallbackAmountDeductionRate: _group.amountDeductionRate,
    );

    _syncGroupMeta();

    if (widget.initialHistoryEntry != null) {
      final entry = widget.initialHistoryEntry!;
      _rows = restoreGroupRows(entry.rows, _group.id);
      _passingRate = entry.passingRate;
      _amountDeductionRate = entry.amountDeductionRate;
      _commissionTracking =
          _commissionEnabled ? entry.commissionTracking : false;
      _historyEntryId = entry.id;
      _editingHistoryEntryId = entry.id;
      _originalPastedText = entry.originalPastedText;
      _changedSinceCalculation = false;
      await widget.storage.clearGroupUndoHistory(_group.id);
      await _refreshCommissionBalance();
      if (mounted) {
        setState(() => _loading = false);
        _updateLiveResult();
      }
      return;
    }

    if (widget.initialParsed != null) {
      final parsed = widget.initialParsed!;
      final rates = SmartTextParser.resolveRates(
        parsed: parsed,
        groupPassingRate: _group.passingRate,
        groupDeductionRate: _group.amountDeductionRate,
      );
      _rows = restoreGroupRows(parsed.rows, _group.id);
      _passingRate = rates.passingRate;
      _amountDeductionRate = rates.amountDeductionRate;
      _originalPastedText =
          widget.originalPastedText ?? parsed.originalText;
      _commissionTracking = _defaultCommissionTracking;
      _changedSinceCalculation = true;
      await _refreshCommissionBalance();
      if (mounted) {
        setState(() => _loading = false);
        if (widget.autoCalculate) _updateLiveResult();
      }
      return;
    }

    if (draft != null && _draftHasWork(draft)) {
      _rows = restoreGroupRows(draft.rows, _group.id);
      _commissionTracking =
          _commissionEnabled ? draft.commissionTracking : false;
      _historyEntryId = draft.historyEntryId;
      _editingHistoryEntryId = draft.historyEntryId;
      _originalPastedText = draft.originalPastedText;
      _changedSinceCalculation = draft.historyEntryId == null;

      // Undo and redo steps are stored with the draft so they survive leaving
      // the group and coming back.
      final undoHistory = await widget.storage.loadGroupUndoHistory(_group.id);
      _undoStack = undoHistory.undo;
      _redoStack = undoHistory.redo;
    } else {
      _rows = defaultGroupRows(_group.id);
      _commissionTracking = _defaultCommissionTracking;
      await widget.storage.clearGroupUndoHistory(_group.id);
    }

    await _refreshCommissionBalance();
    if (mounted) {
      setState(() => _loading = false);
      _updateLiveResult();
    }
  }

  Future<void> _refreshCommissionBalance() async {
    final balance = await widget.storage.getCommissionBalance(
      groupTitleCommissionOwnerId(_group.id, _title),
    );
    if (mounted) setState(() => _storedCommissionBalance = balance);
  }

  void _scheduleDraftSave({String lastView = 'main'}) {
    _draftSaveTimer?.cancel();
    _draftSaveTimer = Timer(
      const Duration(milliseconds: 400),
      () => _saveDraft(lastView: lastView),
    );
  }

  /// Persists the in-progress work. History is deliberately untouched here:
  /// records are only written when Calculate runs.
  Future<void> _saveDraft({String lastView = 'main'}) async {
    try {
      final now = DateTime.now();

      await widget.storage.saveGroupDraft(
        _group.id,
        DraftState(
          title: _title,
          rows: _rows,
          passingRate: _passingRate,
          amountDeductionRate: _amountDeductionRate,
          commissionTracking: _commissionTracking,
          lastView: lastView,
          historyEntryId: _historyEntryId,
          updatedAt: now,
          groupId: _group.id,
          originalPastedText: _originalPastedText,
        ),
      );

      await widget.storage.upsertGroup(
        _group.copyWith(updatedAt: now),
      );
      widget.onGroupUpdated?.call();
    } catch (_) {
      // Avoid crashing the UI if persistence fails while editing.
    }
  }

  /// Rows that actually carry a number. Entries left untouched are not worth
  /// recording, so they never reach history.
  List<RowData> _filledRows() {
    return _rows
        .where(
          (row) =>
              row.amount.trim().isNotEmpty || row.bracket.trim().isNotEmpty,
        )
        .map((row) => row.copyWith())
        .toList();
  }

  Future<void> _syncHistoryEntry({
    String lastView = 'main',
    DateTime? updatedAt,
  }) async {
    if (_historyEntryId == null) return;
    final now = updatedAt ?? DateTime.now();
    final history = await widget.storage.loadHistory();
    HistoryEntry? existing;
    for (final entry in history) {
      if (entry.id == _historyEntryId) {
        existing = entry;
        break;
      }
    }

    final entry = DraftState(
      title: _title,
      rows: _filledRows(),
      passingRate: _passingRate,
      amountDeductionRate: _amountDeductionRate,
      commissionTracking: _commissionTracking,
      lastView: lastView,
      historyEntryId: _historyEntryId,
      updatedAt: now,
      groupId: _group.id,
      originalPastedText: _originalPastedText,
    ).toHistoryEntry(
      id: _historyEntryId!,
      // Writing history only happens on Calculate, and that makes the record
      // final. Untouched entries are dropped rather than marking it a draft.
      status: HistoryEntry.completedStatus,
      savedAt: existing?.savedAt ?? now,
      updatedAt: now,
      commissionEarned: _result?.commissionEarned,
      commissionBalanceAtThatTime: _result?.commissionBalance,
      groupId: _group.id,
      originalPastedText: _originalPastedText,
    );

    await widget.storage.upsertHistoryEntry(entry);
  }

  CalculationResult? _computePreview() {
    if (!_hasCalculationInput) return null;
    try {
      return calculateSettlement(
        _rows,
        passingRate: _passingRate,
        amountDeductionRate: _amountDeductionRate,
        commissionTracking: _commissionTracking,
        storedCommissionBalance: _storedCommissionBalance,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _applyFinalizedResult(CalculationResult result) async {
    if (_editingHistoryEntryId != null) {
      _historyEntryId = _editingHistoryEntryId;
    }
    _historyEntryId ??= DateTime.now().microsecondsSinceEpoch.toString();

    final history = await widget.storage.loadHistory();
    HistoryEntry? existing;
    for (final entry in history) {
      if (entry.id == _historyEntryId) {
        existing = entry;
        break;
      }
    }

    var finalResult = result;
    if (result.commissionTracking) {
      final ownerId = groupTitleCommissionOwnerId(_group.id, _title);
      final stored = await widget.storage.getCommissionBalance(ownerId);
      final oldEarned = existing?.commissionEarned ?? Decimal.zero;
      final newBalance = adjustCommissionBalance(
        currentBalance: stored,
        previousEarned: oldEarned,
        newEarned: result.commissionEarned,
      );
      await widget.storage.setCommissionBalance(ownerId, newBalance);
      finalResult = result.copyWith(
        commissionBalance: newBalance,
        storedCommissionBalance: newBalance - result.commissionEarned,
      );
      _storedCommissionBalance = newBalance;
    }

    setState(() {
      _result = finalResult;
      _commissionTracking = finalResult.commissionTracking;
      _errorMessage = null;
      _errorRowIndex = null;
    });

    await _saveDraft(lastView: 'results');

    // Calculate is the only thing that writes history. The id stays put so a
    // repeat calculation updates this record, while the next edit clears it and
    // starts a new one.
    await _syncHistoryEntry(lastView: 'results');
    if (!mounted) return;
    setState(() {
      _lastSavedHistoryEntryId = _historyEntryId;
      _changedSinceCalculation = false;
    });
  }

  /// Recomputes the on-screen totals whenever row data changes.
  void _updateLiveResult() {
    if (!mounted) return;
    setState(() {
      _result = _computePreview();
      if (_result != null) {
        _errorMessage = null;
        _errorRowIndex = null;
      }
    });
  }

  /// Saves the current calculation to history and commission balances.
  Future<void> _finalizeCalculation() async {
    if (!_hasCalculationInput) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter at least one amount or bracket first.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isCalculating = true;
      _errorMessage = null;
      _errorRowIndex = null;
    });

    try {
      final result = _computePreview();
      if (result == null) {
        if (mounted) {
          setState(() {
            _errorMessage = 'Calculation failed.';
            _result = null;
          });
        }
        return;
      }
      await _applyFinalizedResult(result);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Calculation finalized'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(milliseconds: 1800),
        ),
      );
    } finally {
      if (mounted) setState(() => _isCalculating = false);
    }
  }

  String? _buildCopyMessageSafe() {
    if (_result == null) return null;
    try {
      return buildPasteCopyMessage(
        title: _title,
        rows: _rows,
        result: _result!,
        persistentHeader: _persistentHeaderController.text,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _copyResult() async {
    final message = _buildCopyMessageSafe();
    if (message == null) return;
    await copyCalculationMessage(message);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(milliseconds: 1800),
      ),
    );
  }

  Future<void> _shareResult() async {
    final message = _buildCopyMessageSafe();
    if (message == null) return;
    await shareOnlyCalculationMessage(message);
  }

  Future<void> _clearCommission() async {
    final confirmed = await showHisabProConfirmDialog(
      context: context,
      title: 'Clear commission balance?',
      message: 'This resets the saved commission balance for this group.',
      confirmLabel: 'Clear',
      destructive: true,
    );
    if (confirmed != true || !mounted) return;

    final ownerId = groupTitleCommissionOwnerId(_group.id, _title);
    await widget.storage.setCommissionBalance(ownerId, Decimal.zero);
    setState(() => _storedCommissionBalance = Decimal.zero);
    _updateLiveResult();
  }

  void _onRowChanged(int index, RowData row) {
    var targetIndex = index;
    if (targetIndex < 0 ||
        targetIndex >= _rows.length ||
        _rows[targetIndex].id != row.id) {
      targetIndex = _rows.indexWhere((entry) => entry.id == row.id);
    }
    if (targetIndex < 0) return;
    _pushUndoSnapshot();
    _rows[targetIndex] = row;
    _errorMessage = null;
    _errorRowIndex = null;
    _markRowsChanged();
    _updateLiveResult();
    _scheduleDraftSave();
  }

  Future<void> _deleteRowById(String rowId) async {
    final index = _rows.indexWhere((row) => row.id == rowId);
    if (index < 0) return;
    await _deleteRow(index);
  }

  Future<void> _deleteRow(int index) async {
    if (index < 0 || index >= _rows.length) return;
    final row = _rows[index];
    final rowId = row.id;
    final name = row.name.trim().isEmpty ? 'this entry' : row.name.trim();

    final confirmed = await showHisabProConfirmDialog(
      context: context,
      title: 'Delete entry?',
      message: 'Are you sure you want to delete $name?',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (confirmed != true || !mounted) return;

    final deleteIndex = _rows.indexWhere((entry) => entry.id == rowId);
    if (deleteIndex < 0) return;

    _pushUndoSnapshot();
    setState(() {
      _rows.removeAt(deleteIndex);
      if (_rows.isEmpty) {
        _rows = defaultGroupRows(_group.id);
      }
      _errorMessage = null;
      _errorRowIndex = null;
      _markRowsChanged();
    });
    _updateLiveResult();
    await _saveDraft();
  }

  void _moveRow(int fromIndex, int toIndex) {
    if (fromIndex == toIndex) return;
    if (fromIndex < 0 ||
        toIndex < 0 ||
        fromIndex >= _rows.length ||
        toIndex >= _rows.length) {
      return;
    }
    _pushUndoSnapshot();
    setState(() {
      final row = _rows.removeAt(fromIndex);
      _rows.insert(toIndex, row);
      _errorMessage = null;
      _errorRowIndex = null;
      _markRowsChanged();
    });
    _scheduleDraftSave();
  }

  void _moveRowById(String rowId, int direction) {
    final index = _rows.indexWhere((row) => row.id == rowId);
    if (index < 0) return;
    _moveRow(index, index + direction);
  }

  Future<void> _resetDigits() async {
    final hasDigits = _rows.any(
      (row) =>
          row.amount.trim().isNotEmpty || row.bracket.trim().isNotEmpty,
    );
    if (!hasDigits) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No amounts or brackets to clear.'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(milliseconds: 1800),
        ),
      );
      return;
    }

    _pushUndoSnapshot();
    setState(() {
      _rows = _rows
          .map((row) => row.copyWith(amount: '', bracket: ''))
          .toList();
      _errorMessage = null;
      _errorRowIndex = null;
      _markRowsChanged();
    });
    _updateLiveResult();
    await _saveDraft();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Amounts and brackets cleared.'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(milliseconds: 1800),
      ),
    );
  }

  void _addRow() {
    final name = nextMissingFixedName(_rows);
    if (name == null) return;
    _pushUndoSnapshot();
    setState(() {
      _rows.add(
        RowData(
          id: '${_group.id}-$name-${DateTime.now().microsecondsSinceEpoch}',
          name: name,
        ),
      );
      _errorMessage = null;
      _errorRowIndex = null;
      _markRowsChanged();
    });
    _scheduleDraftSave();
  }

  Future<List<String>> _recentCustomEntryNames() async {
    final used = await _customEntryUsage.getMostUsedNames(limit: 6);
    if (used.isNotEmpty) return used;

    final saved = widget.settings.customEntryNames;
    if (saved.isNotEmpty) {
      return saved.reversed.take(6).toList().reversed.toList();
    }

    return defaultCustomEntrySuggestions;
  }

  Future<void> _addCustomEntry() async {
    final recentOptions = await _recentCustomEntryNames();
    if (!mounted) return;

    final raw = await showHisabProPromptDialog(
      context: context,
      title: 'Custom Entry Name',
      hintText: 'e.g. Mk.',
      confirmLabel: 'Add',
      recentOptions: recentOptions,
    );
    if (raw == null || !mounted) return;

    final name = formatCustomEntryName(raw);
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a name.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_rows.any((row) => row.name.trim() == name)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This entry name is already in the list.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (!isStaticEntryName(name) &&
        !widget.settings.customEntryNames.contains(name)) {
      final updatedSettings = widget.settings.copyWith(
        customEntryNames: [...widget.settings.customEntryNames, name],
      );
      await widget.storage.saveSettings(updatedSettings);
      if (!mounted) return;
      widget.onSettingsChanged(updatedSettings);
    }

    await _customEntryUsage.recordUsage(name);

    _pushUndoSnapshot();
    setState(() {
      _rows.add(
        RowData(
          id: '${_group.id}-custom-${DateTime.now().microsecondsSinceEpoch}',
          name: name,
        ),
      );
      _errorMessage = null;
      _errorRowIndex = null;
      _markRowsChanged();
    });
    await _saveDraft();
  }

  void _openSessionMenu(BuildContext menuContext) {
    showHisabHeaderMenu(
      context: context,
      position: hisabMenuPosition(menuContext),
      items: [
        HisabMenuItem(
          value: 'edit',
          label: 'Edit',
          icon: Icons.edit_outlined,
          onTap: _editGroup,
        ),
        HisabMenuItem(
          value: 'history',
          label: 'View Group History',
          icon: Icons.history_rounded,
          onTap: _openGroupHistory,
        ),
        HisabMenuItem(
          value: 'clear',
          label: 'Clear Current Draft',
          icon: Icons.cleaning_services_outlined,
          onTap: _clearDraft,
        ),
        HisabMenuItem(
          value: 'delete',
          label: 'Delete Group',
          icon: Icons.delete_outline_rounded,
          onTap: _deleteGroup,
          destructive: true,
        ),
      ],
    );
  }

  Future<void> _startFreshCalculation() async {
    await widget.storage.clearGroupDraft(_group.id);
    setState(() {
      _syncGroupMeta();
      _rows = defaultGroupRows(_group.id);
      _result = null;
      _historyEntryId = null;
      _editingHistoryEntryId = null;
      _lastSavedHistoryEntryId = null;
      _originalPastedText = null;
      _errorMessage = null;
      _errorRowIndex = null;
      _changedSinceCalculation = false;
      _commissionTracking = _commissionEnabled
          ? widget.settings.defaultCommissionTracking
          : false;
      _clearUndoHistory();
    });
    await _refreshCommissionBalance();
  }

  void _loadFromHistory(HistoryEntry entry) {
    setState(() {
      _syncGroupMeta();
      _passingRate = entry.passingRate;
      _amountDeductionRate = entry.amountDeductionRate;
      _rows = restoreGroupRows(entry.rows, _group.id);
      _commissionTracking =
          _commissionEnabled ? entry.commissionTracking : false;
      _historyEntryId = entry.id;
      _editingHistoryEntryId = entry.id;
      _lastSavedHistoryEntryId = null;
      _originalPastedText = entry.originalPastedText;
      _result = null;
      _errorMessage = null;
      _errorRowIndex = null;
      _changedSinceCalculation = false;
      _clearUndoHistory();
    });
    _saveDraft();
    _refreshCommissionBalance().then((_) {
      if (mounted) _updateLiveResult();
    });
  }

  Future<void> _onHistoryEntryDeleted(String id) async {
    if (id != _historyEntryId && id != _lastSavedHistoryEntryId) return;
    await widget.storage.clearGroupDraft(_group.id);
    await _startFreshCalculation();
  }

  Future<void> _resetSession() async {
    final confirmed = await showHisabProConfirmDialog(
      context: context,
      title: 'Reset all entries?',
      message:
          'This clears the current session and starts fresh. Saved history is kept.',
      confirmLabel: 'Reset All',
      destructive: true,
    );
    if (confirmed != true) return;
    await _startFreshCalculation();
  }

  Future<void> _clearDraft() async {
    final confirmed = await showHisabProConfirmDialog(
      context: context,
      title: 'Clear current draft?',
      message: 'This will remove unsaved rows in this group.',
      confirmLabel: 'Clear',
      destructive: true,
    );
    if (confirmed != true) return;
    await _startFreshCalculation();
  }

  Future<void> _deleteGroup() async {
    final confirmed = await showHisabProConfirmDialog(
      context: context,
      title: 'Delete Group?',
      message:
          'This will remove the group and its calculations from this device.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (confirmed != true || !mounted) return;
    await widget.storage.deleteGroup(_group.id);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _editGroup() async {
    final updated = await Navigator.push<CalculationGroup>(
      context,
      MaterialPageRoute(
        builder: (context) => CreateGroupScreen(
          storage: widget.storage,
          settings: widget.settings,
          initialGroup: _group,
        ),
      ),
    );
    if (updated == null) return;
    setState(() {
      _group = updated;
      _syncGroupMeta();
      if (!_commissionEnabled) {
        _commissionTracking = false;
      }
    });
    widget.onGroupUpdated?.call();
    _updateLiveResult();
    await _saveDraft();
  }

  void _openGroupHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HistoryScreen(
          storage: widget.storage,
          groupIdFilter: _group.id,
          onEditEntry: _loadFromHistory,
          onDeleteEntry: _onHistoryEntryDeleted,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final canAddRow = nextMissingFixedName(_rows) != null;
    final copyMessage = _buildCopyMessageSafe();

    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) _saveDraft();
      },
      child: Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.primaryText,
        elevation: 0,
        title: Text(_group.name),
        actions: [
          IconButton(
            onPressed: _canUndo ? _undo : null,
            icon: const Icon(Icons.undo_rounded),
            tooltip: 'Undo',
          ),
          IconButton(
            onPressed: _canRedo ? _redo : null,
            icon: const Icon(Icons.redo_rounded),
            tooltip: 'Redo',
          ),
          Builder(
            builder: (menuContext) {
              return IconButton(
                onPressed: () => _openSessionMenu(menuContext),
                icon: const Icon(Icons.more_vert_rounded),
                tooltip: 'More options',
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(36),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              '${_passingRate.toStringAsFixed(0)}% Passing • ${_amountDeductionRate.toStringAsFixed(0)}% Deduction',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.primaryBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pagePadding,
                12,
                AppSpacing.pagePadding,
                0,
              ),
              sliver: SliverToBoxAdapter(
                child: PersistentHeaderInput(
                  controller: _persistentHeaderController,
                  onChanged: (text) async {
                    await widget.storage.savePersistentHeader(text);
                  },
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pagePadding,
                AppSpacing.sectionGap,
                AppSpacing.pagePadding,
                0,
              ),
              sliver: SliverToBoxAdapter(
                child: Container(
                  width: double.infinity,
                  decoration: surfaceDecoration(context),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                        child: GroupEntriesHeader(
                          rows: _rows,
                          onReset: _resetSession,
                          onResetDigits: _resetDigits,
                        ),
                      ),
                      ...List.generate(_rows.length, (index) {
                        final row = _rows[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: GroupEntryRow(
                            key: ValueKey(row.id),
                            row: row,
                            hasError: _errorRowIndex == index,
                            onChanged: (updated) =>
                                _onRowChanged(index, updated),
                            onDelete: () => _deleteRowById(row.id),
                            onMoveUp: index > 0
                                ? () => _moveRowById(row.id, -1)
                                : null,
                            onMoveDown: index < _rows.length - 1
                                ? () => _moveRowById(row.id, 1)
                                : null,
                          ),
                        );
                      }),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                        child: GroupEntriesFooter(
                          onAddRow: _addRow,
                          onAddCustomEntry: () => _addCustomEntry(),
                          canAddRow: canAddRow,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pagePadding,
                0,
                AppSpacing.pagePadding,
                24,
              ),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
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
                    if (_result != null) ...[
                      const SizedBox(height: 16),
                      PasteResultSummary(result: _result!),
                      if (_commissionEnabled &&
                          _result!.showsCommissionInfo) ...[
                        const SizedBox(height: 12),
                        CommissionBalanceCard(
                          result: _result!,
                          onClear: _result!.commissionTracking
                              ? _clearCommission
                              : null,
                        ),
                      ],
                    ],
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _isCalculating ? null : _finalizeCalculation,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        minimumSize:
                            const Size.fromHeight(AppSpacing.buttonHeight),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isCalculating
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _isUpdatingHistory
                                  ? 'Update data'
                                  : 'Final & Done',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                    if (copyMessage != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _copyResult,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primaryBlue,
                                backgroundColor: AppColors.surface,
                                side: const BorderSide(color: AppColors.border),
                                minimumSize: const Size.fromHeight(
                                  AppSpacing.buttonHeight,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(Icons.copy_outlined, size: 18),
                              label: const Text('Copy'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _shareResult,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primaryBlue,
                                backgroundColor: AppColors.surface,
                                side: const BorderSide(color: AppColors.border),
                                minimumSize: const Size.fromHeight(
                                  AppSpacing.buttonHeight,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(Icons.share_outlined, size: 18),
                              label: const Text('Share'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }
}
