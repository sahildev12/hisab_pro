import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/money.dart';
import '../core/storage.dart';
import '../core/validate_rate.dart';
import '../models/calculation_group.dart';
import '../theme/app_theme.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({
    super.key,
    required this.storage,
    required this.settings,
    this.initialGroup,
  });

  final StorageService storage;
  final AppSettings settings;
  final CalculationGroup? initialGroup;

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _passingController;
  late final TextEditingController _deductionController;
  bool _linked = true;
  String? _error;

  bool get _isEdit => widget.initialGroup != null;

  @override
  void initState() {
    super.initState();
    final group = widget.initialGroup;
    _nameController = TextEditingController(text: group?.name ?? '');
    _passingController = TextEditingController(
      text: (group?.passingRate ?? widget.settings.defaultPassingRate)
          .toStringAsFixed(0),
    );
    _deductionController = TextEditingController(
      text: (group?.amountDeductionRate ??
              widget.settings.defaultAmountDeductionRate)
          .toStringAsFixed(0),
    );
    _linked = group == null ||
        group.amountDeductionRate ==
            suggestedAmountDeduction(group.passingRate);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _passingController.dispose();
    _deductionController.dispose();
    super.dispose();
  }

  void _onPassingChanged(String value) {
    if (!_linked) return;
    final passing = Decimal.tryParse(value.trim());
    if (passing != null) {
      _deductionController.text =
          suggestedAmountDeduction(passing).toStringAsFixed(0);
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Group name is required.');
      return;
    }

    final passingResult = validatePassingRate(_passingController.text.trim());
    final deductionResult =
        validateDeductionRate(_deductionController.text.trim());
    if (!passingResult.isValid) {
      setState(() => _error = passingResult.errorMessage);
      return;
    }
    if (!deductionResult.isValid) {
      setState(() => _error = deductionResult.errorMessage);
      return;
    }
    final passing = Decimal.parse(_passingController.text.trim());
    final deduction = Decimal.parse(_deductionController.text.trim());

    final now = DateTime.now();
    final group = widget.initialGroup?.copyWith(
          name: name,
          passingRate: passing!,
          amountDeductionRate: deduction!,
          updatedAt: now,
        ) ??
        CalculationGroup.create(
          name: name,
          passingRate: passing,
          amountDeductionRate: deduction,
        );

    await widget.storage.upsertGroup(group);
    if (mounted) Navigator.pop(context, group);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Group' : 'Create New Group'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.primaryText,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Group Name',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: AppColors.primaryText,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'Enter group name',
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Calculation Rate',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: AppColors.primaryText,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _rateField(
                    label: 'Passing Rate',
                    controller: _passingController,
                    onChanged: _onPassingChanged,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _rateField(
                    label: 'Commission / Deduction',
                    controller: _deductionController,
                    onChanged: (_) {
                      if (_linked) setState(() => _linked = false);
                    },
                  ),
                ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: const TextStyle(color: AppColors.danger),
              ),
            ],
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                minimumSize: const Size.fromHeight(AppSpacing.buttonHeight),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
                ),
              ),
              child: Text(_isEdit ? 'Save Changes' : 'Create Group'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _rateField({
    required String label,
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 13, color: AppColors.slate)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          onChanged: onChanged,
          decoration: InputDecoration(
            suffixText: '%',
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
              borderSide: const BorderSide(color: AppColors.border),
            ),
          ),
        ),
      ],
    );
  }
}
