// Cheap doc/code drift guard for this package's documentation.
//
// The 2026 ONBOARDING_AUDIT found hand-written example snippets in
// AGENTS.md and class-level dartdoc that called methods/factories that no
// longer existed on the actual public API — a first-contact bug for
// anyone copy-pasting from the docs. Fixed by hand once; this script turns
// "caught eventually by a manual audit" into "caught automatically in CI."
//
// README/AGENTS snippets are illustrative, not standalone compilation
// units (they use `// ...` elisions, omit imports, live inside implied
// `build()` bodies) — running a full `dart analyze` over them would be
// both too strict (false positives on intentionally-partial snippets) and
// too slow to set up reliably. Instead this does the sharp, low-noise
// check that would have actually caught the real incident: every
// `ClassName.identifier(` call site in a ```dart fence — a factory/named
// constructor (`ChatMessage.rich(`), a static preset builder
// (`CustomThemeExtension.chatgpt(`), or a static accessor
// (`AiActionProvider.of(`) — must resolve to a real member declared
// inside that class's body in lib/. Plain `ClassName(` calls are checked
// against the class merely existing. Classes not defined in this
// package's lib/ (Text, Container, Duration, ...) are ignored entirely,
// so this never flags Flutter/Dart SDK usage.
import 'dart:io';

/// Extracts the brace-balanced body of the first `class|mixin|enum
/// $name` declaration found in [source], or null if not found.
String? extractTypeBody(String source, String name) {
  final header =
      RegExp('(class|mixin|enum)\\s+$name\\b[^{]*\\{').firstMatch(source);
  if (header == null) return null;
  var depth = 1;
  var i = header.end;
  final start = i;
  while (i < source.length && depth > 0) {
    final c = source[i];
    if (c == '{') depth++;
    if (c == '}') depth--;
    i++;
  }
  return source.substring(start, i - 1);
}

void main() {
  final libSource = StringBuffer();
  for (final entity
      in Directory('lib').listSync(recursive: true).whereType<File>()) {
    if (entity.path.endsWith('.dart')) {
      libSource.writeln(entity.readAsStringSync());
    }
  }
  final lib = libSource.toString();
  final classBodyCache = <String, String?>{};
  String? bodyOf(String className) => classBodyCache.putIfAbsent(
      className, () => extractTypeBody(lib, className));

  final docFiles = ['README.md', 'AGENTS.md'];
  final callPattern =
      RegExp(r'\b([A-Z][A-Za-z0-9_]*)(\.([a-zA-Z_][A-Za-z0-9_]*))?\s*\(');
  final failures = <String>[];
  var checkedCallSites = 0;
  var checkedFiles = 0;

  for (final path in docFiles) {
    final file = File(path);
    if (!file.existsSync()) continue;
    checkedFiles++;
    final content = file.readAsStringSync();
    final dartBlocks =
        RegExp(r'```dart\n([\s\S]*?)```').allMatches(content).map((m) {
      final startLine = content.substring(0, m.start).split('\n').length;
      return (startLine, m.group(1)!);
    });

    for (final (startLine, block) in dartBlocks) {
      for (final match in callPattern.allMatches(block)) {
        final className = match.group(1)!;
        final member = match.group(3);

        final classBody = bodyOf(className);
        final isOurClass = classBody != null ||
            lib.contains('class $className') ||
            lib.contains('enum $className') ||
            lib.contains('mixin $className');
        if (!isOurClass) continue;

        checkedCallSites++;

        if (member == null) {
          continue; // Default constructor — class existing is enough.
        }

        // Resolve against members declared INSIDE this specific class's
        // body (not "the substring appears anywhere in lib/", which would
        // also match stale mentions inside doc comments or same-named
        // members on unrelated classes, masking exactly the drift this
        // script exists to catch).
        final scope = classBody ?? lib;
        final memberEscaped = RegExp.escape(member);
        final resolvesAsMember =
            RegExp('factory\\s+$className\\.$memberEscaped\\s*\\(')
                    .hasMatch(scope) ||
                RegExp('const\\s+$className\\.$memberEscaped\\s*\\(')
                    .hasMatch(scope) ||
                // Any static method of this name, regardless of return
                // type — covers both same-type preset builders
                // (`static Foo bar(`) and cross-type accessors
                // (`static Controller of(`).
                RegExp('static[^;{}]*?\\b$memberEscaped\\s*\\(')
                    .hasMatch(scope);
        if (!resolvesAsMember) {
          final approxLine = startLine +
              block.substring(0, match.start).split('\n').length -
              1;
          failures.add(
            '$path:$approxLine — `$className.$member(...)` does not resolve to '
            'any factory/named/static member declared on $className in lib/. '
            'Either the docs are stale or `$member` was renamed/removed.',
          );
        }
      }
    }
  }

  stdout.writeln(
    'doc-drift: scanned $checkedFiles doc file(s), '
    'checked $checkedCallSites call site(s) against this package\'s classes.',
  );

  if (failures.isNotEmpty) {
    stderr
        .writeln('\ndoc-drift: found ${failures.length} stale reference(s):\n');
    for (final f in failures) {
      stderr.writeln('  - $f');
    }
    exit(1);
  }

  stdout.writeln(
      'doc-drift: no stale factory/named/static-member references found.');
}
