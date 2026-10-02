// Example-app design tokens and `ThemeData`, straight from DESIGN.md §3.
//
// These are the example app's own colours - deliberately independent from
// the package's `ChatTokens` (added in a parallel slice) so this shell never
// depends on in-flight package API. Package defaults still come from the
// host `Theme`/`ColorScheme` built here, so the example continues to show
// the package looking right without any bespoke chat styling.
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Example-app colour tokens, DESIGN.md §3.
///
/// Not exported by the package - this is example-app-only styling, matched
/// by hand to the design direction rather than sourced from `ChatTokens`.
class AppColors {
  const AppColors._({
    required this.canvas,
    required this.surface,
    required this.surfaceSunken,
    required this.border,
    required this.borderStrong,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.accent,
    required this.onAccent,
    required this.codeBg,
    required this.codeBorder,
  });

  final Color canvas;
  final Color surface;
  final Color surfaceSunken;
  final Color border;
  final Color borderStrong;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color accent;
  final Color onAccent;
  final Color codeBg;
  final Color codeBorder;

  static const light = AppColors._(
    canvas: Color(0xFFFBFBFA),
    surface: Color(0xFFFFFFFF),
    surfaceSunken: Color(0xFFF3F3F1),
    border: Color(0xFFE4E4E2),
    borderStrong: Color(0xFF85858D),
    textPrimary: Color(0xFF18181B),
    textSecondary: Color(0xFF52525B),
    textTertiary: Color(0xFF6B6B73),
    accent: Color(0xFF2450D6),
    onAccent: Color(0xFFFFFFFF),
    codeBg: Color(0xFFF6F6F4),
    codeBorder: Color(0xFFE4E4E2),
  );

  static const dark = AppColors._(
    canvas: Color(0xFF111113),
    surface: Color(0xFF18181B),
    surfaceSunken: Color(0xFF1C1C1F),
    border: Color(0xFF2A2A2F),
    borderStrong: Color(0xFF6A6A72),
    textPrimary: Color(0xFFEDEDEF),
    textSecondary: Color(0xFFA8A8B0),
    textTertiary: Color(0xFF8C8C94),
    accent: Color(0xFF8AA8FF),
    onAccent: Color(0xFF111113),
    codeBg: Color(0xFF161618),
    codeBorder: Color(0xFF2A2A2F),
  );

  /// Resolves the token set from ambient [Brightness].
  static AppColors of(Brightness brightness) =>
      brightness == Brightness.dark ? dark : light;
}

/// Builds the example app's `ThemeData` from [AppColors], per DESIGN.md §9.
class AppTheme {
  const AppTheme._();

  static ThemeData light() => _build(AppColors.light, Brightness.light);

  static ThemeData dark() => _build(AppColors.dark, Brightness.dark);

  static ThemeData _build(AppColors tokens, Brightness brightness) {
    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: tokens.accent,
      onPrimary: tokens.onAccent,
      secondary: tokens.accent,
      onSecondary: tokens.onAccent,
      error: brightness == Brightness.dark
          ? const Color(0xFFFF7A66)
          : const Color(0xFFC4321C),
      onError: tokens.onAccent,
      surface: tokens.canvas,
      onSurface: tokens.textPrimary,
      outline: tokens.border,
      outlineVariant: tokens.border,
    );

    final baseTextTheme = GoogleFonts.geistTextTheme(
      brightness == Brightness.dark
          ? ThemeData.dark().textTheme
          : ThemeData.light().textTheme,
    ).apply(
      bodyColor: tokens.textPrimary,
      displayColor: tokens.textPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: tokens.canvas,
      textTheme: baseTextTheme,
      appBarTheme: const AppBarTheme(
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
      ),
      dividerColor: tokens.border,
    );
  }
}

/// Convenience accessor: `context.appColors` instead of threading
/// `AppColors.of(Theme.of(context).brightness)` through every widget.
extension AppColorsContext on BuildContext {
  AppColors get appColors => AppColors.of(Theme.of(this).brightness);
}
