import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:hisab_pro/app.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('HisabPro loads groups home screen', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const HisabProApp());
    await tester.pumpAndSettle();

    expect(find.text('Calculations'), findsOneWidget);
    expect(find.text('Add Group'), findsOneWidget);
    expect(find.text('Search groups'), findsOneWidget);
  });
}
