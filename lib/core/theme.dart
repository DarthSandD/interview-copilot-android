import 'package:flutter/material.dart';

/// Design tokens for Interview Copilot.
///
/// Every colour, radius and duration used by the UI lives here so the visual
/// language stays consistent and can be changed in one place.
abstract final class AppColors {
  static const bg = Color(0xFF0A0D13);
  static const panel = Color(0xFF161C26);
  static const panelAlt = Color(0xFF1E2632);
  static const fg = Color(0xFFEEF3FA);
  static const dim = Color(0xFF8395AA);
  static const dim2 = Color(0xFF5F7086);
  static const them = Color(0xFF5AA9FF);
  static const you = Color(0xFF4ADE80);
  static const hot = Color(0xFFFF5F7E);
  static const live = Color(0xFFC2D5EA);
  static const line = Color(0x14FFFFFF);

  /// Brand gradient used by the header badge and primary button.
  static const brandGradient = LinearGradient(
    colors: [Color(0xFF5EB0FF), Color(0xFFA78BFA), Color(0xFFF472B6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const actionGradient = LinearGradient(
    colors: [Color(0xFF5EB0FF), Color(0xFF7C6BF5)],
  );

  static const stopGradient = LinearGradient(
    colors: [Color(0xFFFF5F7E), Color(0xFFE0405F)],
  );
}

abstract final class AppRadii {
  static const bubble = 13.0;
  static const panel = 13.0;
  static const chip = 10.0;
  static const badge = 9.0;
  static const pill = 24.0;
}

abstract final class AppDurations {
  static const fast = Duration(milliseconds: 180);
  static const normal = Duration(milliseconds: 220);
  static const slow = Duration(milliseconds: 260);
  static const pulse = Duration(milliseconds: 1600);
}

/// App-wide theme built from the tokens above.
ThemeData buildAppTheme() {
  return ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.them,
      surface: AppColors.panel,
    ),
    useMaterial3: true,
    splashFactory: NoSplash.splashFactory,
  );
}
