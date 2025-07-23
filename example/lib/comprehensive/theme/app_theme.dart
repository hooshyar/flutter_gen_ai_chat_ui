import 'package:flutter/material.dart';
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';
import 'package:google_fonts/google_fonts.dart';

/// Theme configuration for the comprehensive AI Chat example
class AppTheme {
  // Color palette
  static const Color primaryColor = Color(0xFF7C4DFF);
  static const Color secondaryColor = Color(0xFF03DAC6);
  static const Color errorColor = Color(0xFFCF6679);

  // Light theme colors
  static const Color lightBg = Color(0xFFF8F9FA);
  static const Color lightSurface = Colors.white;
  static const Color lightOnSurface = Color(0xFF1D1D1D);
  static const Color lightSurfaceVariant = Color(0xFFF0F0F0);

  // Dark theme colors
  static const Color darkBg = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkOnSurface = Color(0xFFF1F1F1);
  static const Color darkSurfaceVariant = Color(0xFF2A2A2A);

  // Light theme extension for the chat UI
  static const CustomThemeExtension lightThemeExtension = CustomThemeExtension(
    chatBackground: lightBg,
    messageBubbleColor: lightSurfaceVariant,
    userBubbleColor: Color(0xFFE6E4FD),
    messageTextColor: lightOnSurface,
    inputBackgroundColor: lightSurface,
    inputBorderColor: Color(0xFFE0E0E0),
    inputTextColor: lightOnSurface,
    hintTextColor: Color(0xFF9E9E9E),
    backToBottomButtonColor: Color(0xFFEDEDED),
    sendButtonColor: primaryColor,
    sendButtonIconColor: Colors.white,
  );

  // Dark theme extension for the chat UI
  static const CustomThemeExtension darkThemeExtension = CustomThemeExtension(
    chatBackground: darkBg,
    messageBubbleColor: darkSurfaceVariant,
    userBubbleColor: Color(0xFF36307D),
    messageTextColor: darkOnSurface,
    inputBackgroundColor: darkSurface,
    inputBorderColor: Color(0xFF3A3A3A),
    inputTextColor: darkOnSurface,
    hintTextColor: Color(0xFFAAAAAA),
    backToBottomButtonColor: Color(0xFF333333),
    sendButtonColor: primaryColor,
    sendButtonIconColor: Colors.white,
  );

  // Define light theme
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: primaryColor,
      secondary: secondaryColor,
      surface: lightSurface,
      error: errorColor,
      onPrimary: Colors.white,
      onSecondary: Colors.black,
      onSurface: lightOnSurface,
      onError: Colors.white,
    ),
    scaffoldBackgroundColor: lightBg,
    textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
    appBarTheme: const AppBarTheme(
      elevation: 0,
      color: lightSurface,
      foregroundColor: lightOnSurface,
      centerTitle: true,
    ),
    cardTheme: CardTheme(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: lightSurface,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: lightSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      filled: true,
      fillColor: lightSurfaceVariant,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    extensions: const [lightThemeExtension],
  );

  // Define dark theme
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: primaryColor,
      secondary: secondaryColor,
      surface: darkSurface,
      error: errorColor,
      onPrimary: Colors.white,
      onSecondary: Colors.black,
      onSurface: darkOnSurface,
      onError: Colors.black,
    ),
    scaffoldBackgroundColor: darkBg,
    textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
    appBarTheme: const AppBarTheme(
      elevation: 0,
      color: darkSurface,
      foregroundColor: darkOnSurface,
      centerTitle: true,
    ),
    cardTheme: CardTheme(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: darkSurface,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: darkSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      filled: true,
      fillColor: darkSurfaceVariant,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    extensions: const [darkThemeExtension],
  );
}
