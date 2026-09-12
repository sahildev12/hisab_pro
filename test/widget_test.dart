import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:hisab_pro/app.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('HisabPro loads without settlement toggle', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const HisabProApp());
    await tester.pumpAndSettle();

    expect(find.textContaining('Hisab'), findsOneWidget);
    expect(find.text('Fast • Accurate • Always Yours'), findsOneWidget);
    expect(find.text('Lene h'), findsNothing);
    expect(find.text('Dene h'), findsNothing);
    expect(find.text('Calculation Rates'), findsOneWidget);
    expect(find.text('Passing Rate'), findsOneWidget);
    expect(find.text('Amount Deduction'), findsOneWidget);
    expect(find.text('Calculate'), findsOneWidget);
  });
}
