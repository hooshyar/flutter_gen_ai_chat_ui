import 'package:flutter_test/flutter_test.dart';

/// Regression coverage for the dangling-marker withholding used by
/// CustomChatWidget while a markdown message streams in (mirrors
/// `test/widgets/streaming_fence_stability_test.dart`'s approach: the
/// transform is private to `_CustomChatWidgetState`, so this reimplements
/// it verbatim and asserts the property the streaming widget depends on).
///
/// Without this, a partially-revealed chunk that ends right after a bare
/// list/heading/blockquote marker (e.g. "...text\n-" or "...text\n##")
/// renders as an empty bullet point / heading / blockquote for one frame
/// before its content arrives — a visible flash the reveal is supposed to
/// avoid (`DESIGN.md` §7's whole point is that streaming never shows
/// half-formed structure).
final RegExp _danglingMarkerLine = RegExp(
  r'(^|\n)[ \t]*(?:[-*+]|\d+\.|#{1,6}|>)[ \t]*$',
);

String withholdDanglingMarker(String text) {
  final match = _danglingMarkerLine.firstMatch(text);
  if (match == null) return text;
  final cut = match.group(1) == '\n' ? match.start + 1 : match.start;
  return text.substring(0, cut);
}

void main() {
  group('withholdDanglingMarker', () {
    test('passes through plain text with no trailing marker', () {
      expect(withholdDanglingMarker('Hello world'), 'Hello world');
    });

    test('passes through a list item that already has content', () {
      const text = 'Intro\n- first point';
      expect(withholdDanglingMarker(text), text);
    });

    test('withholds a bare trailing "-" bullet with no content yet', () {
      // Cuts right after the newline (not before it), so the held value
      // only ever extends as more text streams in — see the prefix-
      // extension test below.
      expect(withholdDanglingMarker('Intro\n-'), 'Intro\n');
    });

    test('withholds a bare trailing "*" bullet with no content yet', () {
      expect(withholdDanglingMarker('Intro\n* '), 'Intro\n');
    });

    test('withholds a bare trailing ordered-list marker', () {
      expect(withholdDanglingMarker('Intro\n1.'), 'Intro\n');
    });

    test('withholds a bare trailing heading marker', () {
      expect(withholdDanglingMarker('Intro\n##'), 'Intro\n');
    });

    test('withholds a bare trailing blockquote marker', () {
      expect(withholdDanglingMarker('Intro\n>'), 'Intro\n');
    });

    test(
        'withholds a bare marker at the very start of the text (no '
        'preceding newline)', () {
      expect(withholdDanglingMarker('-'), '');
      expect(withholdDanglingMarker('##'), '');
    });

    test(
        'held value only ever extends as the marker gains content — never '
        'edits, only extends', () {
      final growingChunks = [
        'Here are some points:\n',
        'Here are some points:\n-',
        'Here are some points:\n- first',
        'Here are some points:\n- first\n-',
        'Here are some points:\n- first\n- second',
      ];

      String? previous;
      for (final chunk in growingChunks) {
        final held = withholdDanglingMarker(chunk);
        if (previous != null) {
          expect(
            held.startsWith(previous!),
            isTrue,
            reason: 'Held output was not a prefix-extension going from '
                '"$previous" to "$held"',
          );
        }
        previous = held;
      }
    });
  });
}
