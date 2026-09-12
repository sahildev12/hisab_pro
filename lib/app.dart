import 'package:flutter/material.dart';

import 'core/calculate.dart';
import 'core/storage.dart';
import 'core/validate.dart';
import 'models/calculation_result.dart';
import 'models/row_data.dart';
import 'models/settlement_type.dart';
import 'screens/main_screen.dart';
import 'screens/results_screen.dart';
import 'theme/app_theme.dart';

enum AppView { main, results }

class HisabProApp extends StatelessWidget {
  const HisabProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HisabPro',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const AppShell(),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final _storage = StorageService();
  bool _loading = true;

  AppView _view = AppView.main;
  String _title = '';
  List<RowData> _rows = [];
  CalculationResult? _result;
  SettlementType _settlementType = SettlementType.lene;
  int _bracketRate = defaultMultiplier;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final saved = await _storage.load();
    if (!mounted) return;

    setState(() {
      if (saved != null) {
        _title = saved.title;
        _rows = saved.rows;
        _settlementType = saved.settlementType;
        _bracketRate = saved.bracketRate;
        _view = saved.lastView == 'results' ? AppView.results : AppView.main;
      } else {
        _title = '';
        _rows = [];
        _settlementType = SettlementType.lene;
        _bracketRate = defaultMultiplier;
        _view = AppView.main;
      }
      _loading = false;
    });

    if (_view == AppView.results && saved != null) {
      final validation = validateRows(saved.rows);
      if (validation.isValid) {
        try {
          _result = calculate(
            saved.rows,
            multiplier: saved.bracketRate,
            settlementType: saved.settlementType,
          );
        } catch (_) {
          _view = AppView.main;
          _result = null;
        }
      } else {
        _view = AppView.main;
        _result = null;
      }
    }
  }

  Future<void> _onCalculate(
    String title,
    List<RowData> rows,
    CalculationResult result,
    SettlementType settlementType,
    int bracketRate,
  ) async {
    await _storage.save(
      SavedState(
        title: title,
        rows: rows,
        lastView: 'results',
        settlementType: settlementType,
        bracketRate: bracketRate,
      ),
    );

    setState(() {
      _title = title;
      _rows = rows;
      _result = result;
      _settlementType = settlementType;
      _bracketRate = bracketRate;
      _view = AppView.results;
    });
  }

  Future<void> _resetToFresh() async {
    setState(() {
      _title = '';
      _rows = [];
      _result = null;
      _settlementType = SettlementType.lene;
      _bracketRate = defaultMultiplier;
      _view = AppView.main;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_view == AppView.results && _result != null) {
      return ResultsScreen(
        storage: _storage,
        title: _title,
        rows: _rows,
        result: _result!,
        settlementType: _settlementType,
        bracketRate: _bracketRate,
        onBack: () {
          setState(() => _view = AppView.main);
        },
      );
    }

    return MainScreen(
      storage: _storage,
      initialTitle: _title,
      initialRows: _rows,
      initialSettlementType: _settlementType,
      initialBracketRate: _bracketRate,
      onCalculate: _onCalculate,
      onNewCalculation: _resetToFresh,
    );
  }
}
