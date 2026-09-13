import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/entry_names.dart';
import '../core/storage.dart';
import '../theme/app_theme.dart';
import '../widgets/hisab_page_header.dart';
import '../widgets/hisab_pro_modal.dart';

class EntryNamesScreen extends StatefulWidget {
  const EntryNamesScreen({
    super.key,
    required this.initialSettings,
  });

  final AppSettings initialSettings;

  @override
  State<EntryNamesScreen> createState() => _EntryNamesScreenState();
}

class _EntryNamesScreenState extends State<EntryNamesScreen> {
  late List<String> _customNames;
  final _newNameController = TextEditingController();
  String? _addError;
  int? _editingIndex;

  @override
  void initState() {
    super.initState();
    _customNames = List<String>.from(widget.initialSettings.customEntryNames);
  }

  @override
  void dispose() {
    _newNameController.dispose();
    super.dispose();
  }

  void _addName() {
    final name = _newNameController.text.trim();
    if (name.isEmpty) {
      setState(() => _addError = 'Enter a name.');
      return;
    }
    if (isStaticEntryName(name) || _customNames.contains(name)) {
      setState(() => _addError = 'Name already exists.');
      return;
    }
    setState(() {
      _customNames.add(name);
      _newNameController.clear();
      _addError = null;
    });
  }

  Future<void> _deleteName(int index) async {
    final name = _customNames[index];
    final confirmed = await showHisabProConfirmDialog(
      context: context,
      title: 'Delete "$name"?',
      message: 'This name will no longer appear in new entries.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (confirmed != true) return;
    setState(() {
      _customNames.removeAt(index);
      _editingIndex = null;
    });
  }

  void _save() {
    Navigator.pop(
      context,
      widget.initialSettings.copyWith(customEntryNames: _customNames),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isDarkContext(context)
          ? AppColors.canvasDark
          : HisabPageColors.canvas,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HisabPageHeader(
            title: 'Entry Names',
            subtitle: 'Manage custom entry names',
            onBack: () => Navigator.pop(context),
            actions: [
              TextButton(
                onPressed: _save,
                child: Text(
                  'Save',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.pagePadding),
              children: [
          Text(
            'Add New Entry Name',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: AppColors.inkDeep,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _newNameController,
            decoration: InputDecoration(
              hintText: 'Enter custom name',
              errorText: _addError,
            ),
            onChanged: (_) => setState(() => _addError = null),
            onSubmitted: (_) => _addName(),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _addName,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Name'),
            ),
          ),
          const SizedBox(height: 20),
          Text('Custom Names', style: sectionLabelStyle(context)),
          const SizedBox(height: 10),
          if (_customNames.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: softSurfaceDecoration(context),
              child: Text(
                'No custom names yet. Add one above.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: AppColors.slate),
              ),
            )
          else
            ...List.generate(_customNames.length, (index) {
              if (_editingIndex == index) {
                return _EditNameRow(
                  initial: _customNames[index],
                  onSave: (value) {
                    final trimmed = value.trim();
                    if (trimmed.isEmpty) return;
                    if (trimmed != _customNames[index] &&
                        (isStaticEntryName(trimmed) ||
                            _customNames.contains(trimmed))) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Name already exists.'),
                        ),
                      );
                      return;
                    }
                    setState(() {
                      _customNames[index] = trimmed;
                      _editingIndex = null;
                    });
                  },
                  onCancel: () => setState(() => _editingIndex = null),
                );
              }
              return _nameRow(_customNames[index], index);
            }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _nameRow(String name, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(14, 8, 4, 8),
      decoration: surfaceDecoration(context),
      child: Row(
        children: [
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: AppColors.inkDeep,
              ),
            ),
          ),
          SizedBox(
            width: 88,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _actionIcon(
                  icon: Icons.edit_outlined,
                  color: AppColors.primary,
                  onTap: () => setState(() => _editingIndex = index),
                ),
                _actionIcon(
                  icon: Icons.delete_outline,
                  color: AppColors.danger,
                  onTap: () => _deleteName(index),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionIcon({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 40,
      height: 40,
      child: IconButton(
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        icon: Icon(icon, size: 18, color: color),
        onPressed: onTap,
      ),
    );
  }
}

class _EditNameRow extends StatefulWidget {
  const _EditNameRow({
    required this.initial,
    required this.onSave,
    required this.onCancel,
  });

  final String initial;
  final ValueChanged<String> onSave;
  final VoidCallback onCancel;

  @override
  State<_EditNameRow> createState() => _EditNameRowState();
}

class _EditNameRowState extends State<_EditNameRow> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initial);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(10, 6, 4, 6),
      decoration: surfaceDecoration(context),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              autofocus: true,
            ),
          ),
          SizedBox(
            width: 88,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SizedBox(
                  width: 40,
                  height: 40,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.check, color: AppColors.success),
                    onPressed: () => widget.onSave(_controller.text),
                  ),
                ),
                SizedBox(
                  width: 40,
                  height: 40,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.close, color: AppColors.slate),
                    onPressed: widget.onCancel,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
