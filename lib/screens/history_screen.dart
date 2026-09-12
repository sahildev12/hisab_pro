import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/format.dart';
import '../core/history_helpers.dart';
import '../core/storage.dart';
import '../models/history_entry.dart';
import '../models/result_type.dart';
import 'history_detail_screen.dart';

class _HistoryColors {
  static const background = Color(0xFFF7FAFF);
  static const navy = Color(0xFF17365D);
  static const border = Color(0xFFE2E8F0);
  static const muted = Color(0xFF64748B);
  static const primary = Color(0xFF2563EB);
  static const primarySoft = Color(0xFFEFF6FF);
  static const lene = Color(0xFF16A34A);
  static const leneBg = Color(0xFFECFDF3);
  static const dene = Color(0xFFDC2626);
  static const deneBg = Color(0xFFFEF2F2);
  static const draft = Color(0xFF64748B);
  static const draftBg = Color(0xFFF1F5F9);
  static const balanced = Color(0xFF2563EB);
  static const balancedBg = Color(0xFFEFF6FF);
  static const deleteBg = Color(0xFFFEF2F2);
}

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({
    super.key,
    required this.storage,
    required this.onEditEntry,
    this.onDeleteEntry,
    this.onStartNewCalculation,
  });

  final StorageService storage;
  final ValueChanged<HistoryEntry> onEditEntry;
  final ValueChanged<String>? onDeleteEntry;
  final VoidCallback? onStartNewCalculation;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<HistoryDisplayItem> _allItems = [];
  bool _loading = true;
  bool _searchOpen = false;
  final _searchController = TextEditingController();
  HistoryFilter _filter = HistoryFilter.all;
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
    final history = await widget.storage.loadHistory();
    final draftEntry = await widget.storage.loadActiveDraftEntry();
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

  List<HistoryDisplayItem> get _visibleItems => filterHistoryItems(
        items: _allItems,
        filter: _filter,
        searchQuery: _searchController.text,
      );

  List<HistoryDateGroup> get _groups => groupHistoryByDate(_visibleItems);

  Future<void> _delete(HistoryDisplayItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this calculation?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: _HistoryColors.dene),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    if (item.isDraft) {
      await widget.storage.clearDraft();
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

  void _toggleSearch() {
    setState(() {
      _searchOpen = !_searchOpen;
      if (!_searchOpen) {
        _searchController.clear();
      }
    });
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
                  child: _loading
                      ? _buildSkeleton()
                      : _buildBody(),
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
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            color: _HistoryColors.navy,
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'History',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: _HistoryColors.navy,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Your past calculations',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: _HistoryColors.muted,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              _searchOpen ? Icons.close : Icons.search,
              color: _HistoryColors.navy,
            ),
            onPressed: _toggleSearch,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: TextField(
        controller: _searchController,
        autofocus: true,
        decoration: InputDecoration(
          hintText: 'Search by title or entry name',
          prefixIcon: const Icon(Icons.search, size: 20),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _HistoryColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _HistoryColors.border),
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
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        children: filters.entries.map((entry) {
          final selected = _filter == entry.key;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(entry.value),
              selected: selected,
              showCheckmark: false,
              labelStyle: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : _HistoryColors.navy,
              ),
              backgroundColor: _HistoryColors.primarySoft,
              selectedColor: _HistoryColors.primary,
              side: BorderSide(
                color: selected ? _HistoryColors.primary : _HistoryColors.border,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              visualDensity: VisualDensity.compact,
              onSelected: (_) => setState(() => _filter = entry.key),
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
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: _groups.length,
        itemBuilder: (context, groupIndex) {
          final group = _groups[groupIndex];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (groupIndex > 0) const SizedBox(height: 20),
              _buildDateHeader(group),
              const SizedBox(height: 12),
              ...group.items.map(_buildHistoryCard),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDateHeader(HistoryDateGroup group) {
    return Row(
      children: [
        Text(
          group.label,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: _HistoryColors.navy,
          ),
        ),
        const Spacer(),
        Text(
          '${group.items.length} ${group.items.length == 1 ? 'calculation' : 'calculations'}',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: _HistoryColors.muted,
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryCard(HistoryDisplayItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _HistoryColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _view(item),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildCardHeader(item),
                    const SizedBox(height: 14),
                    _buildMetadata(item),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _buildActions(item),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardHeader(HistoryDisplayItem item) {
    final statusStyle = _statusStyle(item);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _statusIcon(item, statusStyle),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.displayTitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: _HistoryColors.navy,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                formatHistoryDate(item.entry.savedAt),
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: _HistoryColors.muted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _statusBadge(item, statusStyle),
            const SizedBox(height: 6),
            _amountDisplay(item, statusStyle),
          ],
        ),
      ],
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
      child: Icon(icon, size: 18, color: style.accent),
    );
  }

  Widget _statusBadge(HistoryDisplayItem item, _StatusStyle style) {
    final label = item.isDraft
        ? 'DRAFT'
        : item.result?.resultType.copyLabel ?? '—';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: style.badgeBg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: style.accent,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _amountDisplay(HistoryDisplayItem item, _StatusStyle style) {
    if (item.isDraft && item.result == null) {
      return Text(
        '—',
        style: GoogleFonts.inter(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: _HistoryColors.muted,
        ),
      );
    }

    if (item.result == null) {
      return Text(
        '—',
        style: GoogleFonts.inter(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: _HistoryColors.muted,
        ),
      );
    }

    return Text(
      formatMoney(item.result!.displayAmount, showCurrency: true),
      style: GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: style.accent,
        height: 1.1,
      ),
    );
  }

  Widget _buildMetadata(HistoryDisplayItem item) {
    return Row(
      children: [
        _metaCell('Passing', formatRate(item.entry.passingRate)),
        _metaCell('Deduction', formatRate(item.entry.amountDeductionRate)),
        _metaCell('Rows', '${item.rowCount}'),
      ],
    );
  }

  Widget _metaCell(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: _HistoryColors.muted,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _HistoryColors.navy,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(HistoryDisplayItem item) {
    return Row(
      children: [
        Expanded(
          child: _actionButton(
            label: 'Edit',
            icon: Icons.edit_outlined,
            bg: _HistoryColors.primarySoft,
            fg: _HistoryColors.primary,
            onTap: () => _edit(item),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _actionButton(
            label: 'View',
            icon: Icons.visibility_outlined,
            bg: _HistoryColors.primarySoft,
            fg: _HistoryColors.primary,
            onTap: () => _view(item),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _actionButton(
            label: 'Delete',
            icon: Icons.delete_outline,
            bg: _HistoryColors.deleteBg,
            fg: _HistoryColors.dene,
            onTap: () => _delete(item),
          ),
        ),
      ],
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required Color bg,
    required Color fg,
    required VoidCallback onTap,
  }) {
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: () {
          onTap();
        },
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          height: 40,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: fg),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: fg,
                  ),
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
              size: 48,
              color: _HistoryColors.muted.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 16),
            Text(
              'No Calculations Yet',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: _HistoryColors.navy,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your completed calculations and drafts\nwill appear here.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: _HistoryColors.muted,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100),
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
      message = 'No Drafts';
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
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: _HistoryColors.muted,
          ),
        ),
      ),
    );
  }

  Widget _buildSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          height: 160,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _HistoryColors.border),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 140,
                  height: 14,
                  decoration: BoxDecoration(
                    color: _HistoryColors.draftBg,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: 90,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _HistoryColors.draftBg,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const Spacer(),
                Row(
                  children: List.generate(
                    3,
                    (_) => Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        height: 36,
                        decoration: BoxDecoration(
                          color: _HistoryColors.draftBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  _StatusStyle _statusStyle(HistoryDisplayItem item) {
    if (item.isDraft) {
      return const _StatusStyle(
        accent: _HistoryColors.draft,
        badgeBg: _HistoryColors.draftBg,
        iconBg: _HistoryColors.draftBg,
      );
    }

    switch (item.resultType) {
      case ResultType.lene:
        return const _StatusStyle(
          accent: _HistoryColors.lene,
          badgeBg: _HistoryColors.leneBg,
          iconBg: _HistoryColors.leneBg,
        );
      case ResultType.dene:
        return const _StatusStyle(
          accent: _HistoryColors.dene,
          badgeBg: _HistoryColors.deneBg,
          iconBg: _HistoryColors.deneBg,
        );
      case ResultType.balanced:
        return const _StatusStyle(
          accent: _HistoryColors.balanced,
          badgeBg: _HistoryColors.balancedBg,
          iconBg: _HistoryColors.balancedBg,
        );
      case null:
        return const _StatusStyle(
          accent: _HistoryColors.muted,
          badgeBg: _HistoryColors.draftBg,
          iconBg: _HistoryColors.draftBg,
        );
    }
  }
}

class _StatusStyle {
  const _StatusStyle({
    required this.accent,
    required this.badgeBg,
    required this.iconBg,
  });

  final Color accent;
  final Color badgeBg;
  final Color iconBg;
}
