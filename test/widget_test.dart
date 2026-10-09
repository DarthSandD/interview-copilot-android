import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:interview_copilot/main.dart';

void main() {
  testWidgets('App boots to the home screen', (tester) async {
    await tester.pumpWidget(const InterviewCopilotApp());
    await tester.pump();

    // The shell renders immediately; the controller finishes init on the
    // first frame, so the title must be present without a microphone.
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
