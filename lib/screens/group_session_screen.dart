import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/entry_names.dart';
import '../core/calculate.dart';
import '../core/commission.dart';
import '../core/copy_message.dart';
import '../core/group_commission.dart';
import '../core/group_rows.dart';
import '../core/share_message.dart';
import '../core/smart_text_parser.dart';
import '../core/storage.dart';
import '../core/validate.dart';
import '../models/calculation_group.dart';
import '../models/calculation_result.dart';
import '../models/history_entry.dart';
import '../models/row_data.dart';
import '../theme/app_theme.dart';
import '../widgets/group_static_row_table.dart';
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

  @override
  State<GroupSessionScreen> createState() => _GroupSessionScreenState();
}

class _GroupSessionScreenState extends State<GroupSessionScreen> {
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
  String? _originalPastedText;
  String? _errorMessage;
  int? _errorRowIndex;

  @override
  void initState() {
    super.initState();
    _group = widget.group;
    _persistentHeaderController = TextEditingController();
    _load();
  }

  @override
  void dispose() {
    _saveDraft();
    _persistentHeaderController.dispose();
    super.dispose();
  }

  List<String> get _allowedEntryNames {
    final names = <String>{...widget.entryNames};
    for (final row in _rows) {
      final name = row.name.trim();
      if (name.isNotEmpty) names.add(name);
    }
    return names.toList();
  }

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
      _commissionTracking = widget.settings.defaultCommissionTracking;
      _loading = false;
      setState(() {});
      if (widget.autoCalculate) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _calculate());
      }
      return;
    }

    if (draft != null && draft.hasData) {
      _rows = restoreGroupRows(draft.rows, _group.id);
      _commissionTracking = draft.commissionTracking;
      _historyEntryId = draft.historyEntryId;
      _originalPastedText = draft.originalPastedText;
      _restoreResultFromDraft(draft);
    } else {
      _rows = defaultGroupRows(_group.id);
      _commissionTracking = widget.settings.defaultCommissionTracking;
    }

    await _refreshCommissionBalance();
    if (mounted) setState(() => _loading = false);
  }

  void _restoreResultFromDraft(DraftState draft) {
    final validation = validateRows(_rows, allowedNames: _allowedEntryNames);
    if (!validation.isValid) {
      _result = null;
      return;
    }
    try {
      _result = calculateSettlement(
        _rows,
        passingRate: _passingRate,
        amountDeductionRate: _amountDeductionRate,
        commissionTracking: _commissionTracking,
        storedCommissionBalance: _storedCommissionBalance,
      );
    } catch (_) {
      _result = null;
    }
  }

  Future<void> _refreshCommissionBalance() async {
    final balance = await widget.storage.getCommissionBalance(
      groupTitleCommissionOwnerId(_group.id, _title),
    );
    if (mounted) setState(() => _storedCommissionBalance = balance);
  }

  Future<void> _saveDraft({String lastView = 'main'}) async {
    final now = DateTime.now();
    final hasData = _rows.any(
      (row) =>
          row.amount.trim().isNotEmpty || row.bracket.trim().isNotEmpty,
    );

    if (hasData) {
      _historyEntryId ??= now.microsecondsSinceEpoch.toString();
    }

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

    if (hasData && _historyEntryId != null) {
      await _syncHistoryEntry(lastView: lastView, updatedAt: now);
    }

    await widget.storage.upsertGroup(
      _group.copyWith(updatedAt: now),
    );
    widget.onGroupUpdated?.call();
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

    final status = _result != null
        ? HistoryEntry.completedStatus
        : HistoryEntry.draftStatus;

    final entry = DraftState(
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
    ).toHistoryEntry(
      id: _historyEntryId!,
      status: status,
      savedAt: existing?.savedAt ?? now,
      updatedAt: now,
      commissionEarned: _result?.commissionEarned,
      commissionBalanceAtThatTime: _result?.commissionBalance,
      groupId: _group.id,
      originalPastedText: _originalPastedText,
    );

    await widget.storage.upsertHistoryEntry(entry);
  }

  Future<void> _applyCalculatedResult(CalculationResult result) async {
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
  }

  Future<void> _calculate() async {
    setState(() {
      _isCalculating = true;
      _errorMessage = null;
      _errorRowIndex = null;
    });

    final validation = validateRows(_rows, allowedNames: _allowedEntryNames);
    if (!validation.isValid) {
      setState(() {
        _isCalculating = false;
        _errorMessage = validation.errorMessage;
        _errorRowIndex = validation.rowIndex;
        _result = null;
      });
      return;
    }

    try {
      final result = calculateSettlement(
        _rows,
        passingRate: _passingRate,
        amountDeductionRate: _amountDeductionRate,
        commissionTracking: _commissionTracking,
        storedCommissionBalance: _storedCommissionBalance,
      );
      await _applyCalculatedResult(result);
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Calculation failed.';
          _result = null;
        });
      }
    } finally {
      if (mounted) setState(() => _isCalculating = false);
    }
  }

  String? get _copyMessage {
    if (_result == null) return null;
    return buildPasteCopyMessage(
      title: _title,
      rows: _rows,
      result: _result!,
      persistentHeader: _persistentHeaderController.text,
    );
  }

  Future<void> _copyResult() async {
    final message = _copyMessage;
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
    final message = _copyMessage;
    if (message == null) return;
    await shareOnlyCalculationMessage(message);
  }

  void _onRowChanged(int index, RowData row) {
    setState(() => _rows[index] = row);
    _saveDraft();
  }

  void _deleteRow(int index) {
    setState(() => _rows.removeAt(index));
    _saveDraft();
  }

  void _addRow() {
    final name = nextMissingFixedName(_rows);
    if (name == null) return;
    setState(() {
      _rows.add(
        RowData(
          id: '${_group.id}-$name-${DateTime.now().microsecondsSinceEpoch}',
          name: name,
        ),
      );
    });
    _saveDraft();
  }

  Future<void> _addCustomEntry() async {
    final controller = TextEditingController();
    final raw = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Custom Entry Name'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            hintText: 'e.g. Mk.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (raw == null) return;

    final name = formatCustomEntryName(raw);
    if (name.isEmpty) return;

    if (_rows.any((row) => row.name.trim() == name)) {
      if (!mounted) return;
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
      widget.onSettingsChanged(updatedSettings);
    }

    setState(() {
      _rows.add(
        RowData(
          id: '${_group.id}-custom-${DateTime.now().microsecondsSinceEpoch}',
          name: name,
        ),
      );
    });
    _saveDraft();
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      var target = newIndex;
      if (target > oldIndex) target -= 1;
      final row = _rows.removeAt(oldIndex);
      _rows.insert(target, row);
    });
    _saveDraft();
  }

  Future<void> _startFreshCalculation() async {
    await _saveDraft();
    await widget.storage.clearGroupDraft(_group.id);
    setState(() {
      _syncGroupMeta();
      _rows = defaultGroupRows(_group.id);
      _result = null;
      _historyEntryId = null;
      _originalPastedText = null;
      _errorMessage = null;
      _errorRowIndex = null;
      _commissionTracking = widget.settings.defaultCommissionTracking;
    });
    await _refreshCommissionBalance();
  }

  void _loadFromHistory(HistoryEntry entry) {
    setState(() {
      _syncGroupMeta();
      _rows = restoreGroupRows(entry.rows, _group.id);
      _commissionTracking = entry.commissionTracking;
      _historyEntryId = entry.id;
      _originalPastedText = entry.originalPastedText;
      _result = null;
      _errorMessage = null;
      _errorRowIndex = null;
    });
    _saveDraft();
    _refreshCommissionBalance();
    _calculate();
  }

  Future<void> _onHistoryEntryDeleted(String id) async {
    if (id != _historyEntryId) return;
    await widget.storage.clearGroupDraft(_group.id);
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
    });
    widget.onGroupUpdated?.call();
    if (_result != null) {
      await _calculate();
    } else {
      await _saveDraft();
    }
  }

  void _openGroupHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HistoryScreen(
          storage: widget.storage,
          groupIdFilter: _group.id,
          onEditEntry: (entry) {
            Navigator.pop(context);
            _loadFromHistory(entry);
          },
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
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'edit':
                  _editGroup();
                case 'history':
                  _openGroupHistory();
                case 'clear':
                  _clearDraft();
                case 'delete':
                  _deleteGroup();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'edit', child: Text('Edit')),
              PopupMenuItem(value: 'history', child: Text('View Group History')),
              PopupMenuItem(value: 'clear', child: Text('Clear Current Draft')),
              PopupMenuItem(
                value: 'delete',
                child: Text('Delete Group', style: TextStyle(color: AppColors.danger)),
              ),
            ],
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.pagePadding,
            12,
            AppSpacing.pagePadding,
            24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PersistentHeaderInput(
                controller: _persistentHeaderController,
                onChanged: (text) async {
                  await widget.storage.savePersistentHeader(text);
                },
              ),
              const SizedBox(height: AppSpacing.sectionGap),
              GroupStaticRowTable(
                rows: _rows,
                onRowChanged: _onRowChanged,
                onDeleteRow: _deleteRow,
                onAddRow: _addRow,
                onAddCustomEntry: _addCustomEntry,
                onReorder: _onReorder,
                errorRowIndex: _errorRowIndex,
                canAddRow: canAddRow,
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
              if (_result != null) ...[
                const SizedBox(height: 16),
                PasteResultSummary(result: _result!),
              ],
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _isCalculating ? null : _calculate,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  minimumSize: const Size.fromHeight(AppSpacing.buttonHeight),
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
                    : const Text('Calculate'),
              ),
              if (_copyMessage != null) ...[
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _copyResult,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(AppSpacing.buttonHeight),
                  ),
                  icon: const Icon(Icons.copy_outlined, size: 18),
                  label: const Text('Copy'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _shareResult,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(AppSpacing.buttonHeight),
                  ),
                  icon: const Icon(Icons.share_outlined, size: 18),
                  label: const Text('Share'),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
    );
  }
}
