import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';

/// Rows of the default reverse message list are matched by message id
/// (`findChildIndexCallback`, issue #42), so when rows before them come or
/// go they MOVE to their new index instead of being rebuilt in place. For a
/// row that is kept alive off screen (its content uses
/// `AutomaticKeepAliveClientMixin`) that moves it between keep-alive slots
/// of the sliver, a path the list never took before. Removing and adding
/// messages and toggling the typing indicator while such rows sit far
/// outside the cache extent must not throw, and every row must still show
/// its own message, in order, with its kept-alive state intact.
void main() {
  const user = ChatUser(id: 'user', name: 'You');
  const ai = ChatUser(id: 'ai', name: 'AI');

  testWidgets(
    'kept-alive rows survive moving between keep-alive slots when messages '
    'are removed/added and the typing indicator toggles',
    (tester) async {
      final created = <String, int>{};
      ChatMessage message(int i) => ChatMessage(
            text: 'message $i',
            user: i.isEven ? user : ai,
            createdAt: DateTime(2026, 1, 1).add(Duration(minutes: i)),
            customProperties: {'id': 'm$i'},
            customBuilder: (context, m) => _KeepAliveRow(
              id: 'm$i',
              text: m.text,
              // A mix of kept-alive and ordinary rows.
              keepAlive: i % 3 != 2,
              created: created,
            ),
          );

      // Newest first, as the reverse list expects.
      var order = [for (var i = 29; i >= 0; i--) i];
      final messages = ValueNotifier<List<ChatMessage>>(
        [for (final i in order) message(i)],
      );
      final loading = ValueNotifier<bool>(false);
      addTearDown(messages.dispose);
      addTearDown(loading.dispose);
      final controller = ChatMessagesController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: ValueListenableBuilder<bool>(
              valueListenable: loading,
              builder: (context, isLoading, _) =>
                  ValueListenableBuilder<List<ChatMessage>>(
                valueListenable: messages,
                builder: (context, list, _) => AiChatWidget(
                  currentUser: user,
                  aiUser: ai,
                  controller: controller,
                  messages: list,
                  onSendMessage: (_) async {},
                  loadingConfig: LoadingConfig(isLoading: isLoading),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      ScrollPosition position() =>
          tester.state<ScrollableState>(find.byType(Scrollable).first).position;

      Future<void> settle() async {
        for (var i = 0; i < 10; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(tester.takeException(), isNull);
      }

      void setOrder(List<int> newOrder) {
        order = newOrder;
        messages.value = [for (final i in order) message(i)];
      }

      // Build every row once (scroll to the oldest messages and back), so the
      // old rows are kept alive far outside the cache extent.
      position().jumpTo(position().maxScrollExtent);
      await settle();
      position().jumpTo(0);
      await settle();
      expect(find.text('message 0'), findsNothing);
      final keptAliveIds = [
        for (var i = 0; i < 30; i++)
          if (i % 3 != 2 && created.containsKey('m$i')) 'm$i',
      ];
      expect(keptAliveIds, contains('m0'));

      // Remove a visible message, then an off-screen kept-alive one; add
      // new ones; toggle the typing indicator below the newest message.
      setOrder(order.where((i) => i != 28).toList());
      await settle();
      setOrder([30, ...order]);
      await settle();
      for (var t = 0; t < 3; t++) {
        loading.value = true;
        await settle();
        loading.value = false;
        await settle();
      }
      setOrder(order.where((i) => i != 3).toList());
      await settle();
      setOrder([32, 31, ...order]);
      loading.value = true;
      await settle();
      loading.value = false;
      await settle();

      // Every row shows its own message, in order, from the newest at the
      // bottom to the oldest at the top.
      final seen = <String, double>{};
      void collect() {
        for (final element in find
            .byType(_KeepAliveRow, skipOffstage: true)
            .evaluate()) {
          final row = element.widget as _KeepAliveRow;
          final box = element.renderObject! as RenderBox;
          expect(
            find.descendant(
              of: find.byWidget(row),
              matching: find.text(row.text),
            ),
            findsOneWidget,
          );
          // In a reverse list a larger scroll offset moves the content
          // down, so this is the row's y in the content, whatever the
          // current offset.
          seen[row.id] ??= box.localToGlobal(Offset.zero).dy -
              tester.getTopLeft(find.byType(ListView).first).dy -
              position().pixels;
        }
      }

      for (var offset = 0.0;
          offset <= position().maxScrollExtent;
          offset += 200) {
        position().jumpTo(offset);
        await tester.pump();
        collect();
      }
      position().jumpTo(position().maxScrollExtent);
      await tester.pump();
      collect();
      expect(tester.takeException(), isNull);

      final expectedIds = [for (final i in order) 'm$i'];
      expect(seen.keys.toSet(), expectedIds.toSet());
      // Newest first in the list means bottom first on screen: the content
      // y (top-down, independent of the scroll offset) decreases along it.
      final ys = [for (final id in expectedIds) seen[id]!];
      for (var k = 1; k < ys.length; k++) {
        expect(
          ys[k],
          lessThan(ys[k - 1]),
          reason: '${expectedIds[k]} should be above ${expectedIds[k - 1]}',
        );
      }

      // Kept-alive rows that were never removed kept their state throughout.
      for (final id in keptAliveIds.where((id) => id != 'm3' && id != 'm28')) {
        expect(created[id], 1, reason: '$id was rebuilt from scratch');
      }
    },
  );
}

class _KeepAliveRow extends StatefulWidget {
  const _KeepAliveRow({
    required this.id,
    required this.text,
    required this.keepAlive,
    required this.created,
  });

  final String id;
  final String text;
  final bool keepAlive;
  final Map<String, int> created;

  @override
  State<_KeepAliveRow> createState() => _KeepAliveRowState();
}

class _KeepAliveRowState extends State<_KeepAliveRow>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => widget.keepAlive;

  @override
  void initState() {
    super.initState();
    widget.created[widget.id] = (widget.created[widget.id] ?? 0) + 1;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return SizedBox(height: 120, child: Text(widget.text));
  }
}
