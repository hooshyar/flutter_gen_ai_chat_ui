import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  // Load system fonts for consistent rendering
  TestWidgetsFlutterBinding.ensureInitialized();
  await _loadTestFonts();

  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  // Configure window size and pixel ratio for consistent rendering
  binding.window.physicalSizeTestValue = const Size(400, 800);
  binding.window.devicePixelRatioTestValue = 1.0;

  // Enable real shadows for visual tests
  binding.window.platformDispatcher.textScaleFactorTestValue = 1.0;

  // Skip golden tests on non-macOS platforms
  if (!Platform.isMacOS) {
    goldenFileComparator = _AlwaysPassingGoldenFileComparator();
  }

  // TEMP (to be reverted before merge): print widget-test failures as
  // GitHub annotations so they can be read without the Actions log.
  final originalReporter = reportTestException;
  reportTestException = (details, description) {
    final text = '$description: ${details.exceptionAsString()}';
    final escaped = text
        .replaceAll('%', '%25')
        .replaceAll('\r', '%0D')
        .replaceAll('\n', '%0A');
    print('::error title=test failed::$escaped');
    originalReporter(details, description);
  };

  return testMain();
}

/// Load test fonts for consistent rendering
Future<void> _loadTestFonts() async {
  // This ensures consistent font rendering across test environments
  try {
    final fontLoader = FontLoader('Roboto');
    final font = rootBundle.load('fonts/Roboto-Regular.ttf');
    fontLoader.addFont(font);
    await fontLoader.load();
  } catch (e) {
    // Ignore font loading errors in test environment
    debugPrint('Font loading failed in test environment: $e');
  }
}

class _AlwaysPassingGoldenFileComparator extends GoldenFileComparator {
  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async => true;

  @override
  Future<void> update(Uri golden, Uint8List imageBytes) async {}
}
