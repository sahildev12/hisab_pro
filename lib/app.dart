import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/calculate.dart';
import 'core/storage.dart';
import 'screens/groups_home_screen.dart';
import 'theme/app_theme.dart';
import 'widgets/dismiss_keyboard.dart';

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
  DateTime? _lastBackPress;
  AppSettings _settings = AppSettings(
    defaultPassingRate: defaultPassingRate,
    defaultAmountDeductionRate: defaultAmountDeductionRate,
  );

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await _storage.loadSettings();
    if (!mounted) return;
    setState(() {
      _settings = settings;
      _loading = false;
    });
  }

  Future<void> _onSettingsChanged(AppSettings settings) async {
    await _storage.saveSettings(settings);
    setState(() => _settings = settings);
  }

  void _handleBackPress() {
    final navigator = HisabProApp.navigatorKey.currentState;
    if (navigator != null && navigator.canPop()) {
      navigator.pop();
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
          child: _loading
              ? const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                )
              : GroupsHomeScreen(
                  storage: _storage,
                  settings: _settings,
                  onSettingsChanged: _onSettingsChanged,
                ),
        ),
      ),
    );
  }
}
