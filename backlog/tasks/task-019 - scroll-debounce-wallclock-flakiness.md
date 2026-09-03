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
- [ ] Decide on a real fix rather than more workarounds: either (a) inject a `Clock`
      (`package:clock` or a simple `DateTime Function()` field, overridable in tests) so the
      debounce can be driven deterministically via `withClock`/fake time in tests, or (b) switch
      the debounce mechanism away from wall-clock comparison entirely (e.g. a single
      `Timer?` "debounce active" flag that self-clears, rather than comparing timestamps).
- [ ] Audit existing tests for the same pattern (`addMessage`/`updateMessage` for a non-user
      message followed by a bare `pumpAndSettle()` or single `pump()`) and harden them the same
      way, OR make it structurally impossible to leak a Timer past `pumpAndSettle()` regardless of
      test drain discipline (this is the better fix — don't rely on every test author remembering
      to drain 300-800ms).
- [ ] Add a stress test that runs the same addMessage/scroll sequence many times in a loop
      within one test to make the race easier to reproduce on demand (helps verify the fix).
- [ ] `flutter test` run repeatedly (5+ times) with zero flakes.

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
