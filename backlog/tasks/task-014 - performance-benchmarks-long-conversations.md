**Priority:** P2
**Component:** test/ (benchmark harness)
**Origin:** GOAL item 4

**Acceptance criteria:**
- [x] Add a benchmark test (e.g. `flutter test` with a timed harness, or `benchmark_harness`) that
      measures build/scroll performance with 500-2000+ messages in `ChatMessagesController`.
- [x] Record baseline numbers in the PR/CHANGELOG so regressions are visible over time.
- [x] If a real bottleneck is found (e.g. no item-extent/lazy building), file it as a follow-up task
      rather than scope-creeping this one.

## Done (2026-09-03)

Added `test/performance/message_list_benchmark_test.dart` — 8 tests timing
`ChatMessagesController.setMessages`/`addMessage`/`updateMessage` at 500-2000 messages, plus
`AiChatWidget`'s initial build and scroll cost at 1000 messages. Real numbers recorded in
`CHANGELOG.md`'s `[Unreleased]` section. Confirmed the message list already uses a lazy
`ListView.builder` (not assumed) and quantified the theoretical O(n) `indexWhere` cost in
`updateMessage` for chronological (append) order vs. the default reverse order — directionally real
(~43μs/call vs ~2μs/call at 2000 messages) but far too small in absolute terms (4ms total for 100
streaming updates) to justify a follow-up fix at this scale. No bottleneck found worth filing.
Thresholds kept generous specifically to avoid the wall-clock flakiness documented in task-019.
Commit (this tick). 434/434 tests green, analyze --fatal-infos clean.

**Status:** DONE.
