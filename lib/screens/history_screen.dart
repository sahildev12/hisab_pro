import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/copy_message.dart';
import '../core/format.dart';
import '../core/history_helpers.dart';
import '../core/share_message.dart';
import '../core/storage.dart';
import '../models/history_entry.dart';
import '../models/result_type.dart';
import '../widgets/hisab_pro_modal.dart';
import 'history_detail_screen.dart';

class _HistoryColors {
  static const background = Color(0xFFF7F9FC);
  static const navy = Color(0xFF17365D);
  static const border = Color(0xFFE2E8F0);
  static const divider = Color(0xFFE8EDF3);
  static const muted = Color(0xFF64748B);
  static const primary = Color(0xFF2563EB);
  static const chipInactiveBg = Color(0xFFF1F5F9);
  static const chipInactiveBorder = Color(0xFFDCE4EE);
  static const actionBg = Color(0xFFEFF6FF);
  static const rowBadgeBg = Color(0xFFF8FAFC);
  static const lene = Color(0xFF15803D);
  static const leneBg = Color(0xFFDCFCE7);
  static const leneIconBg = Color(0xFFECFDF3);
  static const leneIcon = Color(0xFF16A34A);
  static const dene = Color(0xFFDC2626);
  static const deneBg = Color(0xFFFEE2E2);
  static const deneIconBg = Color(0xFFFEF2F2);
  static const draft = Color(0xFF64748B);
  static const draftBg = Color(0xFFF1F5F9);
  static const draftIconBg = Color(0xFFEFF6FF);
  static const draftIcon = Color(0xFF2563EB);
  static const balanced = Color(0xFF2563EB);
  static const balancedBg = Color(0xFFEFF6FF);
}

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({
    super.key,
    required this.storage,
    required this.onEditEntry,
    this.onDeleteEntry,
    this.onStartNewCalculation,
    this.groupIdFilter,
  });

  final StorageService storage;
  final ValueChanged<HistoryEntry> onEditEntry;
  final ValueChanged<String>? onDeleteEntry;
  final VoidCallback? onStartNewCalculation;
  final String? groupIdFilter;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  static const _pagePadding = 16.0;

  List<HistoryDisplayItem> _allItems = [];
  bool _loading = true;
  bool _searchOpen = false;
  final _searchController = TextEditingController();
  HistoryFilter _filter = HistoryFilter.all;
  HistorySort _sort = HistorySort.newest;
  HistoryGroupMode _groupMode = HistoryGroupMode.byDate;
  String _persistentHeader = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    var history = await widget.storage.loadHistory();
    if (widget.groupIdFilter != null) {
      history =
          history.where((e) => e.groupId == widget.groupIdFilter).toList();
    }
    HistoryEntry? draftEntry;
    if (widget.groupIdFilter == null) {
      draftEntry = await widget.storage.loadActiveDraftEntry();
    } else {
      final groupDraft = await widget.storage.loadGroupDraft(
        widget.groupIdFilter!,
      );
      if (groupDraft != null && groupDraft.hasData) {
        draftEntry = groupDraft.toHistoryEntry(
          id: groupDraft.historyEntryId ?? HistoryEntry.activeDraftId,
          status: groupDraft.lastView == 'results'
              ? HistoryEntry.completedStatus
              : HistoryEntry.draftStatus,
          savedAt: groupDraft.updatedAt ?? DateTime.now(),
          updatedAt: groupDraft.updatedAt,
          groupId: widget.groupIdFilter,
        );
      }
    }
    final header = await widget.storage.loadPersistentHeader();
    if (!mounted) return;
    setState(() {
      _persistentHeader = header;
      _allItems = mergeHistoryWithDraft(
        history: history,
        draftEntry: draftEntry,
      );
      _loading = false;
    });
  }

  List<HistoryDisplayItem> get _visibleItems => sortHistoryItems(
        filterHistoryItems(
          items: _allItems,
          filter: _filter,
          searchQuery: _searchController.text,
        ),
        _sort,
      );

  List<HistoryDateGroup> get _groups {
    if (_groupMode == HistoryGroupMode.none) {
      return [
        HistoryDateGroup(label: 'All Calculations', items: _visibleItems),
      ];
    }
    return groupHistoryByDate(_visibleItems);
  }

  Future<void> _delete(HistoryDisplayItem item) async {
    final confirmed = await showHisabProConfirmDialog(
      context: context,
      title: 'Delete Calculation?',
      message: 'This cannot be undone.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (confirmed != true) return;

    if (item.isDraft) {
      if (widget.groupIdFilter != null) {
        await widget.storage.clearGroupDraft(widget.groupIdFilter!);
      } else {
        await widget.storage.clearDraft();
      }
    }
    await widget.storage.deleteFromHistory(item.entry.id);
    widget.onDeleteEntry?.call(item.entry.id);
    if (!mounted) return;
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Calculation deleted'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _clearAllHistory() async {
    final confirmed = await showHisabProConfirmDialog(
      context: context,
      title: 'Clear all history?',
      message: 'All saved calculations will be removed. This cannot be undone.',
      confirmLabel: 'Clear',
      destructive: true,
    );
    if (confirmed != true) return;

    await widget.storage.saveHistory([]);
    await widget.storage.clearDraft();
    if (!mounted) return;
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('History cleared'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _edit(HistoryDisplayItem item) {
    widget.onEditEntry(item.entry);
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _view(HistoryDisplayItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HistoryDetailScreen(
          item: item,
          persistentHeader: _persistentHeader,
          onEdit: () {
            Navigator.pop(context);
            _edit(item);
          },
        ),
      ),
    );
  }

  Future<void> _duplicate(HistoryDisplayItem item) async {
    final source = item.entry;
    final duplicated = source.copyWith(
      id: HistoryEntry.activeDraftId,
      title: item.listTitle,
      status: HistoryEntry.draftStatus,
      savedAt: DateTime.now(),
      updatedAt: DateTime.now(),
      rows: source.rows.map((row) => row.copyWith()).toList(),
    );

    await widget.storage.saveDraft(
      DraftState(
        title: item.listTitle,
        rows: duplicated.rows,
        passingRate: duplicated.passingRate,
        amountDeductionRate: duplicated.amountDeductionRate,
        commissionTracking: duplicated.commissionTracking,
        lastView: 'main',
        updatedAt: DateTime.now(),
      ),
    );

    if (!mounted) return;
    widget.onEditEntry(duplicated);
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _share(HistoryDisplayItem item) async {
    final result = item.result;
    if (result == null) return;

    await shareCalculationMessage(
      buildCopyMessage(
        title: item.listTitle,
        rows: item.entry.rows,
        result: result,
        persistentHeader: _persistentHeader,
      ),
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ready to share'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(milliseconds: 1600),
      ),
    );
  }

  void _toggleSearch() {
    setState(() {
      _searchOpen = !_searchOpen;
      if (!_searchOpen) {
        _searchController.clear();
      }
    });
  }

  void _openFilterSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return _HistoryFilterSheet(
          sort: _sort,
          groupMode: _groupMode,
          onApply: (sort, groupMode) {
            setState(() {
              _sort = sort;
              _groupMode = groupMode;
            });
          },
          onClearHistory: () async {
            Navigator.pop(sheetContext);
            await _clearAllHistory();
          },
        );
      },
    );
  }

  void _openCardMenu(HistoryDisplayItem item) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _HistoryCardMenuSheet(
          onView: () {
            Navigator.pop(sheetContext);
            _view(item);
          },
          onEdit: () {
            Navigator.pop(sheetContext);
            _edit(item);
          },
          onDuplicate: () {
            Navigator.pop(sheetContext);
            _duplicate(item);
          },
          onShare: item.result == null
              ? null
              : () {
                  Navigator.pop(sheetContext);
                  _share(item);
                },
          onDelete: () {
            Navigator.pop(sheetContext);
            _delete(item);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _HistoryColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),
                if (_searchOpen) _buildSearchField(),
                _buildFilterBar(),
                Expanded(
                  child: _loading ? _buildSkeleton() : _buildBody(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            color: _HistoryColors.navy,
            iconSize: 20,
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'History',
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: _HistoryColors.navy,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    'Your calculations, always saved',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: _HistoryColors.muted,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
          ),
          _headerIconButton(
            icon: _searchOpen ? Icons.close_rounded : Icons.search_rounded,
            tooltip: _searchOpen ? 'Close search' : 'Search',
            onPressed: _toggleSearch,
          ),
          _headerIconButton(
            icon: Icons.tune_rounded,
            tooltip: 'Filter & sort',
            onPressed: _openFilterSheet,
          ),
        ],
      ),
    );
  }

  Widget _headerIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      icon: Icon(icon, size: 18, color: _HistoryColors.navy),
      padding: const EdgeInsets.all(8),
      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(_pagePadding, 8, _pagePadding, 0),
      child: TextField(
        controller: _searchController,
        autofocus: true,
        style: GoogleFonts.inter(fontSize: 13, color: _HistoryColors.navy),
        decoration: InputDecoration(
          hintText: 'Search by title or entry name',
          hintStyle: GoogleFonts.inter(
            fontSize: 13,
            color: _HistoryColors.muted,
          ),
          prefixIcon: const Icon(Icons.search_rounded, size: 18),
          filled: true,
          fillColor: Colors.white,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _HistoryColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _HistoryColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _HistoryColors.primary),
          ),
        ),
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  Widget _buildFilterBar() {
    const filters = <HistoryFilter, String>{
      HistoryFilter.all: 'All',
      HistoryFilter.drafts: 'Drafts',
      HistoryFilter.lene: 'Lene Aaj',
      HistoryFilter.dene: 'Dene Aaj',
    };

    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(_pagePadding, 10, _pagePadding, 0),
        children: filters.entries.map((entry) {
          final selected = _filter == entry.key;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Material(
              color: selected ? _HistoryColors.primary : _HistoryColors.chipInactiveBg,
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                onTap: () => setState(() => _filter = entry.key),
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: selected
                          ? _HistoryColors.primary
                          : _HistoryColors.chipInactiveBorder,
                    ),
                  ),
                  child: Text(
                    entry.value,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : _HistoryColors.navy,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBody() {
    if (_allItems.isEmpty) {
      return _buildEmptyState();
    }

    if (_visibleItems.isEmpty) {
      return _buildFilteredEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: _HistoryColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(
          _pagePadding,
          12,
          _pagePadding,
          20,
        ),
        itemCount: _groups.length,
        itemBuilder: (context, groupIndex) {
          final group = _groups[groupIndex];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (groupIndex > 0) const SizedBox(height: 22),
              _buildDateHeader(group),
              const SizedBox(height: 8),
              ...group.items.map(_buildHistoryCard),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDateHeader(HistoryDateGroup group) {
    final count = group.items.length;
    final countLabel = count == 1 ? '1 entry' : '$count entries';

    return Row(
      children: [
        Text(
          group.label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: _HistoryColors.navy,
          ),
        ),
        const Spacer(),
        Text(
          countLabel,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: _HistoryColors.muted,
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryCard(HistoryDisplayItem item) {
    final style = _statusStyle(item);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _HistoryColors.border),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _statusIcon(item, style),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 96),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.listTitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: _HistoryColors.navy,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                formatHistoryCardDate(item.entry.savedAt),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: _HistoryColors.muted,
                                  height: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    width: 96,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            _statusBadge(item, style),
                            _cardMenuButton(item),
                          ],
                        ),
                        const SizedBox(height: 4),
                        _amountDisplay(item),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Divider(height: 1, color: _HistoryColors.divider),
              const SizedBox(height: 8),
              Row(
                children: [
                  _rowCountBadge(item.rowCount),
                  const Spacer(),
                  _actionButton(
                    label: 'View',
                    icon: Icons.visibility_outlined,
                    onTap: () => _view(item),
                  ),
                  const SizedBox(width: 6),
                  _actionButton(
                    label: 'Edit',
                    icon: Icons.edit_outlined,
                    onTap: () => _edit(item),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusIcon(HistoryDisplayItem item, _StatusStyle style) {
    IconData icon;
    if (item.isDraft) {
      icon = Icons.description_outlined;
    } else if (item.resultType == ResultType.lene) {
      icon = Icons.arrow_upward_rounded;
    } else if (item.resultType == ResultType.dene) {
      icon = Icons.arrow_downward_rounded;
    } else {
      icon = Icons.balance_rounded;
    }

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: style.iconBg,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 16, color: style.iconColor),
    );
  }

  Widget _cardMenuButton(HistoryDisplayItem item) {
    return SizedBox(
      width: 28,
      height: 22,
      child: Align(
        alignment: Alignment.centerRight,
        child: InkWell(
          onTap: () => _openCardMenu(item),
          borderRadius: BorderRadius.circular(6),
          child: const Padding(
            padding: EdgeInsets.only(left: 4),
            child: Icon(
              Icons.more_vert_rounded,
              size: 18,
              color: _HistoryColors.muted,
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusBadge(HistoryDisplayItem item, _StatusStyle style) {
    final label = item.isDraft
        ? 'DRAFT'
        : item.result?.resultType.copyLabel ?? '—';

    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 7),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: style.badgeBg,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.fade,
        softWrap: false,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: style.badgeText,
          letterSpacing: 0.1,
        ),
      ),
    );
  }

  Widget _amountDisplay(HistoryDisplayItem item) {
    final text = item.result == null
        ? '—'
        : formatMoney(item.result!.displayAmount, showCurrency: true);

    return SizedBox(
      width: double.infinity,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerRight,
        child: Text(
          text,
          textAlign: TextAlign.right,
          maxLines: 1,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: item.result == null
                ? _HistoryColors.muted
                : _HistoryColors.navy,
            height: 1.1,
          ),
        ),
      ),
    );
  }

  Widget _rowCountBadge(int count) {
    final label = count == 1 ? '1 row' : '$count rows';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: _HistoryColors.rowBadgeBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _HistoryColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.grid_view_rounded,
            size: 12,
            color: _HistoryColors.muted,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: _HistoryColors.muted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: _HistoryColors.actionBg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: _HistoryColors.primary),
              const SizedBox(width: 4),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _HistoryColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.history_rounded,
              size: 44,
              color: _HistoryColors.muted.withValues(alpha: 0.55),
            ),
            const SizedBox(height: 14),
            Text(
              'No calculations yet',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: _HistoryColors.navy,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Your saved calculations will appear here.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: _HistoryColors.muted,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            if (widget.onStartNewCalculation != null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    widget.onStartNewCalculation!();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _HistoryColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100),
                    ),
                    textStyle: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: const Text('Start New Calculation'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilteredEmptyState() {
    String message;
    if (_searchController.text.trim().isNotEmpty) {
      message = 'No matching calculations found.';
    } else if (_filter == HistoryFilter.drafts) {
      message = 'No drafts';
    } else if (_filter == HistoryFilter.lene) {
      message = 'No Lene Aaj calculations';
    } else if (_filter == HistoryFilter.dene) {
      message = 'No Dene Aaj calculations';
    } else {
      message = 'No calculations found for this filter.';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: _HistoryColors.muted,
          ),
        ),
      ),
    );
  }

  Widget _buildSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.all(_pagePadding),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          height: 132,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _HistoryColors.border),
          ),
        );
      },
    );
  }

  _StatusStyle _statusStyle(HistoryDisplayItem item) {
    if (item.isDraft) {
      return const _StatusStyle(
        iconBg: _HistoryColors.draftIconBg,
        iconColor: _HistoryColors.draftIcon,
        badgeBg: _HistoryColors.draftBg,
        badgeText: _HistoryColors.draft,
      );
    }

    switch (item.resultType) {
      case ResultType.lene:
        return const _StatusStyle(
          iconBg: _HistoryColors.leneIconBg,
          iconColor: _HistoryColors.leneIcon,
          badgeBg: _HistoryColors.leneBg,
          badgeText: _HistoryColors.lene,
        );
      case ResultType.dene:
        return const _StatusStyle(
          iconBg: _HistoryColors.deneIconBg,
          iconColor: _HistoryColors.dene,
          badgeBg: _HistoryColors.deneBg,
          badgeText: _HistoryColors.dene,
        );
      case ResultType.balanced:
        return const _StatusStyle(
          iconBg: _HistoryColors.balancedBg,
          iconColor: _HistoryColors.balanced,
          badgeBg: _HistoryColors.balancedBg,
          badgeText: _HistoryColors.balanced,
        );
      case null:
        return const _StatusStyle(
          iconBg: _HistoryColors.draftBg,
          iconColor: _HistoryColors.draft,
          badgeBg: _HistoryColors.draftBg,
          badgeText: _HistoryColors.draft,
        );
    }
  }
}

