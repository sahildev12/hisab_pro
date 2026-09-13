import 'package:decimal/decimal.dart';

import 'package:flutter/material.dart';

import 'package:flutter/services.dart';



import 'constants/entry_names.dart';

import 'core/calculate.dart';

import 'core/commission.dart';

import 'core/format.dart';

import 'core/storage.dart';

import 'core/validate.dart';

import 'models/calculation_result.dart';

import 'models/history_entry.dart';

import 'models/row_data.dart';

import 'screens/history_screen.dart';

import 'screens/main_screen.dart';

import 'screens/results_screen.dart';

import 'theme/app_theme.dart';

import 'widgets/dismiss_keyboard.dart';



enum AppView { main, results }



class HisabProApp extends StatelessWidget {

  const HisabProApp({super.key});



  static final GlobalKey<NavigatorState> navigatorKey =

      GlobalKey<NavigatorState>();



  @override

  Widget build(BuildContext context) {

    return const AppShell();

  }

}



class AppShell extends StatefulWidget {

  const AppShell({super.key});



  @override

  State<AppShell> createState() => _AppShellState();

}



class _AppShellState extends State<AppShell> {

  final _storage = StorageService();

  final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();



  bool _loading = true;

  bool _draftRestored = false;

  DateTime? _lastBackPress;



  AppView _view = AppView.main;

  int _mainScreenGeneration = 0;

  String _title = '';

  String _persistentHeader = '';

  List<RowData> _rows = [];

  CalculationResult? _result;

  DateTime? _resultCalculatedAt;

  Decimal _passingRate = defaultPassingRate;

  Decimal _amountDeductionRate = defaultAmountDeductionRate;

  bool _commissionTracking = false;

  Decimal _storedCommissionBalance = Decimal.zero;

  String? _historyEntryId;

  AppSettings _settings = AppSettings(

    defaultPassingRate: defaultPassingRate,

    defaultAmountDeductionRate: defaultAmountDeductionRate,

  );



  List<String> get _entryNames =>

      allEntryNames(_settings.customEntryNames);



  @override

  void initState() {

    super.initState();

    _loadState();

  }



  Future<void> _refreshCommissionBalance() async {

    final balance = await _storage.getCommissionBalance(

      commissionOwnerId(_title),

    );

    if (mounted) {

      setState(() => _storedCommissionBalance = balance);

    }

  }



  Future<void> _loadState() async {

    final settings = await _storage.loadSettings();

    final persistentHeader = await _storage.loadPersistentHeader();

    final draft = await _storage.loadDraft(

      fallbackPassingRate: settings.defaultPassingRate,

      fallbackAmountDeductionRate: settings.defaultAmountDeductionRate,

    );

    if (!mounted) return;



    final hadDraft = draft != null && draft.hasData;



    setState(() {

      _settings = settings;

      _persistentHeader = persistentHeader;

      if (draft != null) {

        _title = draft.title;

        _rows = draft.rows;

        _passingRate = draft.passingRate;

        _amountDeductionRate = draft.amountDeductionRate;

        _commissionTracking = draft.commissionTracking;

        _historyEntryId = draft.historyEntryId;

        _view = draft.lastView == 'results' ? AppView.results : AppView.main;

      } else {

        _title = '';

        _rows = [];

        _passingRate = settings.defaultPassingRate;

        _amountDeductionRate = settings.defaultAmountDeductionRate;

        _commissionTracking = settings.defaultCommissionTracking;

        _view = AppView.main;

      }

      _loading = false;

      _draftRestored = hadDraft;

    });



    await _refreshCommissionBalance();



    if (_draftRestored) {

      WidgetsBinding.instance.addPostFrameCallback((_) {

        _scaffoldMessengerKey.currentState?.showSnackBar(

          const SnackBar(

            content: Text('Draft restored'),

            behavior: SnackBarBehavior.floating,

          ),

        );

      });

    }



    if (_view == AppView.results && draft != null) {

      final validation = validateRows(draft.rows, allowedNames: _entryNames);

      if (validation.isValid) {

        try {

          final history = await _storage.loadHistory();

          HistoryEntry? existing;

          for (final entry in history) {

            if (entry.id == draft.historyEntryId) {

              existing = entry;

              break;

            }

          }

          final storedBalance = await _storage.getCommissionBalance(

            commissionOwnerId(draft.title),

          );

          var result = calculateSettlement(

            draft.rows,

            passingRate: draft.passingRate,

            amountDeductionRate: draft.amountDeductionRate,

            commissionTracking: draft.commissionTracking,

            storedCommissionBalance: storedBalance,

          );

          if (draft.commissionTracking && existing != null) {

            result = result.copyWith(

              commissionBalance: existing.commissionBalanceAtThatTime,

              storedCommissionBalance:

                  existing.commissionBalanceAtThatTime -

                  existing.commissionEarned,

            );

          }

          _result = result;

        } catch (_) {

          _view = AppView.main;

          _result = null;

        }

      } else {

        _view = AppView.main;

        _result = null;

      }

      if (mounted) setState(() {});

    }

  }



