import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'core/logger.dart';
import 'core/theme.dart';
import 'screens/home_screen.dart';

void main() {
  // Never let a framework error take the app down mid-interview: log it
  // through the redacting logger and keep the UI alive.
  runZonedGuarded(
    () {
      WidgetsFlutterBinding.ensureInitialized();

      FlutterError.onError = (details) {
        // Log the exception only — details.context can carry widget text.
        Log.e('flutter.error', details.exception, details.stack);
        if (kDebugMode) FlutterError.presentError(details);
      };

      ErrorWidget.builder = (details) => const _QuietErrorBox();

      runApp(const InterviewCopilotApp());
    },
    (error, stack) => Log.e('zone.error', error, stack),
  );
}

class InterviewCopilotApp extends StatelessWidget {
  const InterviewCopilotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Interview Copilot',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const HomeScreen(),
      // The app is English-only; declaring it avoids locale-driven layout
      // surprises on devices set to a right-to-left language.
      locale: const Locale('en'),
      supportedLocales: const [Locale('en')],
    );
  }
}

/// Replaces the red error screen in release builds.
///
/// Flutter's default error widget renders the exception text, which could
/// contain transcript content. This one shows nothing sensitive.
class _QuietErrorBox extends StatelessWidget {
  const _QuietErrorBox();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.bg,
      child: Center(
        child: Text(
          'Something went wrong',
          style: TextStyle(color: AppColors.dim, fontSize: 12),
        ),
      ),
    );
  }
}
