// Smoke test for Interview Copilot.
//
// The home screen is a live-transcription surface that requests the
// microphone on first use, so this test only verifies the widget tree builds
// with the expected title.

import 'package:flutter_test/flutter_test.dart';

import 'package:interview_copilot/main.dart';

void main() {
  testWidgets('Home screen renders the app title',
      (WidgetTester tester) async {
    await tester.pumpWidget(const InterviewCopilotApp());

    expect(find.text('Interview Copilot'), findsOneWidget);
  });
}
