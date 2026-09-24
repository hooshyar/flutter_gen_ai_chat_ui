import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const me = ChatUser(id: 'user', name: 'Me');
  const ai = ChatUser(id: 'ai', name: 'Assistant');

  ChatMessage msg(
    ChatUser user,
    String text, {
    DateTime? createdAt,
    String? id,
    bool isMarkdown = false,
  }) {
    return ChatMessage(
      text: text,
      user: user,
      createdAt: createdAt ?? DateTime(2026, 1, 1),
      isMarkdown: isMarkdown,
      customProperties: {if (id != null) 'id': id},
    );
  }

  Widget buildChat({
    required List<ChatMessage> messages,
    MessageOptions messageOptions = const MessageOptions(),
    TextDirection textDirection = TextDirection.ltr,
    double width = 800,
    ChatMessagesController? controller,
    bool disableAnimations = false,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: MediaQuery(
          data: MediaQueryData(disableAnimations: disableAnimations),
          child: Directionality(
            textDirection: textDirection,
            child: Center(
              child: SizedBox(
                width: width,
                child: CustomChatWidget(
                  currentUser: me,
                  controller: controller,
                  messages: messages,
                  onSend: (_) {},
                  messageOptions: messageOptions,
                  typingUsers: const [],
                  messageListOptions: const MessageListOptions(
                    paginationConfig: PaginationConfig(reverseOrder: false),
                  ),
                  readOnly: false,
                  quickReplyOptions: const QuickReplyOptions(),
                  scrollToBottomOptions: const ScrollToBottomOptions(),
                  spacingConfig: const ChatSpacingConfig(),
                  streamingEnabled: controller != null,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  group('Document AI layout (default)', () {
    testWidgets(
      'no ancestor Container has a border/shadow decoration, no robot '
      'icon, and the AI name is absent',
      (tester) async {
        await tester.pumpWidget(
          buildChat(messages: [msg(ai, 'Hello there')]),
        );
        await tester.pump();

        final containers = tester.widgetList<Container>(
          find.descendant(
            of: find.byType(CustomChatWidget),
            matching: find.byType(Container),
          ),
        );
        for (final container in containers) {
          final decoration = container.decoration;
          if (decoration is BoxDecoration) {
            expect(decoration.border, isNull);
            expect(decoration.boxShadow, isNull);
          }
        }

        expect(find.byIcon(Icons.smart_toy_outlined), findsNothing);
        expect(find.text('Assistant'), findsNothing);
      },
    );

    testWidgets('explicit showUserName: true shows the AI name', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildChat(
          messages: [msg(ai, 'Hello there')],
          messageOptions: const MessageOptions(showUserName: true),
        ),
      );
      await tester.pump();

      expect(find.text('Assistant'), findsOneWidget);
    });

    testWidgets('markdown h1 renders at fontSize 20', (tester) async {
      await tester.pumpWidget(
        buildChat(
          messages: [msg(ai, '# Heading', isMarkdown: true)],
        ),
      );
      await tester.pump();

      final markdown = tester.widget<Markdown>(find.byType(Markdown));
      expect(markdown.styleSheet?.h1?.fontSize, 20);
    });
  });

  group('Bubble AI layout (opt-in via BubbleStyle)', () {
    testWidgets('BubbleStyle.aiBubbleColor still paints the bubble', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildChat(
          messages: [msg(ai, 'Hello there')],
          messageOptions: const MessageOptions(
            bubbleStyle: BubbleStyle(aiBubbleColor: Colors.red),
          ),
        ),
      );
      await tester.pump();

      final containers = tester.widgetList<Container>(
        find.descendant(
          of: find.byType(CustomChatWidget),
          matching: find.byType(Container),
        ),
      );
      final painted = containers.where((c) {
        final decoration = c.decoration;
        return decoration is BoxDecoration && decoration.color == Colors.red;
      });
      expect(painted, isNotEmpty);
    });
  });

  group('User bubble alignment and width', () {
    testWidgets('user bubble sits right of center in LTR', (tester) async {
      await tester.pumpWidget(
        buildChat(messages: [msg(me, 'hi')], width: 400),
      );
      await tester.pump();

      final container = find
          .ancestor(
            of: find.text('hi'),
            matching: find.byType(Container),
          )
          .first;
      final center = tester.getCenter(container);
      final screenWidth = tester.getSize(find.byType(CustomChatWidget)).width;
      expect(center.dx, greaterThan(screenWidth / 2));
    });

    testWidgets('user bubble sits left of center in RTL', (tester) async {
      await tester.pumpWidget(
        buildChat(
          messages: [msg(me, 'hi')],
          width: 400,
          textDirection: TextDirection.rtl,
        ),
      );
      await tester.pump();

      final container = find
          .ancestor(
            of: find.text('hi'),
            matching: find.byType(Container),
          )
          .first;
      final center = tester.getCenter(container);
      final screenWidth = tester.getSize(find.byType(CustomChatWidget)).width;
      expect(center.dx, lessThan(screenWidth / 2));
    });

    testWidgets(
      'user bubble width is capped at 80% of a 400-wide column '
      '(<=320) even inside a wide 1200 viewport',
      (tester) async {
        tester.view.physicalSize = const Size(1200, 1000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          buildChat(
            messages: [
              msg(me, 'a rather long message that could overflow the bubble'),
            ],
            width: 400,
          ),
        );
        await tester.pump();

        final container = find
            .ancestor(
              of: find.textContaining('a rather long message'),
              matching: find.byType(Container),
            )
            .first;
        final size = tester.getSize(container);
        expect(size.width, lessThanOrEqualTo(320.0));
      },
    );
  });

  group('Copy action', () {
    testWidgets(
      'copy sends the raw text to the clipboard, shows no SnackBar, swaps '
      'to a check icon, and reverts after 1600ms',
      (tester) async {
        String? copied;
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          (call) async {
            if (call.method == 'Clipboard.setData') {
              copied = (call.arguments as Map)['text'] as String?;
            }
            return null;
          },
        );
        addTearDown(() {
          tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            SystemChannels.platform,
            null,
          );
        });

        await tester.pumpWidget(
          buildChat(messages: [msg(ai, 'copy me')]),
        );
        await tester.pump();

        expect(find.byIcon(Icons.content_copy_rounded), findsOneWidget);
        expect(find.byType(SnackBar), findsNothing);

        await tester.tap(find.byIcon(Icons.content_copy_rounded));
        await tester.pump();

        expect(copied, 'copy me');
        expect(find.byType(SnackBar), findsNothing);
        expect(find.byIcon(Icons.check_rounded), findsOneWidget);

        await tester.pump(const Duration(milliseconds: 1600));
        expect(find.byIcon(Icons.content_copy_rounded), findsOneWidget);
        expect(find.byIcon(Icons.check_rounded), findsNothing);
      },
    );
  });

  group('Streaming caret', () {
    testWidgets('present while streaming, gone after stopStreamingMessage', (
      tester,
    ) async {
      final controller = ChatMessagesController();
      addTearDown(controller.dispose);
      controller.addStreamingMessage(msg(ai, 'strea', id: 's1'));

      await tester.pumpWidget(
        buildChat(messages: controller.messages, controller: controller),
      );
      await tester.pump(const Duration(milliseconds: 50));

      expect(
        find.byKey(const ValueKey('chat-streaming-caret')),
        findsOneWidget,
      );

      controller.stopStreamingMessage('s1');
      // Let the reveal finish draining so the message leaves the reveal set.
      for (var i = 0; i < 20; i++) {
        await tester.pumpWidget(
          buildChat(messages: controller.messages, controller: controller),
        );
        await tester.pump(const Duration(milliseconds: 60));
      }

      expect(
        find.byKey(const ValueKey('chat-streaming-caret')),
        findsNothing,
      );
    });

    testWidgets(
      'under disableAnimations, the caret is visible but no animation runs',
      (tester) async {
        final controller = ChatMessagesController();
        addTearDown(controller.dispose);
        controller.addStreamingMessage(msg(ai, 'strea', id: 's2'));

        await tester.pumpWidget(
          buildChat(
            messages: controller.messages,
            controller: controller,
            disableAnimations: true,
          ),
        );
        await tester.pump(const Duration(milliseconds: 50));

        expect(
          find.byKey(const ValueKey('chat-streaming-caret')),
          findsOneWidget,
        );
        expect(tester.hasRunningAnimations, isFalse);
      },
    );
  });

  group('Grouping rhythm', () {
    testWidgets('~4px between same-sender neighbours, ~24px on sender change', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildChat(
          messages: [
            msg(me, 'first', createdAt: DateTime(2026, 1, 1, 12, 0)),
            msg(me, 'second', createdAt: DateTime(2026, 1, 1, 12, 1)),
            msg(ai, 'reply', createdAt: DateTime(2026, 1, 1, 12, 2)),
          ],
        ),
      );
      await tester.pump();

      // The per-message wrapper is `Padding(padding: EdgeInsets.only(top:
      // gap), child: LayoutBuilder(...))` — read its top inset directly
      // rather than inferring it from rendered text positions (which would
      // also bake in each bubble's own internal padding).
      double topGapFor(String text) {
        final padding = tester
            .widgetList<Padding>(
              find.ancestor(
                of: find.text(text),
                matching: find.byType(Padding),
              ),
            )
            .map((p) => p.padding)
            .whereType<EdgeInsets>()
            .firstWhere(
              (p) => p.left == 0 && p.right == 0 && p.bottom == 0 && p.top > 0,
            );
        return padding.top;
      }

      expect(topGapFor('second'), closeTo(4, 1));
      expect(topGapFor('reply'), closeTo(24, 1));
    });
  });
}
