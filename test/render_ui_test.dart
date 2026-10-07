// Renders the real UI to PNG files so the layout can be inspected visually.
//
// Run:  flutter test test/render_ui_test.dart --update-goldens
// Output: test/goldens/*.png

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:interview_copilot/main.dart';

void main() {
  // Phone-ish viewport: Pixel-class 412x915 dp.
  const Size phone = Size(412, 915);

  Future<void> boot(WidgetTester tester) async {
    tester.view.physicalSize = phone;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const InterviewCopilotApp());
    await tester.pump(const Duration(milliseconds: 300));
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

  testWidgets('03 listening state', (tester) async {
    await boot(tester);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/03_idle.png'),
    );
  });
}