class _StatusStyle {
  const _StatusStyle({
    required this.iconBg,
    required this.iconColor,
    required this.badgeBg,
    required this.badgeText,
  });

  final Color iconBg;
  final Color iconColor;
  final Color badgeBg;
  final Color badgeText;
}

class _HistoryCardMenuSheet extends StatelessWidget {
  const _HistoryCardMenuSheet({
    required this.onView,
    required this.onEdit,
    required this.onDuplicate,
    required this.onShare,
    required this.onDelete,
  });

  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onDuplicate;
  final VoidCallback? onShare;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _menuTile(
              icon: Icons.visibility_outlined,
              label: 'View Details',
              onTap: onView,
            ),
            _menuTile(
              icon: Icons.edit_outlined,
              label: 'Edit',
              onTap: onEdit,
            ),
            _menuTile(
              icon: Icons.copy_all_outlined,
              label: 'Duplicate',
              onTap: onDuplicate,
            ),
            if (onShare != null)
              _menuTile(
                icon: Icons.share_outlined,
                label: 'Share',
                onTap: onShare!,
              ),
            const Divider(height: 1, color: _HistoryColors.divider),
            _menuTile(
              icon: Icons.delete_outline,
              label: 'Delete',
              onTap: onDelete,
              destructive: true,
            ),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }

  Widget _menuTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool destructive = false,
  }) {
    final color = destructive ? _HistoryColors.dene : _HistoryColors.navy;
    final iconColor = destructive ? _HistoryColors.dene : _HistoryColors.muted;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: iconColor),
            const SizedBox(width: 14),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryFilterSheet extends StatefulWidget {
  const _HistoryFilterSheet({
    required this.sort,
    required this.groupMode,
    required this.onApply,
    required this.onClearHistory,
  });

  final HistorySort sort;
  final HistoryGroupMode groupMode;
  final void Function(HistorySort sort, HistoryGroupMode groupMode) onApply;
  final VoidCallback onClearHistory;

  @override
  State<_HistoryFilterSheet> createState() => _HistoryFilterSheetState();
}

