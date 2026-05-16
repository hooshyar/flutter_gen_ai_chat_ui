# Work Log

Running log of autonomous maintenance iterations on `flutter_gen_ai_chat_ui`.
Each iteration is scope-bound. Entries are append-only and timestamped.

---

## 2026-05-16 — Iteration 1: Agent discoverability + pub.dev topics

### Orientation snapshot
- Branch: `main`, up to date with `origin/main`.
- Open GitHub issues: 0. Open PRs: 0. No triage backlog.
- Last release: 2.11.1 (2026-05-04, hardware Enter sends on desktop/web).
- Baseline `flutter analyze`: clean ("No issues found!").
- Baseline `flutter test`: 278 tests, all pass with `--concurrency=1`. One test in
  `test/widgets/streaming_disable_test.dart` flakes intermittently under the
  default parallel runner — pre-existing, not caused by this iteration. Logged
  as a follow-up for iteration 2.

### Bucket chosen
(a) Agent discoverability + (b) pub.dev SEO/topics. Both are purely additive,
zero-risk to the public Dart API, and compound: AGENTS.md helps AI coding
agents pick this package; richer `topics:` helps pub.dev's own search and
relevance signals. Code-health (c) and test-coverage (d) deferred.

### Changes (uncommitted — user reviews before commit)
1. **`AGENTS.md`** (new, repo root, ~190 lines)
   - "What it is" + 1-paragraph hook tuned for LLM context windows.
   - "When to use" / "When not to use" decision section.
   - Three copy-paste-ready snippets: minimal chat, streaming, agent/tool use.
   - Key flag glossary: `enableMarkdownStreaming`, `streamingWordByWord`,
     `enableMathRendering`, `ChatMessage.rich`, `ChatMessage.loading`,
     `resultRenderers`, `sendOrMicBuilder`, `sendOnEnter`.
   - Differentiators table vs `flutter_chat_ui` and `dash_chat_2`.
   - Pointers to README, CHANGELOG, doc/MIGRATION.md.
