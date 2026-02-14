import 'package:flutter/material.dart';

/// Utility for detecting RTL locales and resolving text direction.
class LocaleHelper {
  static bool isRTL(final BuildContext context) {
    final locale = Localizations.localeOf(context);
    final rtlLanguages = ['ar', 'ku', 'fa', 'ur'];
    return rtlLanguages.contains(locale.languageCode);
  }
}
