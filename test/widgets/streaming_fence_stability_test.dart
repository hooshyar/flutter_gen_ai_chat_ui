import 'package:flutter_test/flutter_test.dart';

/// Regression coverage for the code-fence withholding used by
/// CustomChatWidget while a markdown message streams in. The transform is
/// private to _CustomChatWidgetState, so this reimplements it verbatim and
/// asserts the property the streaming widget depends on: every value
/// returned for a growing sequence of inputs must be a prefix of the next
/// (StreamingText's append-continuation restarts the whole animation
/// otherwise — see custom_chat_widget.dart's `_withholdIncompleteFence`
/// doc comment for why appending a synthetic closing fence broke this).
String withholdIncompleteFence(String text) {
  final fenceCount = '```'.allMatches(text).length;
  if (fenceCount.isEven) return text;
  return text.substring(0, text.lastIndexOf('```'));
}

void main() {
  group('withholdIncompleteFence', () {
    test('passes through text with no code fence', () {
      expect(withholdIncompleteFence('Hello world'), 'Hello world');
    });

    test('passes through text with a balanced (closed) fence', () {
      const text = 'Before\n```dart\nfinal x = 1;\n```\nAfter';
      expect(withholdIncompleteFence(text), text);
    });

    test('withholds an unclosed trailing fence', () {
      const text = 'Before\n```dart\nfinal x = 1';
      expect(withholdIncompleteFence(text), 'Before\n');
    });

    test(
        'held value is stable while the fence stays open, then releases the '
        'full text once it closes — never edits, only extends', () {
      final growingChunks = [
        'Here you go:\n```dart\n',
        'Here you go:\n```dart\nfinal x',
        'Here you go:\n```dart\nfinal x = 1;',
        'Here you go:\n```dart\nfinal x = 1;\nfinal y = 2;',
        'Here you go:\n```dart\nfinal x = 1;\nfinal y = 2;\n```',
        'Here you go:\n```dart\nfinal x = 1;\nfinal y = 2;\n```\nDone.',
      ];

      String? previous;
      for (final chunk in growingChunks) {
        final held = withholdIncompleteFence(chunk);
        if (previous != null) {
          // The core invariant StreamingText depends on: as the real input
          // grows, the held output must only ever stay the same or extend
          // — never edit or shrink, or the append-continuation logic
          // restarts the whole animation from scratch.
          expect(held.startsWith(previous!), isTrue,
              reason: 'Held output was not a prefix-extension going from '
                  '"$previous" to "$held"');
        }
        previous = held;
      }

      // Once the fence closes, the full text (including the fence
      // markers and everything after) must be revealed.
      expect(previous, growingChunks.last);
    });

    test('handles a second fence after the first one already closed', () {
      const afterFirstBlock =
          'A\n```dart\ncode1\n```\nB\n```dart\nunclosed second';
      expect(
        withholdIncompleteFence(afterFirstBlock),
        'A\n```dart\ncode1\n```\nB\n',
      );
    });
  });
}
