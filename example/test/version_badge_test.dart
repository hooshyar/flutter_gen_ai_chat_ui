import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gen_ai_chat_ui_example/main.dart';
import 'package:flutter_gen_ai_chat_ui_example/version_info.dart';

/// Regression coverage for task-021: the home screen's version badge used
/// to be a hand-typed literal (`'v2.14.0'`) that silently drifted from the
/// actual package version for two releases. `packageVersion` is now
/// generated from the package's own pubspec.yaml by
/// `tool/generate_version.dart` — this test fails loudly if someone bumps
/// the version without re-running that generator (and re-committing the
/// regenerated `lib/version_info.dart`), instead of the badge just quietly
/// going stale again.
void main() {
  test('generated packageVersion matches the package pubspec.yaml version',
      () {
    final pubspecContent = File('../pubspec.yaml').readAsStringSync();
    final match = RegExp(r'^version:\s*(\S+)', multiLine: true)
        .firstMatch(pubspecContent);
    expect(match, isNotNull,
        reason: 'Could not find a version: field in ../pubspec.yaml');

    expect(
      packageVersion,
      match!.group(1),
      reason: 'example/lib/version_info.dart is stale — the package version '
          'was bumped without re-running '
          '`dart run tool/generate_version.dart` (from example/).',
    );
  });

  testWidgets('home screen shows the badge derived from packageVersion',
      (tester) async {
    await tester.pumpWidget(const ExampleApp());
    await tester.pump();

    expect(find.text('v$packageVersion'), findsOneWidget);
  });
}
