import 'package:flutter/material.dart';
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';

void main() {
  // Test the color extension
  const Color color = Colors.blue;
  final Color withAlpha = color.withOpacityCompat(0.5);
  final Color withRed = color.withValues(red: 128);
  final Color withGreen = color.withValues(green: 200);
  final Color withBlue = color.withValues(blue: 50);
  final Color withMultiple =
      color.withValues(red: 255, green: 128, blue: 64).withOpacityCompat(0.8);

  // Test values (removed print statements for production code)
  // You can use these values in your application as needed
  // Original color: $color
  // With alpha 0.5: $withAlpha
  // With red 128: $withRed
  // With green 200: $withGreen
  // With blue 50: $withBlue
  // With multiple changes: $withMultiple
}
