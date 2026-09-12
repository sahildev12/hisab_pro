import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:hisab_pro/app.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('HisabPro app loads with premium design', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const HisabProApp());
    await tester.pumpAndSettle();

    expect(find.text('Hisab'), findsOneWidget);
    expect(find.text('Pro'), findsOneWidget);
    expect(find.text('Start a New Hisab'), findsOneWidget);
    expect(find.text('Calculate'), findsOneWidget);
  });
}
