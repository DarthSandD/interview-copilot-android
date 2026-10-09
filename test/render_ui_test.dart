// Renders the real UI to PNG files so the layout can be inspected visually.
//
// The record/whisper plugins have no test implementations, so the platform
// channels are mocked with no-ops. The controller degrades gracefully and
// the widget tree still renders — which is exactly what we are verifying.
//
// Run:  flutter test test/render_ui_test.dart --update-goldens
// Output: test/goldens/*.png

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:interview_copilot/main.dart';

void main() {
  // Phone-ish viewport: Pixel-class 412x915 dp.
  const Size phone = Size(412, 915);

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    // No-op every plugin channel the app touches during boot.
    const channels = [
      'com.llfbandit.record/messages',
      'plugins.flutter.io/shared_preferences',
      'dev.fluttercommunity.plus/wakelock_plus',
    ];
    for (final ch in channels) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(MethodChannel(ch), (call) async {
        switch (call.method) {
          case 'getAll':
          case 'load':
            return <String, Object>{};
          default:
            return null;
        }
      });
    }
  });

  Future<void> boot(WidgetTester tester) async {
    tester.view.physicalSize = phone;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const InterviewCopilotApp());
    // Let the controller's async init settle and the first frame land.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets('01 empty state', (tester) async {
    await boot(tester);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/01_empty.png'),
    );
  });

  testWidgets('02 notes tab', (tester) async {
    await boot(tester);
    await tester.tap(find.text('My Notes'));
    await tester.pump(const Duration(milliseconds: 300));
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/02_notes.png'),
    );
  });
}