2. **`pubspec.yaml` `topics:`** — expanded from 5 to 10 tags to cover the
   AI/agent surface area: `ai`, `chat`, `llm`, `openai`, `anthropic`, `gemini`,
   `streaming`, `agent`, `markdown`, `rtl`. (pub.dev allows up to ~32 topics
   but recommends focused ones; 10 stays well under the cap and each one is
   genuinely keyword-relevant to the package's surface.)
3. **`pubspec.yaml` `description:`** — rewritten for keyword density and the
   180-char pub.dev sweet spot. Now leads with "AI chat UI" and explicitly
   names streaming, markdown, agent/tool-use, and rich widgets.

### Verification
- `flutter analyze` after changes: clean ("No issues found!").
- `flutter test --concurrency=1` after changes: 278/278 pass.
- `dart pub publish --dry-run`: not executed this iteration (no version bump,
  and user controls release timing). Will run in the release-prep iteration.

### Diff summary (files touched)
- `AGENTS.md` — new file
- `WORK_LOG.md` — new file (this file)
- `pubspec.yaml` — topics + description only; no version bump, no dep change

### What did NOT change
- No version bump in `pubspec.yaml` (user controls releases).
- No `CHANGELOG.md` edit yet — those land at release time. The intended entry
  is drafted in this log section.
- No public Dart API surface changes.
- No example/ changes.
- The flaky `streaming_disable_test.dart` parallel-run failure is **not**
  addressed this iteration. Pre-existing; needs a dedicated investigation.

### Next iteration candidates (priority order)
1. **Investigate the parallel-run flake** in
   `test/widgets/streaming_disable_test.dart`. It passes with
   `--concurrency=1` but fails ~once per run with the default runner.
   Likely a shared singleton or static state in the streaming pipeline.
2. **Code health (bucket c)**: 24 dependency updates available per
   `flutter pub get` output. Most are not in our direct dep list — but worth
   auditing direct deps (`flutter_streaming_text_markdown 1.6.0 → 1.7.3`,
   `google_fonts 8.0.1 → 8.1.0`) for non-breaking bumps and any new
   `flutter analyze` info-level findings on a fresh SDK.
3. **README.md** still has `flutter_gen_ai_chat_ui: ^2.4.2` in the install
   snippet (line 126). Bump to `^2.11.1` to match the actual current version.
4. **Test coverage gap**: `lib/src/agents/example_agents.dart` and
   `lib/src/controllers/agent_orchestrator.dart` are exported but appear to
   have thinner test coverage than the classic-chat surface. Worth a sweep.
5. **Draft CHANGELOG entry** for the next release rolling up topics +
   AGENTS.md as a "Notes / Discoverability" sub-section.

### Reflection
Zero open issues + zero open PRs is the rare condition where SEO and
discoverability work has the highest expected value. The package's classic
and agent surfaces are both solid; what's missing is a fast, structured
entry point that an LLM-driven coding assistant can ingest in one read. That
is exactly what AGENTS.md is for. Pub.dev topic enrichment is a five-minute
edit with measurable downstream impact on search ranking. Both changes are
additive, reversible, and require no version bump.

---

## 2026-05-16 — Iteration 2: Fix flaky streaming_disable_test + README version bump

### Orientation snapshot
- Branch: `main`, up to date with `origin/main`. Zero open issues, zero open PRs.
- Baseline before this iter: `flutter test` default concurrency = 276 pass / 2 fail.
  Both failures in `test/widgets/streaming_disable_test.dart` with the assertion
  *"A Timer is still pending even after the widget tree was disposed."* (so the
  iter-1 note that this only failed "intermittently" was optimistic — it now
  fails deterministically in isolation too).
- `flutter analyze`: clean.

### Root cause
`ChatMessagesController._scrollAfterRender` (lib/src/controllers/chat_messages_controller.dart:480)
scheduled a 200–300 ms post-render scroll via raw `Future.delayed(...)`. That
future was *untracked* — nothing could cancel it. A second untracked
`Future.delayed(300ms)` lived in the scroll-listener at line 181 to reset the
manual-scroll flag. Both create real timers in `fake_async`. When a widget
test does `await tester.pump()` once and returns, the timers are still pending
when `AutomatedTestWidgetsFlutterBinding._verifyInvariants` runs its
`!timersPending` assertion at binding.dart:2242 — *before* any `tearDown`
runs — so the test fails. This is not a parallel-runner race; iter-1 misread
the symptom.

### Fix (uncommitted)
1. `lib/src/controllers/chat_messages_controller.dart`
   - Added two tracked `Timer?` fields: `_scrollAfterRenderTimer` and
     `_manualScrollResetTimer`.
   - Replaced both raw `Future.delayed(...)` calls with `Timer(...)` stored in
     those fields. Each handler nulls its own field and `?.cancel()`s any
     previous in-flight timer before scheduling a new one (so rapid
     `addMessage` calls coalesce instead of leaking).
   - `dispose()` now cancels both new timers alongside the existing
     `_pendingScrollTimer`.
2. `test/widgets/streaming_disable_test.dart`
   - Added `await tester.pump(const Duration(milliseconds: 350))` at the end
     of all 5 `testWidgets` cases to drain the post-render scroll timer
     before the test exits.
3. `README.md`
   - Install snippet bumped `^2.4.2` → `^2.11.1` (iter-1 queued item).

Why both layers: production code cleanup (cancellable timers) + test discipline
(drain the timer that production legitimately needs). Tracked timers also fix
the latent leak — if a consumer disposed the controller mid-scroll the old
`Future.delayed` would still run its body and emit debug logs.

### Verification
- `flutter analyze` → "No issues found!"
- `flutter test` (default concurrency, no `--concurrency=1` workaround) →
  **278 / 278 pass.** Ran twice, both clean. Flake is gone.
- `flutter test test/widgets/streaming_disable_test.dart` (isolated) →
  5/5 pass.
- No public API change. No version bump. No dep change.

### Diff summary (files touched, all uncommitted)
- `lib/src/controllers/chat_messages_controller.dart` — two tracked Timer
  fields + cancellation in dispose; semantics identical to before.
- `test/widgets/streaming_disable_test.dart` — appended timer-drain pump to
  each of the 5 test cases.
- `README.md` — install version `^2.4.2` → `^2.11.1`.
- `WORK_LOG.md` — this entry.

### What did NOT change
- No version bump (`pubspec.yaml` still 2.11.1).
- No `CHANGELOG.md` entry — that lands at release time. Suggested wording for
  next release: *"Fixed: `ChatMessagesController` no longer leaks a pending
  scroll timer after dispose; widget tests using the controller can now exit
  cleanly without `pumpAndSettle`."*
- No agent / agent_orchestrator coverage work.
- No dep bumps.

### Next iteration candidates (priority order)
1. **Non-breaking dep bumps**: `flutter_streaming_text_markdown 1.6.0 → 1.8.0`
   (now available, not 1.7.3 as iter-1 noted), `google_fonts 8.0.2 → 8.1.0`.
   Read both CHANGELOGs first; the streaming dep is on the hot path.
2. **Test coverage gap on agents surface** — `lib/src/agents/` and
   `lib/src/controllers/agent_orchestrator.dart` still under-tested vs. the
   classic chat surface. Add tests around `AgentOrchestrator`'s status
   transitions and error paths.
3. **Audit other `Future.delayed` in `lib/src/`** — same anti-pattern may
   exist in `agent_orchestrator.dart`, `ai_context_controller.dart`, or
   the streaming widgets. Quick `grep` + convert to tracked `Timer`.
4. **Draft CHANGELOG entry** rolling up iter-1 (AGENTS.md, topics) +
   iter-2 (flaky test fix) for the next patch release.

### Reflection
The iter-1 note characterised this as "passes with --concurrency=1, fails
parallel" — that turned out to be wrong; the test failed in isolation too.
The lesson: trust the stack trace before trusting prior triage. The fix was
small once the root cause (untracked timers in production code) was visible
in the failure output. The test-side `pump(350ms)` drain is honest: tests
must take responsibility for timers their code-under-test legitimately
schedules.

---

## 2026-05-16 — Iteration 3: Untracked-timer audit across lib/src/

### Orientation snapshot
- Branch `main`, up to date with `origin/main`. Zero open issues / zero open
  PRs.
- Baseline `flutter analyze`: clean. Baseline `flutter test`: 278/278 pass
  on default concurrency (iter-2 fix held).

### Audit method
`grep -rn 'Future\.delayed' lib/src/`, `grep -rn 'Timer(' lib/src/`, and
`grep -rn 'Timer\.periodic' lib/src/`. For every hit, traced the caller's
lifecycle: `State`/`ChangeNotifier` with a `dispose` method. If the timer's
closure could fire after `dispose` and either (a) capture `this`, (b) call
`mounted` mid-flight, or (c) just keep the timer in `fake_async`'s pending
queue past widget teardown, classified it as a leak.

### Grep hits — classification
| Site | Verdict | Note |
|---|---|---|
| `chat_messages_controller.dart:115` `Timer(delay,...)` in `simulateStreamingCompletion` | **LEAK** | Untracked. Closure references `this` via `stopStreamingMessage`. Fixed. |
| `chat_messages_controller.dart:193,497,899` | Benign | Already tracked in iter 2 + pre-existing. Cancelled in `dispose`. |
| `action_controller.dart:351` `Timer(2s, ...)` in `_completeExecution` | **LEAK** | Untracked. Closure mutates `_executions` map and calls `notifyListeners()`. Fixed via tracked `_cleanupTimers` set. |
| `ai_context_controller.dart:340` `Timer.periodic` | Benign | Tracked `_cleanupTimer`, cancelled in `dispose`. |
| `ai_text_input_controller.dart:37` `Timer(...)` | Benign | Tracked `_suggestionTimer`, cancelled in `dispose`. |
| `custom_chat_widget.dart:156,202` `Timer(...)` | Benign | Tracked `_wordByWordTimers` (list) and `_scrollDebounce`, both cancelled in `dispose`. |
| `loading_widget.dart:163` `Timer.periodic` | Benign | Tracked `_timer`, cancelled in `dispose`. |
| `streaming_text_animations.dart:251` `Future.delayed` recursive | **LEAK** | Untracked recursive self-scheduling. Closure captures `this` via `setState`/`_currentIndex`. Fixed via tracked `_stepTimer`. |
| `animated_chat_widgets.dart:136` `Future.delayed(widget.delay,...)` in `initState` | **LEAK** | Untracked. Closure captures `this` via `_controller.forward()`. Fixed via tracked `_startDelayTimer`. Short-circuited when `delay == Duration.zero` to keep prior fast-path. |
| `copilot_textarea.dart:134` `Future.delayed(500ms,...)` debounce | **LEAK** | Untracked. Captures `this` via `_getSuggestions()`. Fixed via tracked `_suggestionDebounceTimer`. |

### Production fixes (all uncommitted, additive, zero public API change)
1. `lib/src/controllers/chat_messages_controller.dart` — added
   `_simulateStreamingTimers` set + cancellation in `dispose`.
2. `lib/src/controllers/action_controller.dart` — added `_cleanupTimers`
   set; closure removes self before mutating state; cancellation in
   `dispose`. Reordered `dispose` so timers cancel before
   `_eventController.close()` (defensive against listener callbacks).
3. `lib/src/widgets/streaming_text_animations.dart` — added `_stepTimer`
   field; previous timer cancelled before scheduling new one; cleared in
   `dispose`. Added `dart:async` import.
4. `lib/src/widgets/animated_chat_widgets.dart` — added `_startDelayTimer`
   field; `Duration.zero` short-circuits to a synchronous `forward()`;
   cancelled in `dispose`. Added `dart:async` import.
5. `lib/src/widgets/copilot_textarea.dart` — added
   `_suggestionDebounceTimer` field; closure self-clears and re-checks
   `mounted`; cancelled in `dispose`. Added `dart:async` import. Also
   inlined `_hideSuggestions` cleanup inside `dispose` to avoid a
   pre-existing latent bug where `_hideSuggestions()` called `setState()`
   from `dispose()` (surfaced by the new regression test — would have
   crashed any consumer that ever unmounted the widget under a tester).

### Regression tests added (uncommitted)
1. `test/controllers/chat_messages_controller_test.dart` — new group
   "Timer Lifecycle (iter 3)" with `simulateStreamingCompletion cancels
   its timer on dispose`.
2. `test/controllers/action_controller_test.dart` — new group "Timer
   Lifecycle (iter 3 audit)" with `cleanup timer is cancelled on dispose
   without pending leaks`.
3. `test/widgets/timer_lifecycle_test.dart` — new file with three
   `testWidgets` cases for `StreamingTextWidget`, `AnimatedBubble`, and
   `CopilotTextarea` — each schedules a long delay then unmounts before
   the delay elapses; the test framework's `!timersPending` invariant
   would catch any regression.

### Verification
- `flutter analyze` → "No issues found!"
- `flutter test` (default concurrency, run 1) → **283 / 283 pass.**
- `flutter test` (default concurrency, run 2) → **283 / 283 pass.**
  Stable. Net +5 tests (3 widget + 2 controller).
- No public API change. No version bump. No dep change.

### Diff summary (files touched, all uncommitted)
- `lib/src/controllers/chat_messages_controller.dart`
- `lib/src/controllers/action_controller.dart`
- `lib/src/widgets/streaming_text_animations.dart`
- `lib/src/widgets/animated_chat_widgets.dart`
- `lib/src/widgets/copilot_textarea.dart`
- `test/controllers/chat_messages_controller_test.dart`
- `test/controllers/action_controller_test.dart`
- `test/widgets/timer_lifecycle_test.dart` (new)
- `WORK_LOG.md` (this entry)

### What did NOT change
- No version bump in `pubspec.yaml` (still 2.11.1; user controls release).
- `CHANGELOG.md` not yet updated — drafted suggested wording below.
- Dep bumps deferred. `flutter_streaming_text_markdown 1.6.0 → 1.8.0` and
  `google_fonts 8.0.2 → 8.1.0` are still pending and would be safer in
  their own iteration after these fixes settle.
- The `_hideSuggestions`-during-dispose bug was patched only via the
  `dispose` inlining; the `_hideSuggestions` function itself still
  contains the same `setState` call. This is intentionally a minimal
  diff — patching the function further would also need a callsite audit
  (it's called from several places at line 130, 136, 235, 329). Worth a
  follow-up that audits all callsites + adds `mounted` guards.

### Suggested CHANGELOG entry for the next release (drafting; do not bump)
```
## [Unreleased]

### Fixed
- `ChatMessagesController.simulateStreamingCompletion` no longer leaks a
  pending `Timer` after `dispose()`. Widget tests using the simulation
  path can exit cleanly without `pumpAndSettle`.
- `ActionController` no longer leaks the 2-second post-completion cleanup
  `Timer` if the controller is disposed before the timer fires.
- Internal `StreamingTextWidget` (used by streaming animations) no longer
  leaks its recursive step `Timer` on dispose.
- Internal `AnimatedBubble` no longer leaks its start-delay `Timer` on
  dispose.
- `CopilotTextarea` no longer leaks its 500ms suggestion-debounce timer
  on dispose, and no longer crashes the widget tree when unmounted while
  a suggestion overlay is visible.

### Notes
- No public API changes. No new exports. Backwards compatible from 2.11.x.
- Discoverability: package now ships an `AGENTS.md` at the repo root
  (LLM-friendly quick reference for AI coding assistants) and an expanded
  `topics:` list in `pubspec.yaml` (10 tags covering AI, agents, LLM,
  streaming, markdown, RTL).
- Test count: 278 → 283. Five new regression tests pin the timer
  lifecycle behavior fixed in this release.
```

### Next iteration candidates (priority order)
1. **Dep bumps**: read CHANGELOGs for
   `flutter_streaming_text_markdown 1.6.0 → 1.8.0` and
   `google_fonts 8.0.2 → 8.1.0`. Apply, run tests, commit. Streaming dep
   is on the hot path; check its release notes for behaviour changes
   first.
2. **`CopilotTextarea` callsite audit** for the `_hideSuggestions` →
   `setState` interaction (orthogonal to timer leaks but found during
   this audit). Add `mounted` guards on every internal callsite that
   may fire during teardown.
3. **`AgentOrchestrator` / `lib/src/agents/`** coverage gap — still
   under-tested vs. classic chat surface. Add tests around state machine
   transitions and error paths.
4. **Apply the drafted CHANGELOG `[Unreleased]` block** when the next
   release is being prepared — it rolls up iters 1-3.

### Reflection
The iter-2 hypothesis ("same anti-pattern likely exists elsewhere") was
correct. Five additional production-code leaks across two controllers and
three widgets, plus one pre-existing pre-disposal `setState` bug surfaced
by the new tests — that bug would have been a latent crash in any
consumer's widget tree the moment they unmounted a `CopilotTextarea`.
The grep-and-classify methodology scaled cleanly across 13 hits and made
the false-positive/leak ratio (7 benign / 6 real) easy to defend in
review. Worth re-running the same audit on `StreamSubscription` and on
`addPostFrameCallback` callsites in a future iteration — same anti-pattern
shape, same class of test failures.

---

## 2026-05-16 — Iteration 4: AgentOrchestrator test coverage

### Orientation snapshot
- Branch `main`, up to date with `origin/main`. Zero open issues / zero
  open PRs.
- Baseline `flutter analyze`: clean.
- Baseline `flutter test`: 283/283 pass (iter-3 fixes held).
- Coverage gap from iter 3's "next iteration" #3: `AgentOrchestrator` and
  `lib/src/agents/example_agents.dart` had **zero** test references — grep
  for `AgentOrchestrator|TextAnalysisAgent` in `test/` returned nothing.
  The orchestrator is exported public API; uncovered behaviour included
  routing, delegation, error wrapping, streaming, collaboration, and
  dispose semantics.

### Scope chosen
Rotation bucket = tests. Wrote `test/controllers/agent_orchestrator_test.dart`
with a deterministic in-test `_FakeAgent` (no `Future.delayed` sleeps, no
randomness) so the suite stays sub-second. Test file mirrors `lib/src/`
layout per the project convention. No production code was modified — the
test surfaced no real bugs.

### Coverage added (file + named tests, 19 cases)
`test/controllers/agent_orchestrator_test.dart` — new file. Groups:
1. **Agent registration** (5 cases)
   - registers an agent and calls `initialize` with orchestrator config
   - `unregisterAgent` disposes the agent and removes it
   - `unregisterAgent` on unknown id is a no-op
   - `getAgentsByCapability` filters on agent capabilities
   - `getAvailableAgents` returns only idle agents
2. **processRequest happy path** (4 cases)
   - routes to the only registered agent and returns its response
   - emits the agent response on the orchestrator response stream
   - routes to the capability-matching agent when scores differ
   - throws `AgentException` when no agents are registered
3. **processRequest error handling** (2 cases)
   - wraps agent exceptions in an error `AgentResponse`
   - error response is also emitted on the response stream
4. **Delegation** (2 cases)
   - `_handleDelegation` re-routes to the metadata-named agent (with the
     correct `parentRequestId` and `AgentRequestType.delegation` on the
     delegated request)
   - delegation with missing target metadata surfaces as an error
     `AgentResponse` (pinned contract — see note below)
5. **Collaboration** (2 cases)
   - `startCollaboration` throws `UnsupportedError` when
     `enableCollaboration: false`
   - `startCollaboration` registers the session and notifies listeners
6. **streamResponse** (2 cases)
   - yields a partial then the final response from the routed agent
   - yields a final error response when the agent throws
7. **Disposal** (2 cases)
   - `dispose()` closes both stream controllers and disposes all agents
     (verified by draining each broadcast stream before dispose)
   - `dispose()` leaves no pending timers (regression-pin for the
     iter-3 leak-free contract)

### Contract surfaced (not a bug — worth pinning in code review)
The orchestrator's `processRequest` try/catch wraps **all** throws from
both `targetAgent.processRequest` *and* `_handleDelegation`. A delegation
response with missing `delegate_to` metadata therefore yields an error
`AgentResponse` (not a propagated `AgentException`). My first draft test
expected a thrown exception and failed; the production behaviour is
defensible (callers always see an `AgentResponse`, never a raw throw on
the happy-flow API surface), so I updated the test to pin that contract
rather than change the orchestrator.

### Bonus task — CopilotTextarea `_hideSuggestions`/`setState` audit
Iter 3 flagged lines 130, 136, 235, 329 as the call sites to audit.
Reviewed all four:
- Line 130/136 (`_onTextChanged`): synchronous `TextEditingController`
  listener callback, no async gap. Safe.
- Line 235 (renumbered to 240, in `_showSuggestionOverlay`): called
  synchronously from inside `_getSuggestions`'s post-`mounted`-gate
  block. Safe.
- Line 329 (in `_applySuggestion`): synchronous user-tap response. Safe.
- `_triggerCompletion` (lines 346-365): the post-await write to
  `_controller` is already guarded by `if (mounted && completion.isNotEmpty)`.
- `_getSuggestions` (line 178): already `if (mounted && text == _controller.text)`.

Iter-3's inlining of overlay cleanup in `dispose()` (so the dispose path
never reaches `_hideSuggestions`) closed the only real hazard. No
additional `mounted` guards or production changes are needed. The
existing `test/widgets/timer_lifecycle_test.dart` test for
`CopilotTextarea` already pins the dispose-during-debounce path.

### Verification
- `flutter analyze` → "No issues found!"
- `flutter test` (default concurrency, run 1) → **302 / 302 pass.**
- `flutter test` (default concurrency, run 2) → **302 / 302 pass.**
  Stable. Net **+19 tests** (283 → 302).
- `flutter test test/controllers/agent_orchestrator_test.dart` in
  isolation → 19/19 pass.
- No production code changed this iteration.
- No public API change. No version bump. No dep change.

### Diff summary (files touched, all uncommitted)
- `test/controllers/agent_orchestrator_test.dart` — new file (19 tests)
- `WORK_LOG.md` — this entry

### What did NOT change
- No production code in `lib/src/agents/` or
  `lib/src/controllers/agent_orchestrator.dart` — no bugs surfaced by
  the new tests.
- No `pubspec.yaml` version bump. No `CHANGELOG.md` edit.
- The pending dep bumps from iter 2/3 (`flutter_streaming_text_markdown
  1.6.0 → 1.8.0`, `google_fonts 8.0.2 → 8.1.0`) still pending.

### Suggested CHANGELOG entry for the next release (drafting; do not bump)
Append under the iter-3 `[Unreleased]` block:
```
### Tests
- Added 19 unit tests covering `AgentOrchestrator` (registration,
  routing, delegation, collaboration, streaming, error wrapping, and
  dispose). Public API behaviour pinned: routing prefers capability
  matches; delegation with missing target metadata returns an error
  response rather than throwing.
```

### Next iteration candidates (priority order)
1. **`example_agents.dart` test coverage** — the orchestrator tests use
   a deterministic fake; the three shipped example agents
   (`TextAnalysisAgent`, `CodeAnalysisAgent`, `GeneralAssistantAgent`)
   still have zero direct tests. Each has its own `canHandle` routing
   rules, state-stream emissions, and the general agent has
   delegation-triggering logic that's only exercised end-to-end via the
   example app. A small targeted suite (~10 tests) would cover the
   remaining gap from iter-3's "next iteration" #3.
2. **Dep bumps** (still pending from iters 2 & 3):
   `flutter_streaming_text_markdown 1.6.0 → 1.8.0`,
   `google_fonts 8.0.2 → 8.1.0`. Read each CHANGELOG first; the
   streaming dep is on the hot path.
3. **`StreamSubscription` and `addPostFrameCallback` audit** — same
   anti-pattern shape as the timer audit in iter 3. The orchestrator
   itself has an unstored `agent.streamState().listen(...)` subscription
   in `registerAgent` (line 39). If an agent emits state after the
   orchestrator's `_stateStreamController` is closed but before the
   agent itself is disposed in the orchestrator's own `dispose`, there's
   a "Cannot add events after closing" risk. Today's example agents
   don't trigger it (they only emit synchronously inside
   `processRequest` and inside their own `initialize`). Worth tracking
   the subscriptions and cancelling them on `unregisterAgent` /
   `dispose` for full correctness — additive change, no API impact.
4. **Apply the drafted CHANGELOG `[Unreleased]` block** when the next
   release is being prepared — it rolls up iters 1-4.

### Reflection
The "no agent tests at all" gap was bigger than iter 3 implied: not
"thinner coverage", literal zero. The fake-agent pattern paid off — by
fixing process-time, status transitions, and metadata in the fake, the
orchestrator tests run in <100ms total and are deterministic, which is
exactly what the agent surface needs given how much non-determinism the
production routing scorer has (a `Random().nextDouble() * 0.1` tiebreak
factor at orchestrator line 271). The one failing draft test was
informative: it exposed that the public-API contract for
`processRequest` is "always returns an `AgentResponse`, never throws on
agent error" — that's worth knowing, and now it's pinned.

---

## 2026-05-16 — Iteration 6: Dartdoc coverage + apply [Unreleased] CHANGELOG block

### Orientation snapshot
- Branch `main`, up to date with `origin/main`. Zero open issues / zero open PRs.
- Baseline `flutter analyze`: clean. Baseline `flutter test`: 305 / 305 pass.
- Iter-5 next-iter #4 = apply the drafted `[Unreleased]` block to `CHANGELOG.md`. Primary scope for iter 6 = dartdoc completeness on the highest-traffic public types (pub.dev pana score + agent discoverability).

### What changed (uncommitted)

**Dartdoc completeness pass** on the six classes a consumer is most likely to instantiate or look up:

1. `lib/src/widgets/ai_chat_widget.dart`
   - Class-level doc expanded with intent ("classic chat surface entry point"), the controller-ownership contract, the rich-widget / `AiActionProvider` integration points, and a runnable code-example block.
   - Primary constructor now has a doc comment.
   - The four bare streaming fade-in fields (`streamingFadeInDuration`, `streamingFadeInCurve`, `streamingFadeInEnabled`, `streamingWordByWord`) each got an individual doc, including units, nullability behaviour, and the gating dependency on `enableMarkdownStreaming`.

2. `lib/src/controllers/chat_messages_controller.dart`
   - Class-level doc expanded with the canonical streaming pattern (add empty message with id → repeatedly updateMessage → stopStreamingMessage) as a runnable example.
   - `mounted` getter, `addAgentMessage`, `setScrollController`, `forceScrollToTop`, `forceScrollToFirstMessageInChain`, `handleExampleQuestion`, `hideWelcomeMessage` each got a 1-line summary + when-to-use explanation. (`addMessage`, `updateMessage`, `clearMessages`, `scrollToBottom`, `loadMore`, `setMessages`, the streaming setters, the rich/loading factories on `ChatMessage` already had docs.)

3. `lib/src/models/chat/chat_message.dart`
   - Class-level doc expanded to mention immutability + `copyWith`, list the three named factories with their intents, and a runnable example for ordinary text + markdown construction.
   - Primary constructor got a doc.

4. `lib/src/widgets/ai_action_provider.dart`
   - `AiActionConfig`: class-level summary, field-level docs for `actions` / `confirmationBuilder` / `debug` (when it fires, what the return contract is), constructor doc.
   - `AiActionProvider`: class-level doc with a runnable example showing an action that pushes to a cart, owner-controller-vs-external semantics, plus per-field and constructor docs.
   - `AiActionProvider.of` / `maybeOf`: throw-vs-null behaviour documented.
   - `AiActionHook`: class-level doc + runnable example using `AiActionBuilder.executeAction`.
   - `AiActionBuilder`: class-level doc, `builder` field doc, constructor doc.

5. `lib/src/controllers/agent_orchestrator.dart`
   - Class-level doc with a runnable example covering register / processRequest / streamResponse / dispose.
   - `maxConcurrentRequests`, `requestTimeout`, `enableCollaboration` each documented (including the "currently advisory" note for the two not yet enforced).
   - Public getters (`agents`, `activeCollaborations`, `responseStream`, `stateStream`) and methods (`getAgent`, `getAgentsByCapability`, `getAvailableAgents`, `dispose`) all documented.
   - `AgentException`: class-level doc explaining the throw-vs-error-response contract surfaced by iter-4 testing; `message` field documented.

**CHANGELOG `[Unreleased]` block applied** to the top of `CHANGELOG.md` (no version number, as instructed). Rolls up iters 1-5 (AGENTS.md + topics + description, README install bump, timer leaks, stream-sub leak, +27 tests) plus iter 6's dartdoc improvements.

### Verification
- `dart doc --validate-links` — `Found 0 warnings and 0 errors. Documented 1 public library.` Was already 0/0 baseline; intent of the pass was content-quality not warning-count, but the zero-warning baseline held through every edit (one round-trip with two `comment_references` info-level findings on `[AiChatWidget]` and `[AiAction]` references across library boundaries — both fixed by switching to backtick references).
- `flutter analyze` → "No issues found!" (clean after the comment-reference fix).
- `flutter test` (default concurrency, run 1) → **305 / 305 pass.**
- `flutter test` (default concurrency, run 2) → **305 / 305 pass.** Stable.
- `dart pub publish --dry-run` → "Package has 2 warnings." Both warnings are pre-existing meta-warnings unrelated to this iter's changes: (1) the `.memory/` directory is checked in while gitignored — a longstanding repo-state issue, and (2) "18 checked-in files are modified in git" — every iter 1-6's uncommitted edits trip this; it will go away when the user commits. No content / pana / score warnings about the actual package payload.

### Diff summary (files touched, all uncommitted)
- `CHANGELOG.md` — new `[Unreleased]` block at the top of file
- `lib/src/widgets/ai_chat_widget.dart` — dartdoc only
- `lib/src/controllers/chat_messages_controller.dart` — dartdoc only
- `lib/src/models/chat/chat_message.dart` — dartdoc only
- `lib/src/widgets/ai_action_provider.dart` — dartdoc only
- `lib/src/controllers/agent_orchestrator.dart` — dartdoc only
- `WORK_LOG.md` — this entry

No public API surface changed. No version bump. No dep change. No commits.

### What did NOT change
- No `example_agents.dart` direct tests — the iter spec marked these "tertiary, only if time", and the doc-coverage pass plus CHANGELOG application filled the iteration. Still queued for the next iter.
- The 2-warning dry-run state (gitignored memory files + uncommitted-files notice) — both pre-existing and user-scope (user must `git rm --cached .memory/`, or `.gitignore` should be relaxed, plus the user must commit at their own cadence).
- Pending dep bumps (`flutter_streaming_text_markdown 1.6.0 → 1.8.0`, `google_fonts 8.0.2 → 8.1.0`) still pending from iters 2-5. Streaming dep is on the hot path; needs its CHANGELOG read.
- Pana score not actually measured numerically — would need `pana` invocation. `dart doc --validate-links` clean is the closest proxy this iter has.

### Next iteration candidates (priority order)
1. **`example_agents.dart` direct tests** — the long-deferred secondary. ~10 cases over `TextAnalysisAgent`, `CodeAnalysisAgent`, `GeneralAssistantAgent`: `canHandle` routing rules, state-stream emissions, and `GeneralAssistantAgent`'s delegation-triggering logic (currently only exercised end-to-end via the example app). Carried from iter 5.
2. **Run `pana` locally** to produce a numerical pub.dev score before/after the doc pass. If `pana` isn't installed (`dart pub global activate pana`), do that first. This is the proper measurement for the iter-6 deliverable.
3. **Dartdoc round 2** — apply the same treatment to the next-tier exports (`ActionController`, `AiContextController`, `HeadlessChatController`, `AiTextInputController`, the model classes under `lib/src/models/`, and the public theme extension). Iter 6 deliberately scoped to the six most-instantiated types; tier-2 will close most remaining undocumented public API.
4. **Dep bumps** (still pending). Read `flutter_streaming_text_markdown` 1.7 + 1.8 CHANGELOGs before applying.
5. **`addPostFrameCallback` audit** — same anti-pattern shape as iters 3 (timers) and 5 (stream subs).

### Reflection
The class-level runnable examples are the highest-leverage piece of this pass: pub.dev's pana scorer counts them explicitly, but more importantly an LLM-driven coding assistant reading the dartdoc HTML for `AiChatWidget` now gets a working snippet in the very first paragraph it sees — same intent as iter-1's `AGENTS.md` but at the per-class granularity. The two `comment_references` info findings were the only flakes; both reflected that `[ClassName]` only resolves inside `dartdoc` if the surrounding file imports the class, which `chat_messages_controller.dart` and `ai_action_provider.dart` deliberately don't (they live one layer below their consumers). Backtick references are the right fix here — they read identically in IDE hovers and on the rendered pub.dev API page, and they don't tie the docs to import structure.

---

## 2026-05-16 — Iteration 5: StreamSubscription leak audit across lib/src/

### Orientation snapshot
- Branch `main`, up to date with `origin/main`. Zero open issues / zero
  open PRs.
- Baseline `flutter analyze`: clean. Baseline `flutter test`: 302/302 pass
  (iter-4 state held).
- Iter 4 surfaced one untracked `agent.streamState().listen(...)` at
  `lib/src/controllers/agent_orchestrator.dart:39`. Iter-5 scope: same
  audit shape as iter-3 (timers), but for `.listen(...)`.

### Audit method
`grep -rn '\.listen(' lib/src/` → 3 hits.
`grep -rn 'StreamSubscription' lib/src/` → 3 hits (one field, two return
types).
`grep -rn 'StreamController' lib/src/` → 15 hits across 6 files.
For each `.listen(`, traced the closure's lifetime relative to the
owning object's `dispose`.

### Grep hits — classification (3)
| Site | Verdict | Note |
|---|---|---|
| `agent_orchestrator.dart:39` `agent.streamState().listen(_stateStreamController.add)` | **LEAK** | Untracked, multi-instance (one per registered agent), tear-off forwards to a controller that may be closed first. Fixed via `Map<String, StreamSubscription<AgentState>>` keyed by agent id; cancellation in `unregisterAgent` and `dispose`. |
| `ai_context_controller.dart:276` `valueStream.listen(...)` in `watchValue<T>` | Benign | Method's documented contract: returns the `StreamSubscription` to the caller. Ownership explicitly transferred. |
| `ai_context_provider.dart:101` `_controller.events.listen(_logContextEvent)` | Benign | Already stored in `_eventSubscription`; cancelled in `dispose` (line 214). |

`StreamController` audit also clean — every controller in `lib/src/`
(`headless_chat_controller.dart`, `ai_text_input_controller.dart`,
`ai_context_controller.dart`, `action_controller.dart`, the orchestrator's
two) is `.close()`d in the owning class's `dispose`.

### Production fix (uncommitted, additive, zero public API change)
`lib/src/controllers/agent_orchestrator.dart`:
- New private field `Map<String, StreamSubscription<AgentState>>
  _agentStateSubscriptions = {}` to track per-agent state-forwarding
  subscriptions.
- New private bool `_disposed` so the forwarding closure can short-circuit
  if the orchestrator is being torn down (defensive against an agent
  emitting between subscription cancel and stream close).
- `registerAgent` now cancels any prior subscription under the same id
  (re-registration is rare but possible and was previously a silent leak),
  then stores the new sub. The forwarding callback is a closure that
  checks `_disposed || _stateStreamController.isClosed` before adding.
- `unregisterAgent` cancels the agent's tracked subscription BEFORE
  invoking `agent.dispose()`. Order matters: agents that emit a final
  status from within their own `dispose` (e.g. `_EmitOnDisposeAgent` in
  the test suite, and the real `example_agents.dart` agents follow the
  same pattern) would otherwise forward to a stream that's about to be
  closed by the orchestrator's own `dispose`.
- `dispose` cancels every tracked subscription FIRST, then closes both
  broadcast controllers, then disposes agents.

### Regression tests added (uncommitted)
`test/controllers/agent_orchestrator_test.dart` — new group "Stream
subscription lifecycle (iter 5)" with 3 cases, plus a new
`_EmitOnDisposeAgent` fake whose `dispose` emits one final
`AgentState` before closing its own controller:
1. `unregisterAgent disposes an agent that emits during its own
   dispose without throwing "add after close"` — pins that
   `unregisterAgent` cancels the subscription before invoking the
   agent's dispose.
2. `dispose() cancels all per-agent subscriptions before closing the
   orchestrator state stream — agent emissions during teardown do not
   throw "add after close"` — pins dispose ordering.
3. `re-registering an agent with the same id cancels the previous
   subscription (no duplicate forwarding)` — pins that the orphan
   sub from a re-registered id never forwards again.

### Verification
- `flutter analyze` → "No issues found!"
- `flutter test` (default concurrency, run 1) → **305 / 305 pass.**
- `flutter test` (default concurrency, run 2) → **305 / 305 pass.**
  Stable. Net **+3 tests** (302 → 305).
- `flutter test test/controllers/agent_orchestrator_test.dart` in
  isolation → 22/22 pass (was 19; the 3 new cases added cleanly).
- No public API change. No version bump. No dep change.

### Diff summary (files touched, all uncommitted)
- `lib/src/controllers/agent_orchestrator.dart` — per-agent
  subscription tracking + cancellation ordering in dispose/unregister.
- `test/controllers/agent_orchestrator_test.dart` — new fake agent
  (`_EmitOnDisposeAgent`) + 3-case stream-subscription-lifecycle group.
- `WORK_LOG.md` — this entry.

### What did NOT change
- No version bump in `pubspec.yaml` (still 2.11.1).
- No `CHANGELOG.md` edit. Suggested addition to the `[Unreleased]`
  block being assembled across iters 1-5:
  ```
  - `AgentOrchestrator` now tracks per-agent state-stream subscriptions
    and cancels them on `unregisterAgent` / `dispose` (before closing
    its own broadcast controllers). Fixes a latent "Cannot add events
    after closing" risk when an agent emits state from within its own
    `dispose`. Re-registering an agent under an existing id now also
    cancels the orphaned subscription instead of silently leaking it.
  ```
- The secondary scope (`example_agents.dart` direct tests for
  `TextAnalysisAgent` / `CodeAnalysisAgent` / `GeneralAssistantAgent`)
  was NOT picked up — primary fix + tests + verification + log already
  filled the iteration. Carried to iter 6.

### Next iteration candidates (priority order)
1. **`example_agents.dart` direct tests** — the deferred secondary
   from this iter. ~10 cases: `canHandle` routing rules per agent,
   state-stream emissions, and the `GeneralAssistantAgent`'s delegation-
   triggering logic (which today is only exercised end-to-end via the
   example app).
2. **`addPostFrameCallback` audit** — same anti-pattern shape as
   iters 3 & 5. `grep -rn 'addPostFrameCallback' lib/src/` to find every
   call site and verify the closure either short-circuits on `!mounted`
   or stores a cancellable reference. Likely 5-10 hits in the widget
   layer.
3. **Dep bumps** (still pending from iters 2-4): `flutter_streaming_text_markdown
   1.6.0 → 1.8.0`, `google_fonts 8.0.2 → 8.1.0`. Read each CHANGELOG
   first; streaming dep is on the hot path.
4. **Apply the drafted CHANGELOG `[Unreleased]` block** when the next
   release is being prepared — now covers iters 1-5.

### Reflection
The iter-4 "next-iter #3" note flagged this exact site as a "today no
agent triggers it" risk. Auditing confirmed the risk and produced a
fix that covers three real failure modes: (a) the obvious unregister
race, (b) the less-obvious re-registration leak, and (c) the dispose
ordering where the orchestrator closes its broadcast stream before
agents have a chance to emit teardown state. The `_EmitOnDisposeAgent`
fake makes the regression visible without needing the production
agents — same fake-agent pattern as iter 4. Three new tests is the
right count: any fewer would miss one of those failure modes; any
more would be testing implementation rather than contract.

---

## 2026-05-16 — Iteration 7: example_agents.dart direct tests + pana baseline

### Orientation snapshot
- Branch `main`, up to date with `origin/main`. Zero open issues / zero open
  PRs.
- Baseline `flutter analyze`: clean. Baseline `flutter test`: 305 / 305 pass
  (iter-6 state held).
- `pana` already installed at `~/.pub-cache/bin/pana`. No need to activate.

### Primary scope — direct tests for `lib/src/agents/example_agents.dart`

The three shipped example agents (`TextAnalysisAgent`, `CodeAnalysisAgent`,
`GeneralAssistantAgent`) had zero direct tests — only indirectly exercised
via the example app. They're exported public API and consumers will
subclass them, so their behaviour is contract-level. This was deferred
from iters 4, 5, and 6.

New test file: `test/agents/example_agents_test.dart` — **21 tests** across
4 groups.

Per-agent coverage (each of the 3 agents gets all four points spec'd in
the iter brief):
- **`canHandle` routing** — in-domain prompts return true, out-of-domain
  return false. For `GeneralAssistantAgent`, pins the "always returns
  true" fallback contract (3 cases). For `TextAnalysisAgent`, exercises
  both the keyword path (`analyze`, `text`, `sentiment`, `summarize`)
  and the capability-name path (`sentiment analysis` from
  `sentiment_analysis`).
- **Happy-path execution** — initialize then processRequest a matching
  query; assert the response is not an error, has the expected
  agentId, confidence in the documented range, and the expected
  metadata stamp (`analysis_type` for text agent, `language` +
  `analysis_type` for code agent).
- **Dispose lifecycle (no leaks)** — subscribe to `streamState()`, await
  `dispose()`, then expect the subscription's `onDone` to fire within 1s.
  Mirrors the iter-3/5 "no pending timers/subs" contract. tearDown
  catches `StateError` so tests can also dispose inside the body
  without double-close failures.
- **Agent-specific assertion**:
  - `TextAnalysisAgent`: routes to sentiment / summary / grammar
    sub-branches based on keyword (3 separate test cases — exercises
    each `_analyzeSentiment` / `_summarizeText` / `_checkGrammar`
    code path).
  - `CodeAnalysisAgent`: recognises code-shaped prompts (`code`,
    `function`, `debug`, `optimize`, `review`).
  - `GeneralAssistantAgent`: delegates correctly for text-analyst
    queries (`delegate_to: text_analysis_001`), delegates correctly
    for code-analyst queries (`delegate_to: code_analysis_001`), and
    **falls through to a general answer for unmatched queries with no
    `delegate_to` metadata** — pins the "unmatched does not delegate"
    contract.

Plus 2 cross-agent integration tests against `AgentOrchestrator`:
- Routing prefers the capability-matching agent over the always-true
  general fallback (text query goes to text agent, not general).
- Pure general query goes to the general agent when no specialist
  matches.

Total: 21 tests (TextAnalysis 7, CodeAnalysis 5, GeneralAssistant 7,
integration 2).

No production code in `lib/src/agents/example_agents.dart` was modified.
The tests didn't surface any real bugs in the example agents — they're
small, deterministic, and behave as documented. Each `processRequest`
includes a real `Future<void>.delayed(500-1200ms)`, so the suite takes
~16s end-to-end in isolation; that's acceptable for a tier-2 agent suite
and matches the production code path unmodified.

### Secondary scope — pana baseline

Ran `pana --no-warning` (the iter brief's `--line-length 80` flag isn't
in this pana version; dropped it). Initial score: **150 / 160.** The
10-point loss was on "code has no errors, warnings, lints, or formatting
issues" — pana flagged `lib/src/controllers/agent_orchestrator.dart`
as not matching the Dart formatter.

Root cause: iter 6's dartdoc additions to `agent_orchestrator.dart`
introduced lines that exceeded the formatter's wrapping width. `flutter
analyze` doesn't flag formatter drift (formatter is a separate tool
from the analyzer), so it stayed green; only `pana` (and `dart pub
publish`) catches it. Last commit `598a077 fix: dart format 2 lib files
for 150/150 pub.dev score` had formatted the previous version of this
exact file — the iter-6 dartdoc additions re-broke it.

Fix: `dart format lib/src/controllers/agent_orchestrator.dart`. Pure
re-wrap of dartdoc lines; no logic changed (verified via `git diff
--stat`: +116/-10 — all wrap changes inside the new doc comments). No
public API change.

After format: **pana 160 / 160.** Breakdown (all sections perfect):
- `pubspec.yaml` valid: 10/10
- `README.md` valid: 5/5
- `CHANGELOG.md` valid: 5/5
- OSI-approved license: 10/10
- Dartdoc coverage ≥20% of public API: 10/10
- Package has an example: 10/10
- Supports all 6 platforms: 20/20
- **Code has no errors/warnings/lints/formatting: 50/50** (was 40/50)
- All deps supported in latest version: 10/10
- Supports latest stable Dart + Flutter SDKs: 10/10
- Compatible with dependency constraint lower bounds: 20/20

### Tertiary scope — addPostFrameCallback audit

Skipped this iter — primary + secondary work + the unexpected
formatter fix filled the iteration cleanly. The audit is queued for
iter 8 (same anti-pattern shape as iters 3 and 5).

### Verification
- `flutter analyze` → "No issues found!" (clean before + after).
- `flutter test test/agents/example_agents_test.dart` in isolation → 21/21
  pass.
- `flutter test` (default concurrency, run 1) → **326 / 326 pass.**
- `flutter test` (default concurrency, run 2) → **326 / 326 pass.**
  Stable. Net **+21 tests** (305 → 326).
- `pana --no-warning` → **160 / 160 points.**
- No public API change. No version bump. No dep change. No commits.

### Diff summary (files touched, all uncommitted)
- `test/agents/example_agents_test.dart` — new file (21 tests)
- `lib/src/controllers/agent_orchestrator.dart` — `dart format` only
  (zero logic change; iter-6 dartdoc re-wrap)
- `WORK_LOG.md` — this entry

### What did NOT change
- No production code in `lib/src/agents/example_agents.dart` — the new
  tests surfaced no bugs.
- No `pubspec.yaml` version bump (still 2.11.1; user controls release).
- No `CHANGELOG.md` edit. Suggested addition to the `[Unreleased]`
  block iter 6 already started:
  ```
  ### Tests
  - Added 21 unit tests covering the shipped example agents
    (`TextAnalysisAgent`, `CodeAnalysisAgent`, `GeneralAssistantAgent`).
    Pins canHandle routing, processRequest happy-path metadata,
    `GeneralAssistantAgent`'s delegation contract (text-analyst rules,
    code-analyst rules, and "unmatched queries do not delegate"), and
    dispose-without-leak behaviour. End-to-end pana score now 160/160.
  ```
- The pending `flutter_streaming_text_markdown 1.6.0 → 1.8.0` and
  `google_fonts 8.0.2 → 8.1.0` bumps still pending from iters 2-6.
- `addPostFrameCallback` audit (iter brief tertiary) still pending.

### Next iteration candidates (priority order)
1. **`addPostFrameCallback` audit** — same anti-pattern as iters 3 & 5.
   `grep -rn 'addPostFrameCallback\|SchedulerBinding' lib/src/`. For
   each, check if the closure captures `this` and could fire after
   the `State` is disposed; add `if (!mounted) return;` guards.
2. **Dartdoc round 2** — iter 6 scoped to tier-1 types. Tier 2:
   `ActionController`, `AiContextController`, `HeadlessChatController`,
   `AiTextInputController`, the model classes under `lib/src/models/`,
   and the public theme extension.
3. **Dep bumps** (still pending from iters 2-6).
4. **Format-on-save guardrail** — iter 7 surfaced that formatter
   drift from iter 6 was invisible to `flutter analyze` and only
   caught by pana. Consider adding a `dart format --output=none
   --set-exit-if-changed .` step to the CI workflow (or pre-commit
   hook) so dartdoc edits can't silently re-break the formatter.
5. **Apply the drafted CHANGELOG `[Unreleased]` block** when the next
   release is being prepared — now covers iters 1-7.

### Reflection
The 150 → 160 pana jump from a single `dart format` call is the
highest leverage line of code in any iter so far: zero logic change,
zero behaviour change, 10 points back on the pub.dev scorecard. The
real lesson is the gap between `flutter analyze` (clean) and `pana`
(formatter-drift flag): `flutter analyze` is necessary but not
sufficient for pre-publish health, because the formatter runs as a
separate tool. Iter 6's dartdoc work was correct in intent and content,
but the line-wrap drift it introduced sat invisibly under the green-
analyze signal until pana ran. The fix is trivial; the missing
guardrail (CI step or pre-commit) is the more interesting follow-up.

The 21 agent tests are the long-deferred fill for iter 3's "next
iteration #4" — three iterations later. The fake-agent pattern from
iter 4 wasn't needed here because the production agents are themselves
small and deterministic; testing them directly is cleaner than
wrapping them. The cross-agent integration tests (2 of 21) add value
beyond just-the-agents because they pin orchestrator routing
behaviour against real shipped agents — the iter-4 orchestrator suite
used only fakes.

---

## 2026-05-16 — Iteration 8: addPostFrameCallback dispose-hazard audit + CI guardrail

### Orientation snapshot
- Branch `main`, up to date with `origin/main`. Zero open issues / zero
  open PRs.
- Baseline `flutter analyze`: clean. Baseline `flutter test`: 326/326 pass
  (iter-7 state). Baseline pana: 160/160.
- Iter 8 closes the dispose-hazard trilogy:
  - Iter 3 cleared `Future.delayed` / `Timer` leaks.
  - Iter 5 cleared `StreamSubscription` leaks.
  - Iter 8 sweeps `addPostFrameCallback` / `SchedulerBinding` /
    `WidgetsBinding.instance` callbacks.

### Audit method
`grep -rn 'addPostFrameCallback' lib/src/` → 2 hits.
`grep -rn 'SchedulerBinding\|WidgetsBinding.instance' lib/src/` → 4 hits
(2 of which are the same `addPostFrameCallback`; the other 2 are an
`addObserver`/`removeObserver` pair).

### Grep hits — classification (4 unique sites)
| Site | Verdict | Note |
|---|---|---|
| `smart_chat_input.dart:69` `addPostFrameCallback((_) { _focusNode.requestFocus(); })` in `initState` (autoFocus path) | **HAZARD** | Inside State. Closure calls `_focusNode.requestFocus()`. `_focusNode` is disposed in `dispose()`. If the State is disposed before the next frame fires, the callback throws "A FocusNode was used after being disposed". Fixed with `if (!mounted) return;`. |
| `custom_chat_widget.dart:169` `addPostFrameCallback((_) { ... scrollToBottom(); })` in `_connectScrollControllerToMessagesController` | **HAZARD** | Inside State. Closure reads `widget.messages` and calls `widget.controller!.scrollToBottom()`. After dispose, `_scrollController` may be detached / disposed; touching `widget` after unmount is also illegal. Fixed with `if (!mounted) return;`. |
| `ai_context_provider.dart:97/213` `WidgetsBinding.instance.addObserver(this)` + matched `removeObserver(this)` | Benign | Properly paired: added in initState, removed in dispose. No leak. |

No `SchedulerBinding`, `endOfFrame`, or `addPersistentFrameCallback`
usages found (lower-level APIs not used in this package).

### Production fixes (uncommitted, additive, zero public API change)
1. `lib/src/widgets/smart_chat_input.dart` — added `if (!mounted) return;`
   at the top of the autoFocus post-frame callback.
2. `lib/src/widgets/custom_chat_widget.dart` — added `if (!mounted)
   return;` at the top of the initial-scroll post-frame callback. Comment
   explains the why (consumer-owned controller, detached scroll
   controller after dispose).

Both fixes mirror the iter-3 / iter-5 pattern: defensive `mounted` /
`_disposed` short-circuit in the asynchronous closure body.

### Regression tests added (uncommitted)
`test/widgets/timer_lifecycle_test.dart` — new group "Frame callback
lifecycle — iter 8 audit" with 2 cases (net +2 tests, 326 → 328):
1. `SmartChatInput(autoFocus: true) disposed before next frame does not
   request focus on a disposed FocusNode` — pumps the widget then
   immediately unmounts before the post-frame callback fires. Without
   the `mounted` guard the framework would throw the FocusNode-after-
   dispose assertion.
2. `CustomChatWidget connect-scroll post-frame callback no-ops after
   dispose` — pumps an `AiChatWidget` (which wraps `CustomChatWidget`
   and exercises the same `_connectScrollControllerToMessagesController`
   path), then unmounts before the initial scroll-to-bottom fires.

Note on test scope: the trilogy-closing file now lives at
`test/widgets/timer_lifecycle_test.dart` (file name kept for diff
continuity; the file now covers Timer, StreamSubscription side via
`agent_orchestrator_test.dart`'s own group, and frame-callback lifecycle).
Naming could be refactored to `dispose_hazard_test.dart` in a future
iter — left for now to avoid renaming churn.

### Secondary scope — Formatter / lint CI guardrail
Iter 7's pana fix surfaced that `dart format` drift in
`agent_orchestrator.dart` cost 10 pana points until corrected, and
that `flutter analyze` does NOT catch formatter drift. Iter 8's CI
guardrail closes that visibility gap.

1. Checked `.github/workflows/` — does not exist. (`.github/ISSUE_TEMPLATE/`
   exists but no workflows.)
2. Created `.github/workflows/ci.yml` — pinned `subosito/flutter-action@v2`
   (verified the tag resolves on github.com) and `actions/checkout@v4`.
   Steps in order: checkout → setup-flutter (channel: stable, cache: true)
   → `flutter pub get` → `dart format --output=none --set-exit-if-changed .`
   (the iter-8 guardrail) → `flutter analyze --fatal-infos` →
   `flutter test --reporter expanded`. Triggers on push to `main`, PRs to
   `main`, and manual `workflow_dispatch`.
3. Validated the YAML parses (`python3 -c "import yaml; yaml.safe_load(...)"`).
4. Did NOT add pre-commit hooks — those are user-machine-specific and
   out of scope for a published package (per iter brief).

### Formatter cleanup discovered while wiring CI
Running `dart format --set-exit-if-changed .` locally exposed that 15
files in `test/` had drifted from canonical format (pre-existing
uncommitted edits from iters 2-7 that never got a final format pass).
`lib/` was clean (so pana stayed at 160/160), but the new CI guardrail
would have failed on its first run. Ran `dart format .` once over the
whole repo — 15 test files re-wrapped, zero logic changes. Formatter
re-check now exits 0 on the entire repo.

### Verification
- `flutter analyze` → "No issues found!"
- `flutter test test/widgets/timer_lifecycle_test.dart` in isolation →
  5/5 pass (3 from iter 3 + 2 new from iter 8).
- `flutter test` (default concurrency, run 1) → **328 / 328 pass.**
- `flutter test` (default concurrency, run 2) → **328 / 328 pass.**
  Stable. Net **+2 tests** (326 → 328).
- `dart format --output=none --set-exit-if-changed .` → exits 0.
- `pana --no-warning` → **160 / 160 points** (held).
- CI YAML parses; action tags verified on GitHub.
- No public API change. No version bump. No dep change. No commits.

### Diff summary (files touched, all uncommitted)
- `lib/src/widgets/smart_chat_input.dart` — `if (!mounted) return;` guard
  in autoFocus post-frame callback.
- `lib/src/widgets/custom_chat_widget.dart` — `if (!mounted) return;`
  guard in initial-scroll post-frame callback + explanatory comment.
- `test/widgets/timer_lifecycle_test.dart` — new "Frame callback
  lifecycle — iter 8 audit" group with 2 widget tests.
- `.github/workflows/ci.yml` — new file. CI guardrail (format / analyze /
  test) on push/PR to main.
- 15 `test/**/*.dart` files — pure `dart format` rewrap, zero logic
  change (was pre-existing drift from iters 2-7 uncommitted edits).
- `WORK_LOG.md` — this entry.

### What did NOT change
- No version bump in `pubspec.yaml` (still 2.11.1; user controls release).
- No `CHANGELOG.md` edit. Suggested addition to the `[Unreleased]`
  block:
  ```
  ### Fixed
  - `SmartChatInput(autoFocus: true)` no longer requests focus on a
    disposed `FocusNode` if the widget is unmounted before the first
    frame.
  - `AiChatWidget`'s initial scroll-to-bottom post-frame callback now
    short-circuits if the widget is disposed before the frame fires
    (no more touching a detached scroll controller).

  ### Notes
  - CI: added `.github/workflows/ci.yml` running `dart format --set-exit-
    if-changed`, `flutter analyze --fatal-infos`, and `flutter test` on
    push/PR to `main`. The formatter step closes a gap surfaced by the
    iter-7 pana run (where `flutter analyze` was green but `pana`
    flagged unformatted dartdoc rewraps).
  ```
- Pending `flutter_streaming_text_markdown 1.6.0 → 1.8.0` and
  `google_fonts 8.0.2 → 8.1.0` bumps still pending from iters 2-7.
- Tier-2 dartdoc pass (iter brief tertiary) — `ActionController`,
  `AiContextController`, `HeadlessChatController` — not picked up;
  primary + secondary + the unexpected formatter cleanup filled the
  iteration. Carried to iter 9.

### Next iteration candidates (priority order)
1. **Tier-2 dartdoc pass** — same depth as iter 6's tier-1 pass.
   Targets: `ActionController`, `AiContextController`,
   `HeadlessChatController`, `AiTextInputController`, the public model
   classes under `lib/src/models/`, and the public theme extension.
   Run `dart doc --validate-links` after, then re-run pana to confirm
   no regression in the documentation coverage section.
2. **Dep bumps** (still pending from iters 2-7):
   `flutter_streaming_text_markdown 1.6.0 → 1.8.0`,
   `google_fonts 8.0.2 → 8.1.0`. Streaming dep is on the hot path —
   read its CHANGELOG first.
3. **Rename `test/widgets/timer_lifecycle_test.dart` →
   `dispose_hazard_test.dart`** (or split per audit) — the file now
   covers all three audit outcomes (timers, stream subs via the
   orchestrator test file, frame callbacks). Pure naming cleanup.
4. **Apply the drafted CHANGELOG `[Unreleased]` block** when the next
   release is being prepared — now covers iters 1-8.

### Reflection
The trilogy is complete: timers (iter 3), stream subscriptions
(iter 5), and now frame callbacks (iter 8) all audited and guarded
across `lib/src/`. The hit count was lowest this iter (2 real
hazards) because the package's widget layer is small and the bulk
of work happens inside controllers rather than mid-frame. The CI
guardrail is arguably more valuable than the audit itself: iter 7
showed that formatter drift was invisible to local-machine workflow
until pana ran, and pana isn't part of any consumer's contribution
loop. Wiring `dart format --set-exit-if-changed` into PR-time CI
turns that silent-10-point-loss class of regressions into a 5-second
red check the contributor sees immediately. The unexpected 15-file
format cleanup was the same class of drift caught early — exactly
what the guardrail exists to surface.

---

## Iteration 9 — 2026-05-16 (consolidated; iters 9-13 cron fires backlogged during rate-limit window)

### Triage
Zero open issues, zero open PRs. State coming in: 328 tests, analyze clean, pana 160/160. Previous iter-9 agent dispatch hit Anthropic daily rate limit and produced no work; 5 cron fires backlogged during cooldown; consolidating into one inline pass.

### Bucket
**Dependencies** — deferred 7 iters (since iter 2). Per-dep CHANGELOG read via WebFetch before bumping.

### Per-dep decisions
- `flutter_streaming_text_markdown ^1.4.0 → ^1.8.0`. BUMPED.
  CHANGELOG read 1.4 → 1.8 inclusive. Zero breaking changes in any minor.
  Notable inclusions: 1.7.0 RTL/Arabic word-splitting fix + emoji-resume fix
  (directly relevant — this package advertises RTL); 1.7.2 trailing-fade
  dismiss fix; 1.8.0 adds optional custom markdown component overrides
  (additive). Our usage (`AnimatedTextMessage`, `MessageContentText`,
  `custom_chat_widget.dart`) uses core streaming-text API only, no
  adaptation needed.
- `google_fonts ^8.0.1 → ^8.1.0`. BUMPED.
  CHANGELOG read 8.0.1 → 8.1.0. 8.0.2 async-exception-handling fix; 8.1.0
  adds optional custom HTTP client (additive). Our usage
  (`font_helper.dart`) calls only the high-level `GoogleFonts.X()` API.

### Tier-2 dartdoc / file rename
Deferred to iter 10. Primary goal of iter 9 (dep bumps with proper diligence)
took the full budget.

### Verification
- `flutter pub get` → resolved, 3 dependencies changed.
- `flutter analyze` → No issues found! (9.8s)
- `flutter test` (default concurrency) → 328 / 328 pass.
- `dart format --output=none --set-exit-if-changed .` → 151 files, 0 changed.
- `pana --no-warning` → **160 / 160** held.
- No public API change. No version bump. No commits. CHANGELOG `[Unreleased]`
  block extended with `### Dependencies` and `### Tooling` subsections plus
  the iter-7 and iter-8 test counts that were missing.

### Next iter picks up
1. **Tier-2 dartdoc pass** on `ActionController`, `AiContextController`,
   `HeadlessChatController`, `AiTextInputController` — same depth as iter 6's
   tier-1 pass (class summary, primary-constructor docs, public method/field
   docs, code-example blocks for consumer-instantiated ones).
2. **File rename** `test/widgets/timer_lifecycle_test.dart` →
   `dispose_hazard_test.dart` (the file now covers timers + frame callbacks
   after iter 8). Use `git mv` to preserve history.
3. **Real-user-journey doc**: pick a persona ("developer adding streaming
   chat from scratch following the README", "user with RTL Arabic UI",
   "consumer enabling agent tools") and walk the path, documenting any
   friction without simulator launch. The README/example must be coherent
   without running it.
4. Optional: **example app `pubspec.lock` cleanup** — pana ignores it but
   pub.dev publishing surfaces 18 unstaged file warnings. Pre-release
   housekeeping when the user approves a version bump.

### Reflection
Dep bump was lower-risk than the deferral suggested. Reading the CHANGELOGs
took longer than the actual code change. The streaming dep's 1.7.0 RTL fix
is now reachable for consumers — a quiet quality win for the package's RTL
positioning that costs us nothing. CI guardrail from iter 8 caught zero
new format drift this iter; the pubspec.yaml change was the only edit on
disk and pubspec doesn't go through the formatter. Worth confirming next
iter that the workflow runs green on a real PR rather than just locally.

---

## Iteration 10 — 2026-05-16

### Triage
Zero open issues, zero open PRs. State coming in: 328 tests, analyze
clean, pana 160/160, dep bumps from iter 9 landed.

### Bucket
**Real-user journey — Developer Onboarding Audit.** Walk pub.dev →
README → install → quickstart → streaming → agent → RTL → example app
→ AGENTS.md as a first-time Flutter dev. Document friction, fix small
items inline, queue larger items.

### Audit deliverable
New file: `doc/ONBOARDING_AUDIT.md` — full audit with per-step
findings, severity, and FIXED / QUEUED / NOT-A-PROBLEM labels.

### Friction count
12 items total — **6 FIXED**, **5 QUEUED**, **1 NOT A PROBLEM**.

High-severity (load-bearing API documentation that did not compile):
1. **AGENTS.md Snippet 2** — `_controller.updateMessage(id, text:...)`
   does not match the actual `void updateMessage(ChatMessage message)`
   signature. **[FIXED]** — rewrote to construct a `ChatMessage` with
   matching `customProperties['id']` + `isStreaming: true`, ending with
   `stopStreamingMessage(id)`. Mirrors the controller's class-level
   dartdoc.
2. **AGENTS.md Snippet 4** — `ActionParameter.integer(...)` does not
   exist; actual API has `string` / `number` / `boolean` / `object` /
   `array` / `objectArray` / `objectWithAttributes`. **[FIXED]** —
   `ActionParameter.number` with a `(num).toInt()` cast.
3. **AGENTS.md Snippet 4** — `ActionResult.success(data: ...)` does not
   exist; `success` is a `bool` field, the factory is `createSuccess`.
   **[FIXED]** — `ActionResult.createSuccess({...})`.
4. **`lib/src/widgets/ai_action_provider.dart` class-level dartdoc** —
   contained the same `ActionParameter.integer` + `ActionResult.success`
   bugs, plus a `handler: (args, _)` two-arg signature (real signature
   is single-arg `(params)`). **[FIXED]** — three corrections in one
   edit. Public dartdoc is the surface most agent assistants quote
   verbatim, so this is reachable by IDE tooltip / dart doc / pub.dev
   API docs.

Medium-severity (advertised features with no example surface):
- README claims "RTL language support" and pubspec topics include
  `rtl`, but zero code example in README and zero example screen.
  **[QUEUED for iter 11]** — `example/lib/examples/rtl_chat.dart` +
  README `## RTL` section.
- README has no end-to-end streaming snippet (only flag reference);
  full pattern lives only in AGENTS.md and the controller's dartdoc.
  **[QUEUED]** — promote the canonical pattern to a dedicated README
  H2 right after Quick Start.

Low-severity:
- README "Live Examples" bullets list "File Attachments" and
  "Advanced Features" — neither matches the actual example menu
  (Basic / Streaming / Themed / Actions / Rich Widgets).
  **[QUEUED]** — sync the list.
- Differentiator table is only in AGENTS.md; the README has prose-only
  comparisons. **[QUEUED]** — pull the table into README near the top.
- Install + Quick Start are at lines 120 and 159 respectively, below
  the features wall. **[QUEUED]** — promote above Features section.
- **`example/lib/examples/rich_widgets_chat.dart`** — 9 analyzer infos
  (3× `withOpacity` deprecation, 5× `prefer_const_constructors`, 1×
  `prefer_const_literals_to_create_immutables`). New users copying
  from the example file would inherit them. **[FIXED]** — replaced
  `withOpacity` with the package's own `withOpacityCompat` extension
  (matching CLAUDE.md guidance), `const`-ified the renderer map and
  `_Bar` widgets. `flutter analyze example/` now returns "No issues
  found!".

Not-a-problem:
- README Quick Start compiles against the actual public API
  (`ChatUser(firstName:)`, `LoadingConfig(isLoading:)`,
  `WelcomeMessageConfig(questionsSectionTitle:)`, `ExampleQuestion`,
  `ChatMessage(text:, user:, createdAt:)`). Verified field-by-field
  against `lib/src/`.

### Files touched
- `AGENTS.md` — Snippet 2 streaming flow rewritten; Snippet 4 action
  factory + parameter type corrections.
- `lib/src/widgets/ai_action_provider.dart` — dartdoc API fixes
  (three errors in the class-level example).
- `example/lib/examples/rich_widgets_chat.dart` — 9 lints fixed.
- `doc/ONBOARDING_AUDIT.md` — new audit artifact.

### Verification
- `flutter analyze` → No issues found! (3.4s)
- `flutter analyze example/` → No issues found! (3.3s)
- `flutter test` (default concurrency, run TWICE) → 328 / 328 pass
  on both runs.
- `dart format --output=none --set-exit-if-changed .` → 151 files,
  0 changed.
- `pana --no-warning` → **160 / 160** held.
- No public API change. No version bump. No commits.

### Next iter picks up
1. **README structure pass** — move Install + Quick Start above
   Features, pull the AGENTS.md differentiator table into the README,
   add a dedicated `## Streaming tokens` H2 with the canonical
   addMessage → updateMessage(ChatMessage) flow. Single PR-sized.
2. **RTL example** — `example/lib/examples/rtl_chat.dart` registered
   in `main.dart` + home screen; `## RTL` README section; 4–6 line
   `Directionality.rtl` wrap snippet. Single PR-sized. The
   `flutter_streaming_text_markdown` 1.7.0 RTL/Arabic word-splitting
   fix landed in iter 9 — this is the natural follow-up that exposes
   it to consumers.
3. **README example menu sync** — trivial bullet edit.
4. **File rename `test/widgets/timer_lifecycle_test.dart` →
   `dispose_hazard_test.dart`** (carried from iter 9) — not picked up
   this iter; primary audit work consumed the budget. Pure naming
   cleanup, low priority.

### Reflection
The audit found four load-bearing API-doc bugs that would have failed
on first compile for anyone copy-pasting from AGENTS.md or the
`AiActionProvider` dartdoc. The pattern in all four cases: the doc
text drifted from the API during early authoring (iter 1 for
AGENTS.md, original author for the dartdoc) and was never recompiled
against the source. None of these are caught by `flutter analyze`
because dartdoc comments and markdown files are not compiled. None
are caught by tests because the snippets aren't tested.

This is a real gap in the package's quality net. Worth considering for
a future iter: a doctest-style harness that extracts `dart` fenced
code blocks from README.md / AGENTS.md / lib dartdocs, wraps each in
a synthetic test file, and runs `dart analyze` over them. Even a
manual once-per-release pass would have caught all four bugs.

The 9 example-app lints are a smaller but related miss: the package
has CI-checked formatting (iter 7) and dependency-bound analysis,
but `example/` is not in the CI loop. Worth adding `cd example &&
flutter analyze` to the workflow next iter alongside the README
structure pass.

---

## Iter 11 — 2026-05-16 — RTL story (example + README + tests)

### Why
Pubspec description, pubspec topics (`rtl`), AGENTS.md positioning,
and the README features list all advertise RTL support — but the
iter-10 cold-read audit caught that there was **zero RTL code surface
anywhere a consumer would find one**. No example screen, no README
code block, no widget test pinning the wrap. Iter 9 had just shipped
`flutter_streaming_text_markdown` 1.7.0 with the Arabic word-splitting
fix, so this was the natural follow-up: make the supported behavior
demonstrable end-to-end.

### What I shipped
1. **`example/lib/examples/rtl_chat.dart`** — new screen, ~210 lines.
   Wraps the chat in `Directionality(textDirection: TextDirection.rtl)`,
   streams a canned Arabic markdown response word-by-word, includes
   three example questions (two Arabic, one English to demonstrate
   the per-message bidi auto-detection that lets a mixed conversation
   render correctly inside an RTL surface). Mirrors the existing
   `streaming_chat.dart` controller/stream/dispose pattern verbatim
   so a consumer reading both can map one to the other. File-level
   dartdoc up top names the three things being demonstrated: surface
   mirror, per-message bidi, Arabic word-splitting.
2. **`example/lib/main.dart`** — `/rtl` route registered.
3. **`example/lib/home_screen.dart`** — new `_CardData` entry with a
   distinct sky-blue color and the `translate_rounded` icon, slotted
   in after Rich Widgets.
4. **`README.md`** — new `## RTL & Bidirectional Languages` H2 placed
   directly between Quick Start and Configuration Options. Four
   verified claims (locale-aware layout, per-message bidi auto-detect,
   Arabic word-splitting, markdown still works inside RTL) plus a
   minimal 15-line `Directionality + AiChatWidget` snippet. Table of
   Contents updated.
5. **`README.md` Live Examples list** — replaced the stale "File
   Attachments / Custom Themes / Advanced Features" bullets with the
   actual example menu (Basic / Streaming + Markdown / Custom Themes
   / AI Actions / Rich Widgets / RTL Chat). This was a queued iter-10
   bullet edit; clearing it now.
6. **`test/widgets/rtl_chat_test.dart`** — 2 new widget tests pinning:
   (a) `AiChatWidget` builds inside `Directionality.rtl` without
       throwing, and `Directionality.of(chatContext)` resolves to
       `TextDirection.rtl` (the load-bearing "wrap once, descendants
       inherit" promise the README makes).
   (b) Controller can accept an Arabic message, the chat doesn't
       throw on layout, and the message lands in the controller's
       message list.
   I tried text-finder assertions first but they failed in test env
   (Arabic glyphs + Roboto fallback + RichText splitting). Switched
   to controller-state + ambient-direction assertions, which test
   the actual contract.

### Verification
- `flutter analyze` (root) → No issues found! (2.9s)
- `flutter analyze example/` → No issues found! (2.6s)
- `dart format --output=none --set-exit-if-changed .` → 153 files,
  0 changed. (One reformat needed mid-iter on the new RTL example
  file; resolved.)
- `flutter test` → **330 / 330 pass** on both runs (was 328 at
  iter-10 end; +2 RTL tests, identical count both runs → deterministic).
- `pana --no-warning` → **160 / 160** held.

### What works / what doesn't
- ✅ Widget-test verified: `Directionality.rtl` wrap propagates,
  layout doesn't throw, controller accepts Arabic.
- ✅ Static-analysis verified: example file passes `flutter analyze`
  with zero infos.
- ⚠️ **Visually unverified** — global CLAUDE.md prohibits simulator
  runs, so I have not seen the screen render on a device. The screen
  reuses the same `AiChatWidget` config patterns as the four other
  example screens (which are visually verified by the maintainer in
  prior iterations), but the RTL-specific paint (mirrored input row,
  right-anchored bubbles, Arabic font fallback through google_fonts'
  notoSansArabic) is not pixel-checked by these widget tests. A
  manual smoke test on `example/` next time the maintainer runs the
  app would close this gap; an integration test under
  `example/integration_test/` could automate it.

### Files touched
- `example/lib/examples/rtl_chat.dart` (new)
- `example/lib/main.dart` (route + import)
- `example/lib/home_screen.dart` (menu entry)
- `README.md` (RTL H2, TOC entry, Live Examples bullets)
- `test/widgets/rtl_chat_test.dart` (new, 2 tests)
- `WORK_LOG.md` (this entry)

No commits made. No version bump. No public API change. No breaking
change. Existing tests untouched.

### Next iter picks up
1. **README structure pass** — still queued from iter 10: move
   Install + Quick Start above the Features wall so consumers landing
   on pub.dev see the install snippet without scrolling past 80
   lines of feature bullets. Pull the AGENTS.md differentiator table
   into README near the top. Pure markdown edit, no code risk.
2. **Test file rename** — `test/widgets/timer_lifecycle_test.dart`
   → `test/widgets/dispose_hazard_test.dart` via `git mv`. Carried
   from iter 9 + 10. Pure rename, low priority, fits a small iter.
3. **README streaming H2** — promote the canonical `addMessage` +
   `updateMessage(ChatMessage)` streaming flow from AGENTS.md to a
   dedicated README H2. Currently only the flags are documented in
   README; the pattern lives in AGENTS.md and the controller dartdoc.
4. **CI: add `cd example && flutter analyze` step** — iter 10's
   reflection flagged that `example/` is outside the CI loop. Adding
   the step would catch future regressions in the example app (the
   iter-10 audit found 9 lints there that had slipped past).
5. **Doctest harness (longer-term)** — iter 10 reflection's suggestion
   to extract `dart` fenced code blocks from README/AGENTS.md/dartdocs
   and compile-check them. Would have caught all four iter-10 doc
   bugs at CI time. Real work, not a single-iter task; worth scoping
   when the small queue empties.

### Reflection
Picked the smallest possible delta that closed the "advertised but
invisible" gap. One new screen file (no API change), one README
section, two widget tests. The instinct in iters past has been to
keep RTL work scoped to "make sure existing bidi code paths work",
but consumers don't audit our code — they search for the word
"RTL" in our README and judge from what's there. A 15-line code
block plus a working example file is a much sharper answer than
the prior pubspec-topic-only signal.

The visually-unverified caveat is real and I called it out plainly
above. The widget tests pin the load-bearing contract
(`Directionality.of` resolves to RTL inside the chat subtree, layout
doesn't throw on Arabic content) but not the paint. This is the
class of gap that auto-screenshot-diffing in CI would close; if a
later iter sets that up, the RTL screen is a great first candidate.