class _HistoryFilterSheetState extends State<_HistoryFilterSheet> {
  late HistorySort _sort = widget.sort;
  late HistoryGroupMode _groupMode = widget.groupMode;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        12,
        0,
        12,
        MediaQuery.paddingOf(context).bottom + 16,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Sort & Filter',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _HistoryColors.navy,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Sort by',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _HistoryColors.muted,
                ),
              ),
              const SizedBox(height: 8),
              _radioTile(
                label: 'Date (Newest first)',
                selected: _sort == HistorySort.newest,
                onTap: () => setState(() => _sort = HistorySort.newest),
              ),
              _radioTile(
                label: 'Date (Oldest first)',
                selected: _sort == HistorySort.oldest,
                onTap: () => setState(() => _sort = HistorySort.oldest),
              ),
              _radioTile(
                label: 'Amount (High to Low)',
                selected: _sort == HistorySort.amountHigh,
                onTap: () => setState(() => _sort = HistorySort.amountHigh),
              ),
              _radioTile(
                label: 'Amount (Low to High)',
                selected: _sort == HistorySort.amountLow,
                onTap: () => setState(() => _sort = HistorySort.amountLow),
              ),
              const SizedBox(height: 12),
              Text(
                'Group by',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _HistoryColors.muted,
                ),
              ),
              const SizedBox(height: 8),
              _radioTile(
                label: 'Date (Day)',
                selected: _groupMode == HistoryGroupMode.byDate,
                onTap: () => setState(() => _groupMode = HistoryGroupMode.byDate),
              ),
              _radioTile(
                label: 'No Grouping',
                selected: _groupMode == HistoryGroupMode.none,
                onTap: () => setState(() => _groupMode = HistoryGroupMode.none),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    widget.onApply(_sort, _groupMode);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _HistoryColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Apply',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: widget.onClearHistory,
                icon: const Icon(
                  Icons.delete_outline,
                  size: 18,
                  color: _HistoryColors.dene,
                ),
                label: Text(
                  'Clear History',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _HistoryColors.dene,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _radioTile({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              size: 20,
              color: selected ? _HistoryColors.primary : _HistoryColors.muted,
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: _HistoryColors.navy,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
