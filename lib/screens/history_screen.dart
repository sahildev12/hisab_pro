import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

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
  late HistoryGroupMode _groupMode;
  DateTime? _filterFrom;
  DateTime? _filterTo;
  String _persistentHeader = '';
  Map<String, String> _groupNames = const {};

  @override
  void initState() {
    super.initState();
    // Inside a single group there is nothing to group by, so fall back to dates.
    _groupMode = widget.groupIdFilter == null
        ? HistoryGroupMode.byGroup
        : HistoryGroupMode.byDate;
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    // Only calculated records are listed; in-progress drafts stay out of
    // history until Calculate is pressed.
    final history = widget.groupIdFilter != null
        ? await widget.storage.loadGroupHistory(widget.groupIdFilter!)
        : await widget.storage.loadHistory();
    final header = await widget.storage.loadPersistentHeader();
    final groups = await widget.storage.loadGroups();
    if (!mounted) return;
    setState(() {
      _persistentHeader = header;
      _groupNames = {for (final group in groups) group.id: group.name};
      _allItems = mergeHistoryWithDraft(history: history, draftEntry: null);
      _loading = false;
    });
  }

  List<HistoryDisplayItem> get _visibleItems {
    var items = sortHistoryItems(
      filterHistoryItems(
        items: _allItems,
        filter: _filter,
        searchQuery: _searchController.text,
      ),
      _sort,
    );

    if (_filterFrom != null || _filterTo != null) {
      items = items.where(_isWithinDateRange).toList();
    }

    return items;
  }

  bool _isWithinDateRange(HistoryDisplayItem item) {
    final saved = item.entry.savedAt;
    final day = DateTime(saved.year, saved.month, saved.day);

    if (_filterFrom != null) {
      final from = DateTime(
        _filterFrom!.year,
        _filterFrom!.month,
        _filterFrom!.day,
      );
      if (day.isBefore(from)) return false;
    }

    if (_filterTo != null) {
      final to = DateTime(
        _filterTo!.year,
        _filterTo!.month,
        _filterTo!.day,
      );
      if (day.isAfter(to)) return false;
    }

    return true;
  }

  List<HistoryDateGroup> get _groups {
    switch (_groupMode) {
      case HistoryGroupMode.none:
        return [
          HistoryDateGroup(label: 'All Calculations', items: _visibleItems),
        ];
      case HistoryGroupMode.byGroup:
        return groupHistoryByGroup(_visibleItems, groupNames: _groupNames);
      case HistoryGroupMode.byDate:
        return groupHistoryByDate(_visibleItems);
    }
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

  void _edit(HistoryDisplayItem item) {
    widget.onEditEntry(item.entry);
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    }
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
        return _HistoryDateRangeSheet(
          from: _filterFrom,
          to: _filterTo,
          onApply: (from, to) {
            setState(() {
              _filterFrom = from;
              _filterTo = to;
            });
          },
          onClear: () {
            setState(() {
              _filterFrom = null;
              _filterTo = null;
            });
          },
        );
      },
    );
  }

  String _cardTimeLabel(HistoryDisplayItem item) {
    final headerHasDate = widget.groupIdFilter != null ||
        _groupMode == HistoryGroupMode.byDate;
    return headerHasDate
        ? formatHistoryCardTime(item.entry.savedAt)
        : formatHistoryCardDate(item.entry.savedAt);
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
                if (!_loading && _allItems.isNotEmpty) _buildTotalBanner(),
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

  String? get _filteredGroupName {
    final groupId = widget.groupIdFilter;
    if (groupId == null) return null;
    return _groupNames[groupId];
  }

  bool _shouldHideCardTitle(HistoryDisplayItem item) {
    if (widget.groupIdFilter != null) return true;
    if (_groupMode != HistoryGroupMode.byGroup) return false;
    final groupId = item.entry.groupId;
    if (groupId == null) return false;
    return _groupNames[groupId] == item.listTitle;
  }

  Widget _buildHeader() {
    final groupName = _filteredGroupName;

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
                    groupName ?? 'History',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: _HistoryColors.navy,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    groupName == null
                        ? 'Every change, kept for $historyRetentionDays days'
                        : 'History • Last $historyRetentionDays days',
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
            tooltip: 'Date range',
            onPressed: _openFilterSheet,
          ),
        ],
      ),
    );
  }

  Widget _buildTotalBanner() {
    final total = historyTotalAmount(_visibleItems);
    final label = widget.groupIdFilter == null
        ? 'Total Amount • Last $historyRetentionDays days'
        : 'Total Amount';

    return Padding(
      padding: const EdgeInsets.fromLTRB(_pagePadding, 10, _pagePadding, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _HistoryColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                color: _HistoryColors.actionBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.summarize_outlined,
                size: 17,
                color: _HistoryColors.primary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: _HistoryColors.muted,
                ),
              ),
            ),
            Text(
              formatMoney(total, showCurrency: true),
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _HistoryColors.navy,
              ),
            ),
          ],
        ),
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
    final total = historyTotalAmount(group.items);

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              group.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _HistoryColors.navy,
                height: 1.2,
              ),
            ),
          ),
          Text(
            'TOTAL ${formatMoney(total, showCurrency: true)}',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _HistoryColors.navy,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(HistoryDisplayItem item) {
    final style = _statusStyle(item);
    final hideTitle = _shouldHideCardTitle(item);
    final canShare = item.result != null;

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
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _statusIcon(item, style),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!hideTitle) ...[
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
                        ],
                        Text(
                          _cardTimeLabel(item),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: hideTitle ? 14 : 12,
                            fontWeight: hideTitle
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: hideTitle
                                ? _HistoryColors.navy
                                : _HistoryColors.muted,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        _amountDisplay(item),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (!item.isDraft) _statusBadge(item, style),
                ],
              ),
              const SizedBox(height: 10),
              const Divider(height: 1, color: _HistoryColors.divider),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
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
                  const SizedBox(width: 6),
                  _actionButton(
                    label: 'Share',
                    icon: Icons.share_outlined,
                    onTap: canShare ? () => _share(item) : null,
                  ),
                  const SizedBox(width: 6),
                  _actionButton(
                    label: 'Delete',
                    icon: Icons.delete_outline,
                    onTap: () => _delete(item),
                    destructive: true,
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

  Widget _statusBadge(HistoryDisplayItem item, _StatusStyle style) {
    if (item.isDraft) return const SizedBox.shrink();

    final label = item.result?.resultType.copyLabel ?? '—';

    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 7),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: style.badgeBg,
        borderRadius: BorderRadius.circular(11),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          softWrap: false,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: style.badgeText,
            letterSpacing: 0.1,
          ),
        ),
      ),
    );
  }

  Widget _amountDisplay(HistoryDisplayItem item) {
    final text = item.result == null
        ? '—'
        : formatMoney(item.result!.displayAmount, showCurrency: true);

    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: item.result == null ? _HistoryColors.muted : _HistoryColors.navy,
        height: 1.1,
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    VoidCallback? onTap,
    bool destructive = false,
  }) {
    final enabled = onTap != null;
    final color =
        destructive ? _HistoryColors.dene : _HistoryColors.primary;
    final bg = destructive ? _HistoryColors.deneBg : _HistoryColors.actionBg;

    return Material(
      color: enabled ? bg : _HistoryColors.rowBadgeBg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: enabled ? color : _HistoryColors.muted,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: enabled ? color : _HistoryColors.muted,
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
    } else if (_filterFrom != null || _filterTo != null) {
      message = 'No calculations in this date range.';
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

class _HistoryDateRangeSheet extends StatefulWidget {
  const _HistoryDateRangeSheet({
    required this.from,
    required this.to,
    required this.onApply,
    required this.onClear,
  });

  final DateTime? from;
  final DateTime? to;
  final void Function(DateTime? from, DateTime? to) onApply;
  final VoidCallback onClear;

  @override
  State<_HistoryDateRangeSheet> createState() => _HistoryDateRangeSheetState();
}

class _HistoryDateRangeSheetState extends State<_HistoryDateRangeSheet> {
  DateTime? _from;
  DateTime? _to;

  @override
  void initState() {
    super.initState();
    _from = widget.from;
    _to = widget.to;
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final initial = isFrom
        ? (_from ?? DateTime.now())
        : (_to ?? _from ?? DateTime.now());
    final first = DateTime.now().subtract(const Duration(days: 365));
    final last = DateTime.now().add(const Duration(days: 1));

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
      helpText: isFrom ? 'From date' : 'To date',
    );
    if (picked == null || !mounted) return;

    setState(() {
      if (isFrom) {
        _from = picked;
        if (_to != null && _to!.isBefore(picked)) {
          _to = picked;
        }
      } else {
        _to = picked;
        if (_from != null && _from!.isAfter(picked)) {
          _from = picked;
        }
      }
    });
  }

  String _formatPickerDate(DateTime? date) {
    if (date == null) return 'Select date';
    return DateFormat('d MMM yyyy').format(date);
  }

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
                'Date Range',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _HistoryColors.navy,
                ),
              ),
              const SizedBox(height: 16),
              _dateField(
                label: 'From',
                value: _formatPickerDate(_from),
                onTap: () => _pickDate(isFrom: true),
              ),
              const SizedBox(height: 10),
              _dateField(
                label: 'To',
                value: _formatPickerDate(_to),
                onTap: () => _pickDate(isFrom: false),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _from == null && _to == null
                      ? null
                      : () {
                          widget.onApply(_from, _to);
                          Navigator.pop(context);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _HistoryColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        _HistoryColors.chipInactiveBg,
                    disabledForegroundColor: _HistoryColors.muted,
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
              if (_from != null || _to != null || widget.from != null) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    widget.onClear();
                    Navigator.pop(context);
                  },
                  child: Text(
                    'Clear dates',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _HistoryColors.muted,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _dateField({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    final hasValue = value != 'Select date';

    return Material(
      color: _HistoryColors.chipInactiveBg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _HistoryColors.muted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: hasValue
                            ? _HistoryColors.navy
                            : _HistoryColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.calendar_today_rounded,
                size: 18,
                color: hasValue
                    ? _HistoryColors.primary
                    : _HistoryColors.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
