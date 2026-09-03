// Regenerates example/lib/version_info.dart from the package's own
// pubspec.yaml `version:` field, so the example app's version badge can
// never silently drift from what's actually published (task-021: the
// badge sat at a hardcoded 'v2.14.0' for two releases because it was a
// typed literal). Run this after bumping the package version — it also
// runs automatically in CI before every web-demo build (see
// .github/workflows/deploy-web-demo.yml).
//
// Usage (from the repo root or from example/): dart run tool/generate_version.dart
import 'dart:io';

void main() {
  final scriptDir = File(Platform.script.toFilePath()).parent;
  final pubspecFile = File('${scriptDir.path}/../../pubspec.yaml');
  final outputFile = File('${scriptDir.path}/../lib/version_info.dart');

  final pubspecContent = pubspecFile.readAsStringSync();
  final match =
      RegExp(r'^version:\s*(\S+)', multiLine: true).firstMatch(pubspecContent);
  if (match == null) {
    stderr.writeln('Could not find a version: field in ${pubspecFile.path}');
    exit(1);
  }
  final version = match.group(1)!;

  outputFile.writeAsStringSync('''
// GENERATED FILE. DO NOT EDIT BY HAND.
//
// Regenerate with: dart run tool/generate_version.dart
// (also runs automatically in CI before the web demo is built — see
// .github/workflows/deploy-web-demo.yml)

/// The published version of `flutter_gen_ai_chat_ui`, read from the
/// package's own pubspec.yaml at generation time.
const String packageVersion = '$version';
''');

  stdout.writeln('Wrote ${outputFile.path}: packageVersion = $version');
}
