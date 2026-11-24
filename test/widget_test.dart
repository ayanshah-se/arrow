import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:arrows/features/game/data/progress_service.dart';
import 'package:arrows/main.dart';
import 'package:arrows/app/routes/app_pages.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await progressService.initialize();
    Get.testMode = true;
  });

  tearDown(Get.reset);

  testWidgets('home screen loads', (tester) async {
    await tester.pumpWidget(const ArrowEscapeApp());
    await tester.pumpAndSettle();

    expect(find.text('Arrow Escape'), findsOneWidget);
    expect(find.text('Play'), findsOneWidget);
  });

  testWidgets('play navigates to game start', (tester) async {
    await tester.pumpWidget(const ArrowEscapeApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Play'));
    await tester.pumpAndSettle();

    expect(Get.currentRoute, AppPages.game);
    expect(find.text('Play now'), findsOneWidget);
  });
}
