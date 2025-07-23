import 'package:flutter/material.dart';
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Modern color palette
  static const Color _primaryColor = Color(0xFF0A84FF);
  static const Color _secondaryColor = Color(0xFF5E5CE6);
  static const Color _accentColor = Color(0xFF30D158);
  static const Color _dangerColor = Color(0xFFFF453A);
  // Removed unused color constants for lint compliance
  // static const Color _warningColor = Color(0xFFFFD60A);
  // static const Color _infoColor = Color(0xFF64D2FF);

  // Light theme colors
  static const Color _lightBackgroundColor = Color(0xFFF2F2F7);
  static const Color _lightSurfaceColor = Colors.white;
  static const Color _lightOnSurfaceColor = Color(0xFF1C1C1E);

  // Dark theme colors
  static const Color _darkBackgroundColor = Color(0xFF000000);
  static const Color _darkSurfaceColor = Color(0xFF1C1C1E);
  static const Color _darkElevatedSurfaceColor = Color(0xFF2C2C2E);
  static const Color _darkOnSurfaceColor = Color(0xFFF2F2F7);

  // Light theme extension for the chat UI
  static final CustomThemeExtension lightThemeExtension = CustomThemeExtension(
    chatBackground: const Color(0xFFF2F2F7),
    messageBubbleColor: Colors.white,
    userBubbleColor: const Color(0xFFE1F0FF),
    messageTextColor: const Color(0xFF1C1C1E),
    inputBackgroundColor: Colors.white,
    inputBorderColor: Colors.grey[300],
    inputTextColor: const Color(0xFF1C1C1E),
    hintTextColor: Colors.grey[500],
    backToBottomButtonColor: Colors.white,
    sendButtonColor: _primaryColor,
    sendButtonIconColor: Colors.white,
  );

  // Dark theme extension for the chat UI
  static final CustomThemeExtension darkThemeExtension = CustomThemeExtension(
    chatBackground: const Color(0xFF000000),
    messageBubbleColor: const Color(0xFF2C2C2E),
    userBubbleColor: const Color(0xFF0A3464),
    messageTextColor: Colors.white,
    inputBackgroundColor: const Color(0xFF1C1C1E),
    inputBorderColor: const Color(0xFF2C2C2E),
    inputTextColor: Colors.white,
    hintTextColor: Colors.grey[400],
    backToBottomButtonColor: const Color(0xFF2C2C2E),
    sendButtonColor: _primaryColor,
    sendButtonIconColor: Colors.white,
  );

  // Light theme
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: _primaryColor,
    scaffoldBackgroundColor: _lightBackgroundColor,
    colorScheme: const ColorScheme.light(
      primary: _primaryColor,
      secondary: _secondaryColor,
      tertiary: _accentColor,
      surface: _lightSurfaceColor,
      error: _dangerColor,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: _lightOnSurfaceColor,
      onError: Colors.white,
    ),
    appBarTheme: AppBarTheme(
      elevation: 0,
      centerTitle: true,
      backgroundColor: _lightBackgroundColor,
      foregroundColor: _lightOnSurfaceColor,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: GoogleFonts.inter(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: _lightOnSurfaceColor,
      ),
    ),
    cardTheme: CardTheme(
      elevation: 3,
      shadowColor: Colors.black.withOpacityCompat(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: _primaryColor,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: CircleBorder(),
    ),
    iconTheme: const IconThemeData(color: _lightOnSurfaceColor),
    dividerTheme: const DividerThemeData(
      color: Color(0xFFE5E5EA),
      thickness: 1,
      space: 1,
    ),
    navigationBarTheme: NavigationBarThemeData(
      indicatorColor: _primaryColor.withOpacityCompat(0.12),
      backgroundColor: _lightSurfaceColor,
      elevation: 3,
      shadowColor: Colors.black.withOpacityCompat(0.05),
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      iconTheme: WidgetStateProperty.all(
        const IconThemeData(size: 24),
      ),
    ),
    textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme).copyWith(
      headlineLarge: GoogleFonts.inter(
        fontWeight: FontWeight.bold,
        fontSize: 28,
      ),
      headlineMedium: GoogleFonts.inter(
        fontWeight: FontWeight.bold,
        fontSize: 24,
      ),
      titleLarge: GoogleFonts.inter(
        fontWeight: FontWeight.w600,
        fontSize: 20,
      ),
      titleMedium: GoogleFonts.inter(
        fontWeight: FontWeight.w600,
        fontSize: 16,
      ),
      bodyLarge: GoogleFonts.inter(
        fontWeight: FontWeight.normal,
        fontSize: 16,
      ),
      bodyMedium: GoogleFonts.inter(
        fontWeight: FontWeight.normal,
        fontSize: 14,
      ),
    ),
    extensions: [lightThemeExtension],
  );

  // Dark theme
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: _primaryColor,
    scaffoldBackgroundColor: _darkBackgroundColor,
    colorScheme: const ColorScheme.dark(
      primary: _primaryColor,
      secondary: _secondaryColor,
      tertiary: _accentColor,
      surface: _darkSurfaceColor,
      error: _dangerColor,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: _darkOnSurfaceColor,
      onError: Colors.white,
    ),
    appBarTheme: AppBarTheme(
      elevation: 0,
      centerTitle: true,
      backgroundColor: _darkBackgroundColor,
      foregroundColor: _darkOnSurfaceColor,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: GoogleFonts.inter(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: _darkOnSurfaceColor,
      ),
    ),
    cardTheme: CardTheme(
      elevation: 6,
      shadowColor: Colors.black.withOpacityCompat(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: _darkElevatedSurfaceColor,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: _primaryColor,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: CircleBorder(),
    ),
    iconTheme: const IconThemeData(color: _darkOnSurfaceColor),
    dividerTheme: const DividerThemeData(
      color: Color(0xFF38383A),
      thickness: 1,
      space: 1,
    ),
    navigationBarTheme: NavigationBarThemeData(
      indicatorColor: _primaryColor.withOpacityCompat(0.2),
      backgroundColor: _darkSurfaceColor,
      elevation: 3,
      shadowColor: Colors.black.withOpacityCompat(0.2),
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      iconTheme: WidgetStateProperty.all(
        const IconThemeData(size: 24),
      ),
    ),
    textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
      headlineLarge: GoogleFonts.inter(
        fontWeight: FontWeight.bold,
        fontSize: 28,
      ),
      headlineMedium: GoogleFonts.inter(
        fontWeight: FontWeight.bold,
        fontSize: 24,
      ),
      titleLarge: GoogleFonts.inter(
        fontWeight: FontWeight.w600,
        fontSize: 20,
      ),
      titleMedium: GoogleFonts.inter(
        fontWeight: FontWeight.w600,
        fontSize: 16,
      ),
      bodyLarge: GoogleFonts.inter(
        fontWeight: FontWeight.normal,
        fontSize: 16,
      ),
      bodyMedium: GoogleFonts.inter(
        fontWeight: FontWeight.normal,
        fontSize: 14,
      ),
    ),
    extensions: [darkThemeExtension],
  );
}