  Future<void> _saveDraft({String lastView = 'main'}) async {

    final now = DateTime.now();

    final hasData = _title.trim().isNotEmpty ||

        _rows.any(

          (row) =>

              row.name.trim().isNotEmpty ||

              row.amount.trim().isNotEmpty ||

              row.bracket.trim().isNotEmpty,

        );



    if (hasData) {

      _historyEntryId ??= now.microsecondsSinceEpoch.toString();

    }



    await _storage.saveDraft(

      DraftState(

        title: _title,

        rows: _rows,

        passingRate: _passingRate,

        amountDeductionRate: _amountDeductionRate,

        commissionTracking: _commissionTracking,

        lastView: lastView,

        historyEntryId: _historyEntryId,

        updatedAt: now,

      ),

    );



    if (hasData && _historyEntryId != null) {

      await _syncHistoryEntry(lastView: lastView, updatedAt: now);

    }

  }



  Future<void> _syncHistoryEntry({

    String lastView = 'main',

    DateTime? updatedAt,

  }) async {

    if (_historyEntryId == null) return;



    final now = updatedAt ?? DateTime.now();

    final history = await _storage.loadHistory();

    HistoryEntry? existing;

    for (final entry in history) {

      if (entry.id == _historyEntryId) {

        existing = entry;

        break;

      }

    }



    final status = _view == AppView.results && _result != null

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

    ).toHistoryEntry(

      id: _historyEntryId!,

      status: status,

      savedAt: existing?.savedAt ?? now,

      updatedAt: now,

      commissionEarned: _result?.commissionEarned,

      commissionBalanceAtThatTime: _result?.commissionBalance,

    );



