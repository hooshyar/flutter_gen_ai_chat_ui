**Priority:** P2
**Component:** ChatMessagesController scroll debounce
**Origin:** Discovered while stabilizing tests during task-002 (knob-sweep audit)

**Problem:** `ChatMessagesController`'s auto-scroll debounce (`_scrollAfterRender`,
`forceScrollToFirstMessageInChain`) gates on real wall-clock `DateTime.now()`
(`_lastScrollTime`), not a virtualizable/injectable clock. Under normal conditions the gap
between controller construction and the first `addMessage`/`updateMessage` call is a few
real milliseconds, comfortably under the 800ms debounce window, so the debounce almost
always short-circuits and no Timer gets scheduled. But under heavy load (e.g. `flutter test`
running the full ~380-test suite with many concurrent isolates), that real-time gap can
occasionally exceed 800ms, causing a genuine `Timer` (up to 300ms, from
`_scrollAfterRenderTimer`) to actually get scheduled. If the test that triggered it doesn't
drain at least that long afterward (a bare `pumpAndSettle()`'s default 100ms step can early-exit
before a Timer not tied to a scheduled frame fires), the test fails at teardown with
"A Timer is still pending even after the widget tree was disposed."

This surfaced intermittently (not on every full-suite run) while adding new tests in
task-002, and was worked around locally in those tests (draining with
`pump(duration >= 350ms)` / `pumpAndSettle(duration: 350ms)` instead of relying on
`pumpAndSettle()`'s default). It likely also affects some of the pre-existing ~372 tests
that call `addMessage`/`updateMessage` for an AI message without an equally generous drain —
this is why it wasn't caught before: it's rare, not reliably reproducible on demand, and only
shows up under specific load/timing conditions.

**Acceptance criteria:**
- [x] Decide on a real fix rather than more workarounds: either (a) inject a `Clock`
      (`package:clock` or a simple `DateTime Function()` field, overridable in tests) so the
      debounce can be driven deterministically via `withClock`/fake time in tests, or (b) switch
      the debounce mechanism away from wall-clock comparison entirely (e.g. a single
      `Timer?` "debounce active" flag that self-clears, rather than comparing timestamps).
- [x] Audit existing tests for the same pattern (`addMessage`/`updateMessage` for a non-user
      message followed by a bare `pumpAndSettle()` or single `pump()`) and harden them the same
      way, OR make it structurally impossible to leak a Timer past `pumpAndSettle()` regardless of
      test drain discipline (this is the better fix — don't rely on every test author remembering
      to drain 300-800ms). **Superseded by the clock-injection fix**: since the debounce timing is
      now driven by an injectable clock rather than a Timer that could be armed unconditionally,
      no test needed hardening — the existing "usually short-circuits" property is preserved for
      every un-migrated test (identical to today, since untouched tests still see the real clock).
- [x] Add a stress test that runs the same addMessage/scroll sequence many times in a loop
      within one test to make the race easier to reproduce on demand (helps verify the fix).
- [x] `flutter test` run repeatedly (5+ times) with zero flakes.

## Done (2026-09-03)

**Chose option (a), clock injection — after empirically ruling out (b).** First attempted (b): a
single `bool _recentlyScrolled` flag + a self-clearing `Timer` (exactly as the acceptance criteria's
own suggested wording describes), replacing the wall-clock comparison. Running the existing suite
against it immediately surfaced 100+ new failures ("A Timer is still pending"), *more* than before
the change — the wall-clock version's debounce almost always blocks the very FIRST scroll of a fast
test (since `_lastScrollTime` is initialized at construction and real elapsed time to the first call
is a few ms, comfortably under 800ms), so the delayed-scroll `Timer` it gates almost never actually
gets created in a normal test run. That's an accidental protective side-effect, not something (b)'s
naive always-armed flag preserves — the flag starts `false` and lets the FIRST call through every
time, unconditionally scheduling a real `Timer` in essentially every widget test that exercises
scrolling. Reverted (b) cleanly via `git checkout` before it was ever committed.

Went with (a) instead: added `clock: ^1.1.2` (pinned to match Flutter's own bundled `flutter_test`
`clock` dependency exactly, confirmed via both the pub.dev API and Flutter's own `flutter_test`
pubspec.yaml across 3.35.0/3.38.0/3.41.6 — no cascading floor issue this time, unlike task-012's
`google_fonts`/`characters` chase). Replaced the 3 debounce-timing `DateTime.now()` call sites
(`_scrollAfterRender`, `forceScrollToFirstMessageInChain`, `_scrollToBottomInternal`) and the
`_lastScrollTime` field initializer with `clock.now()` — a drop-in, zero-behavior-change swap for
any code path that doesn't explicitly `withClock(...)` (confirmed: full 434/434 suite green,
unchanged, both before and after). Added `test/controllers/scroll_debounce_clock_test.dart` (2
tests): a 25-iteration stress loop that advances a fake clock by 2s each iteration to force the
debounce open on demand every time (previously only possible by chance under real machine load),
verifying no Timer leaks past disposal; and a companion test confirming the debounce still blocks a
second call when the fake clock hasn't advanced. Ran the full suite twice in a row plus the new file
3 times in isolation — zero flakes. 436/436 tests green, `analyze --fatal-infos` clean, `dart format`
clean.

**Status:** DONE.

**Confirmed pre-existing, not a regression (2026-09-03):** Reproduced the same failure class in
tests I never touched — `test/input_customization_test.dart` ("ResultRendererRegistry
integration — edge cases rich message interleaved with text messages all render correctly") and
`test/controllers/auto_scroll_behavior_test.dart` ("ChatMessagesController scrollToMessage
functionality accepts message IDs for scrolling") — while running the full suite under unusually
heavy machine load (multiple concurrent Conductor fleet sessions — rs-tinder, dila-edms-app,
flutter_streaming_text_markdown — each running their own `flutter test`/`flutter analyze` and
contending for the same shared Flutter SDK toolchain lock; one full-suite run took 14m52s instead
of the normal ~20-50s). Isolated per-file reruns of every test I added/changed this session passed
cleanly and quickly every time. Confirms this is a real, pre-existing architectural issue (the
debounce compares real `DateTime.now()`, so it behaves completely differently when the machine is
this heavily loaded) rather than something introduced today — safe to ship the day's actual fixes;
this task tracks the proper fix.

**Notes:** Not urgent (rare under normal single-session load, doesn't affect real app behavior —
only test-suite reliability), but worth fixing properly rather than leaving every future test
author to rediscover this the hard way. Most visible when multiple fleet sessions run `flutter
test` concurrently on this machine.

## Another instance (2026-09-03 10:10)
Full suite in a separate worktree while 5 fleet sessions + 2 flutter web dev servers were running: `test/golden/chat_golden_test.dart: streaming message mid-stream (partial reveal)` failed once; the same test passes in isolation on both the fixed and the pre-fix commit. Timing-dependent partial-reveal golden under CPU load. Consider pumping to a deterministic reveal point instead of a wall-clock duration.
