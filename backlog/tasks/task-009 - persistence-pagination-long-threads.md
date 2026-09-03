**Priority:** P2
**Component:** ChatMessagesController
**Origin:** GitHub issue #13, Issue #41 Phase 3 (unchecked item)

**Acceptance criteria:**
- [x] Design an opt-in lazy-pagination API for `ChatMessagesController` (load-older-messages on
      scroll-to-top) — additive, doesn't change default in-memory behavior.
- [x] Provide a persistence hook/interface (consumer supplies storage; package doesn't force a
      specific backend) for restoring long threads.
- [x] Add a performance benchmark test for long conversations (see task-014) to validate this
      actually helps.
- [x] Tests + docs.

## Done (2026-09-03)

**The lazy-pagination half was already done, discovered rather than built**: `loadMore()`,
`hasMoreMessages`, and `PaginationConfig` (`enabled`, `autoLoadOnScroll`,
`distanceToTriggerLoadPixels`, `loadMoreDebounceTime`) already existed and are genuinely wired to a
real scroll listener in `custom_chat_widget.dart` — confirmed by reading the wiring, not assumed.
task-014's benchmark suite already covers this at 500-2000 messages. The one confirmed-dead knob in
this area, `PaginationConfig.scrollThreshold` (flagged open since task-002), is now `@Deprecated`
with a regression test proving the real trigger (`distanceToTriggerLoadPixels`) works regardless of
its value — closes out that long-standing loose end.

**The genuinely new work was the persistence hook.** Added `ChatPersistence`
(`lib/src/models/chat/chat_persistence.dart`) — an abstract `loadMessages()`/`saveMessages(...)`
interface, consumer-implemented, no storage backend forced. Wired into `ChatMessagesController` via
3 new constructor params (`persistence`, `autoPersist` default true, `persistDebounce` default
500ms) and 2 new methods (`restoreFromPersistence()`, `persistNow()`). Auto-persist is called from
every message-mutating method (`addMessage`, `addMessages`, `updateMessage` incl. its error-fallback
path, `setMessages`, `clearMessages`), debounced via a tracked `Timer` cancelled in `dispose()` —
learned the hard way from task-019 this session that an untracked/uncancelled debounce Timer is
exactly how "Timer still pending" test failures happen, so this one was designed correctly from the
start rather than retrofitted. 6 new tests in `test/controllers/chat_persistence_test.dart`,
including 2 using `package:fake_async`'s `fakeAsync()` to deterministically prove the debounce
coalesces a burst into one save and that disposal cancels a pending save without leaking a Timer.
Documented in a new cookbook recipe (`doc/cookbook/README.md`) and linked from README's feature
list. Added `fake_async: ^1.3.3` as an explicit dev_dependency (was already resolving transitively
via `flutter_test`, but explicit is more correct than relying on that).

443/443 tests green (436 + 6 persistence + 1 scrollThreshold regression), `analyze --fatal-infos`
clean (root + example), `dart format` clean, `dart pub publish --dry-run` clean.

**Status:** DONE.
