**Priority:** P1
**Component:** Package-wide config surface
**Origin:** Issue #41 Phase 0.5 (unchecked item)

**Problem:** Historical bug pattern: documented parameters that silently do nothing (#40, #30, #18,
#20, #9, #38, #24, #28, #3, #6 — all fixed individually, but no systematic guard exists).

**Acceptance criteria:**
- [x] Enumerate every public, documented config knob across `AiChatWidget`, `MessageOptions`,
      `InputOptions`, `ScrollBehaviorConfig`, `CustomThemeExtension`, etc. — first pass done via a
      script cross-referencing declared `final` fields in `ai_chat_widget.dart` / `ai_chat_config.dart`
      / `chat_spacing_config.dart` against every test file; found 31/71 fields with zero mention in
      `test/`. Still need the same pass over `MessageOptions`, `InputOptions`, `CustomThemeExtension`,
      and the other model files not yet covered by the script.
- [~] For each knob without an existing test asserting visible effect, add one — IN PROGRESS. Done
      so far: `enableMathRendering` (was wired but untested), `LoadingConfig.typingIndicatorColor`/
      `.typingIndicatorSize` (were genuinely DEAD — see below — now wired + tested),
      `streamingFadeInEnabled`/`.streamingFadeInDuration`/`.streamingFadeInCurve` (confirmed wired,
      added coverage), `AiChatWidget.paginationConfig` (was genuinely DEAD — see below — now wired +
      tested).
      Correction from the first pass: several of the originally-flagged 31 fields belong to the
      already-`@Deprecated`-at-the-class-level `AiChatConfig` shim (`showTimestamp`, `userName`, plus
      `aiName`/`markdownStyleSheet`/etc. duplicated there) — those are EXPECTED to be unwired (the
      whole class is legacy/unused by `AiChatWidget`) and are OUT OF SCOPE for this sweep; don't
      re-flag them. Remaining real (non-`AiChatConfig`) untested knobs still to check:
      `autoLoadOnScroll`, `cacheExtent` (PaginationConfig, confirmed wired via
      `ListView.builder.cacheExtent` — just needs a test), `distanceToTriggerLoadPixels`,
      `loadMoreDebounceTime`, `loadingIndicatorOffset`, `loadMoreIndicator`, `loadingWidgetMargin`,
      `loadingWidgetPadding`, `markdownStyleSheet` (the live one on `MessageOptions`/`AiChatWidget`,
      not the `AiChatConfig` duplicate), `messageBubbleInnerPadding`, `messageBubbleOuterPadding`,
      `messageFooterTopPadding`, `messageListPadding`, `messageMediaSpacing`,
      `messageUsernameBottomPadding`, `quickRepliesPadding`, `scrollThreshold` (also genuinely DEAD,
      found alongside `enableHapticFeedback` — "Scroll position threshold to trigger loading (0.0 to
      1.0)", never read; `loadingIndicatorOffset`/`loadMoreIndicator` are ALSO dead by the same grep —
      not yet fixed, needs design judgment on exact intended semantics vs. the existing
      `distanceToTriggerLoadPixels`/absolute-pixel trigger before wiring),
      `typingIndicatorMargin`, `typingIndicatorPadding` (padding/spacing knobs are lower risk — likely
      just plumbed straight into a `Padding`/`SizedBox` — but still unverified). `loadingText`/
      `noMoreMessagesText`/`loadingIndicator`/`showCenteredIndicator` confirmed wired during an
      earlier tick's investigation (still worth a quick test each, but not dead). Given
      `AiChatWidget.paginationConfig` itself turned out to be dead, double-check whether any OTHER
      knob only reachable via that same top-level-shortcut-vs-nested-options pattern has the same bug
      (e.g. compare every `AiChatWidget` top-level field against what `messageListOptions`/
      `messageOptions`/`inputOptions` also expose, not just against test coverage).
- [x] Document any knob found to be dead-wired; fix or deprecate it:
      - `AiChatWidget.aiName` — completely dead (documented as "Name of the AI assistant (for
        display)" but never read anywhere; the real display name always comes from `aiUser.name`).
        Deprecated with a message pointing to `aiUser.name`.
      - `LoadingConfig.typingIndicatorColor` / `.typingIndicatorSize` — documented but never threaded
        past `AiChatWidget` into the actual dot-indicator widget. Unlike `aiName` this described a
        real, wantable customization, so it was WIRED (not deprecated): threaded through
        `CustomChatWidget` → `_DotIndicator`, additive/no breaking change.
      - `AiChatWidget.paginationConfig` — completely dead: never read in `ai_chat_widget.dart`'s
        build method at all; pagination only worked via `messageListOptions.paginationConfig`. Fixed
        (not deprecated — this is a real, commonly-needed feature, and #13/#41 Phase 3 already plans
        pagination/persistence work) by merging it into the `messageListOptions` handed to
        `CustomChatWidget`, matching existing precedence (`scrollController` already works the same
        way in that same `copyWith` call).
      - `PaginationConfig.enableHapticFeedback` — completely dead: no `HapticFeedback` call anywhere
        in the load-more path. Fixed (real, wantable, and a one-line wire) by calling
        `HapticFeedback.lightImpact()` right where `onLoadMore` actually fires, gated by the flag.
- [x] **IMPORTANT — caught and fixed a real regression from this session's own #42 fix before it
      shipped.** The #42 fix's `BuildContext` resolver originally used a persistent `GlobalKey` per
      message list item (cached across rebuilds). That's unsafe on a `ListView.builder` item: the
      list recycles/repositions items as it scrolls, and attaching a long-lived `GlobalKey` to one
      tripped a Flutter framework semantics assertion (`_needsLayout` during `flushSemantics`) the
      moment the list was actually scrolled via `jumpTo`/drag — not just measured, which is all the
      earlier tests exercised (they only drove `Scrollable.ensureVisible`'s own `animateTo`, which
      happened not to trigger it). Found this tick while writing the haptic-feedback test, which
      needed a real `jumpTo`. Replaced the `GlobalKey` with a plain element-tree walk keyed off the
      list item's existing `ValueKey` — same capability, no GlobalKey lifecycle interaction with the
      scrolling item. Added `test/widgets/scroll_jump_no_crash_test.dart` as a permanent regression
      guard. This never shipped to pub.dev (still unreleased), but was live on `main` for a few
      commits — reinforces: always test actual user-driven scrolling (`jumpTo`/drag), not just
      programmatic `animateTo`, for anything touching list-item widget identity.
- [x] `dart analyze --fatal-infos` clean; full `flutter test` green (385/385, ~17s, no flakiness) once
      this tick's own machine-load contention (see task-019) cleared.
- [ ] Reply progress on issue #41 — deferred until a more complete pass (or several ticks) is done;
      not worth a comment yet for five findings across four ticks.

**Status:** IN PROGRESS — resume with the remaining untested-knob list above (now scoped to genuinely
live, non-`AiChatConfig` fields only), then the not-yet-scanned model files (`MessageOptions`,
`InputOptions`, `CustomThemeExtension`, etc.), then reply on #41.

**Notes:** This is a "trust" investment per #41's thesis — prevents the next silent-no-op bug report.