    await _storage.upsertHistoryEntry(entry);

  }



  Future<void> _archiveCurrentToHistory() async {

    if (_historyEntryId == null) return;

    await _syncHistoryEntry();

  }



  Future<void> _onCalculate(

    String title,

    List<RowData> rows,

    CalculationResult result,

    Decimal passingRate,

    Decimal amountDeductionRate,

  ) async {

    _historyEntryId ??= DateTime.now().microsecondsSinceEpoch.toString();



    final history = await _storage.loadHistory();

    HistoryEntry? existing;

    for (final entry in history) {

      if (entry.id == _historyEntryId) {

        existing = entry;

        break;

      }

    }



    var finalResult = result;

    if (result.commissionTracking) {

      final ownerId = commissionOwnerId(title);

      final stored = await _storage.getCommissionBalance(ownerId);

      final oldEarned = existing?.commissionEarned ?? Decimal.zero;

      final newBalance = adjustCommissionBalance(

        currentBalance: stored,

        previousEarned: oldEarned,

        newEarned: result.commissionEarned,

      );

      await _storage.setCommissionBalance(ownerId, newBalance);

      finalResult = result.copyWith(

        commissionBalance: newBalance,

        storedCommissionBalance: newBalance - result.commissionEarned,

      );

      _storedCommissionBalance = newBalance;

    }



    setState(() {

      _title = title;

      _rows = rows;

      _result = finalResult;

      _resultCalculatedAt = DateTime.now();

      _passingRate = passingRate;

      _amountDeductionRate = amountDeductionRate;

      _commissionTracking = finalResult.commissionTracking;

      _view = AppView.results;

    });



    await _saveDraft(lastView: 'results');

  }



  Future<void> _onSettingsChanged(AppSettings settings) async {

    await _storage.saveSettings(settings);

    setState(() => _settings = settings);

  }



  void _openHistory() {
    HisabProApp.navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (context) => HistoryScreen(
          storage: _storage,
          onEditEntry: (entry) {
            Navigator.pop(context);
            _loadFromHistory(entry);
          },
          onDeleteEntry: _onHistoryEntryDeleted,
        ),
      ),
    );
  }

  Future<void> _deleteCurrentCalculation() async {
    final id = _historyEntryId;
    if (id != null) {
      await _storage.deleteFromHistory(id);
      await _onHistoryEntryDeleted(id);
      return;
    }
    await _startFreshCalculation();
  }

  void _onResultsBack() {
    setState(() => _view = AppView.main);
    _saveDraft(lastView: 'main');
  }

  Future<void> _onHistoryEntryDeleted(String id) async {

    if (id != _historyEntryId) return;



    await _storage.clearDraft();

    setState(() {

      _title = '';

      _rows = [];

      _result = null;

      _historyEntryId = null;

      _passingRate = _settings.defaultPassingRate;

      _amountDeductionRate = _settings.defaultAmountDeductionRate;

      _commissionTracking = _settings.defaultCommissionTracking;

      _view = AppView.main;

      _mainScreenGeneration++;

    });

    await _refreshCommissionBalance();

  }



  Future<void> _onPersistentHeaderChanged(String text) async {

    _persistentHeader = text;

    await _storage.savePersistentHeader(text);

  }



  Future<void> _startFreshCalculation() async {

    await _storage.clearDraft();

    setState(() {

      _title = '';

      _rows = [];

      _result = null;

      _passingRate = _settings.defaultPassingRate;

      _amountDeductionRate = _settings.defaultAmountDeductionRate;

      _commissionTracking = _settings.defaultCommissionTracking;

      _historyEntryId = null;

      _view = AppView.main;

      _mainScreenGeneration++;

    });

    await _refreshCommissionBalance();

  }



  Future<void> _onNewCalculationWithArchive() async {

    await _archiveCurrentToHistory();

    await _startFreshCalculation();

  }



  void _loadFromHistory(HistoryEntry entry) {

    setState(() {

      _title = entry.title;

      _rows = List<RowData>.from(entry.rows);

      _passingRate = entry.passingRate;

      _amountDeductionRate = entry.amountDeductionRate;

      _commissionTracking = entry.commissionTracking;

      _historyEntryId = entry.id;

      _result = null;

      _view = AppView.main;

      _mainScreenGeneration++;

    });

    _saveDraft();

    _refreshCommissionBalance();

  }



  void _onDraftChanged({

    required String title,

    required List<RowData> rows,

    required Decimal passingRate,

    required Decimal amountDeductionRate,

    required bool commissionTracking,

  }) {

    final titleChanged = title != _title;

    _title = title;

    _rows = rows;

    _passingRate = passingRate;

    _amountDeductionRate = amountDeductionRate;

    _commissionTracking = commissionTracking;

    if (titleChanged) {

      _refreshCommissionBalance();

    }

  }



  Future<void> _onClearCommission() async {

    final ownerId = commissionOwnerId(_title);

    final currentBalance = await _storage.getCommissionBalance(ownerId);

    await _storage.clearCommissionBalance(ownerId);



    setState(() {

      _storedCommissionBalance = Decimal.zero;

      if (_result != null) {

        _result = _result!.copyWith(

          commissionBalance: Decimal.zero,

          storedCommissionBalance: Decimal.zero,

        );

      }

    });



    if (_historyEntryId != null && _result != null) {

      final history = await _storage.loadHistory();

      final index = history.indexWhere((entry) => entry.id == _historyEntryId);

      if (index >= 0) {

        final entry = history[index];

        history[index] = entry.copyWith(

          commissionBalanceAtThatTime: Decimal.zero,

        );

        await _storage.saveHistory(history);

      }

    }



    if (mounted) {

      _scaffoldMessengerKey.currentState?.showSnackBar(

        SnackBar(

          content: Text(

            'Commission balance cleared (${formatMoney(currentBalance, showCurrency: true)})',

          ),

          behavior: SnackBarBehavior.floating,

        ),

      );

    }



    await _saveDraft(lastView: 'results');

  }



  void _handleBackPress() {

    final navigator = HisabProApp.navigatorKey.currentState;

    if (navigator != null && navigator.canPop()) {

      navigator.pop();

      return;

    }



    if (_view == AppView.results) {

      setState(() => _view = AppView.main);

      _saveDraft(lastView: 'main');

      return;

    }



    final now = DateTime.now();

    if (_lastBackPress == null ||

        now.difference(_lastBackPress!) > const Duration(seconds: 2)) {

      _lastBackPress = now;

      _scaffoldMessengerKey.currentState?.showSnackBar(

        const SnackBar(

          content: Text('Press back again to exit'),

          behavior: SnackBarBehavior.floating,

          duration: Duration(seconds: 2),

        ),

      );

      return;

    }



    SystemNavigator.pop();

  }



  Widget _buildShellContent() {

    if (_loading) {

      return const Scaffold(

        body: Center(child: CircularProgressIndicator()),

      );

    }



    if (_view == AppView.results && _result != null) {

      return ResultsScreen(

        storage: _storage,

        persistentHeader: _persistentHeader,

        title: _title,

        rows: _rows,

        result: _result!,

        passingRate: _passingRate,

        amountDeductionRate: _amountDeductionRate,

        commissionTracking: _commissionTracking,

        storedCommissionBalance: _storedCommissionBalance,

        calculatedAt: _resultCalculatedAt ?? DateTime.now(),

        onBack: _onResultsBack,

        onEdit: () {

          setState(() => _view = AppView.main);

          _saveDraft(lastView: 'main');

        },

        onBackWithNewCalculation: () async {

          await _onNewCalculationWithArchive();

        },

        onClearCommission: _result!.commissionTracking

            ? _onClearCommission

            : null,

        onViewHistory: _openHistory,

        onDeleteCalculation: _deleteCurrentCalculation,

      );

    }



    return MainScreen(

      key: ValueKey('main-$_mainScreenGeneration'),

      storage: _storage,

      initialTitle: _title,

      initialPersistentHeader: _persistentHeader,

      initialRows: _rows,

      initialPassingRate: _passingRate,

      initialAmountDeductionRate: _amountDeductionRate,

      initialCommissionTracking: _commissionTracking,

      storedCommissionBalance: _storedCommissionBalance,

      settings: _settings,

      entryNames: _entryNames,

      onDraftChanged: _onDraftChanged,

      onPersistentHeaderChanged: _onPersistentHeaderChanged,

      onCalculate: _onCalculate,

      onNewCalculation: _onNewCalculationWithArchive,

      onSettingsChanged: _onSettingsChanged,

      onOpenHistoryEntry: _loadFromHistory,

      onDeleteHistoryEntry: _onHistoryEntryDeleted,

    );

  }



  @override

  Widget build(BuildContext context) {

    return MaterialApp(

      navigatorKey: HisabProApp.navigatorKey,

      title: 'HisabPro',

      debugShowCheckedModeBanner: false,

      theme: buildAppTheme(),

      darkTheme: buildDarkAppTheme(),

      themeMode: _settings.darkMode ? ThemeMode.dark : ThemeMode.light,

      builder: (context, child) {
        return DismissKeyboard(child: child ?? const SizedBox.shrink());
      },

      home: PopScope(

        canPop: false,

        onPopInvokedWithResult: (didPop, result) {

          if (!didPop) _handleBackPress();

        },

        child: ScaffoldMessenger(

          key: _scaffoldMessengerKey,

          child: _buildShellContent(),

        ),

      ),

    );

  }

}


