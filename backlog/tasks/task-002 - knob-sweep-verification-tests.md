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
      All `chat_spacing_config.dart` padding/margin fields (`messageBubbleInnerPadding`,
      `messageBubbleOuterPadding`, `messageFooterTopPadding`, `messageListPadding`,
      `messageMediaSpacing`, `messageUsernameBottomPadding`, `quickRepliesPadding`,
      `typingIndicatorMargin`, `typingIndicatorPadding`, `loadingWidgetMargin`,
      `loadingWidgetPadding`) and all remaining `PaginationConfig` fields (`autoLoadOnScroll`,
      `cacheExtent`, `distanceToTriggerLoadPixels`, `loadMoreDebounceTime`, `loadingText`,
      `noMoreMessagesText`, `loadingBuilder`/default indicator) CONFIRMED WIRED by grep this tick
      (each has a real call site in `custom_chat_widget.dart` or `loading_widget.dart`) — still worth
      a quick assert-it-applies test each eventually, but none are dead. Only remaining real gap:
      `markdownStyleSheet` (the live one on `MessageOptions`/`AiChatWidget`, not the `AiChatConfig`
      duplicate) still untested, and `scrollThreshold` — confirmed genuinely dead (documented "Scroll
      position threshold to trigger loading (0.0 to 1.0)", never read) but DELIBERATELY NOT wired this
      tick: OR-ing it in naively with its current default (0.1) would trigger load-more much EARLIER
      than today for any list with `maxScrollExtent > 1000px` (since `maxScroll * 0.1` would exceed
      the default 100px `distanceToTriggerLoadPixels`), which is a real default-behavior change, not
      a safe additive fix. Needs a deliberate design call (e.g. make it nullable/opt-in) before
      wiring — leave for a dedicated pass, don't rush it.
      Given `AiChatWidget.paginationConfig` itself turned out to be dead, swept the REST of
      `AiChatWidget`'s top-level fields the same way (grep each `widget.<field>` in
      `ai_chat_widget.dart`) — found TWO MORE dead: `padding` ("Padding around the entire widget",
      never applied) and `markdownStyleSheet` (never merged into the effective `MessageOptions`, same
      bug shape as `paginationConfig`). Both fixed this tick. Also found `enableAnimation`
      ("Whether to enable animations") dead, but unlike the others no single animation system remains
      for it to gate (streaming/fade-in are each already controlled by their own dedicated flag) —
      deprecated rather than guessed at. Every other top-level field (`messageOptions`,
      `inputOptions`, `quickReplyOptions`, `scrollToBottomOptions`, `welcomeMessageConfig`,
      `exampleQuestions`, `fileUploadOptions`, `spacingConfig`,
      `resultRenderers`/`resultLoadingRenderers`, `scrollBehaviorConfig`, `maxWidth`,
      `persistentExampleQuestions(Title)`, `streamingDuration`, `onCancelGenerating`) CONFIRMED
      reaches `CustomChatWidget`'s constructor call or is otherwise read in `build()`.
      Still need: enumerate `MessageOptions`/`InputOptions`/`CustomThemeExtension` fields the same way
      the first pass did for `AiChatWidget`/`ai_chat_config.dart` (the script only covered those two
      files + `chat_spacing_config.dart` so far).
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
      - `AiChatWidget.padding` — completely dead: never applied anywhere. Fixed by wrapping the whole
        widget with `Padding(padding: widget.padding!, ...)` when set.
      - `AiChatWidget.markdownStyleSheet` — same bug shape as `paginationConfig`: never merged into
        the effective `MessageOptions` handed to `CustomChatWidget`. Fixed via `MessageOptions.
        copyWith(markdownStyleSheet: widget.markdownStyleSheet)`.
      - `PaginationConfig.loadingIndicatorOffset` / `.loadMoreIndicator` — dead, but superseded by
        working mechanisms (`isLoadingMore` flag, `loadingBuilder`) rather than simply forgotten;
        deprecated pointing at those instead of wiring new behavior.
      - `AiChatWidget.enableAnimation` — dead, and no single remaining animation system to wire it
        into (each animation aspect already has its own dedicated flag); deprecated pointing at
        `enableMarkdownStreaming`/`streamingWordByWord`/`streamingFadeInEnabled`.
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
- [x] `dart analyze --fatal-infos` clean; full `flutter test` green (388/388, ~18s, no flakiness).
- [x] Reply progress on issue #41 — posted after 8 findings across 5 ticks.

**Status:** PAUSED (resumable) — the `AiChatWidget`/`ai_chat_config.dart`/`chat_spacing_config.dart`
sweep is essentially done (8 real findings, all fixed or deliberately deprecated; remaining items are
low-risk padding/spacing knobs already confirmed wired). Replied on #41. Moving to other backlog
tasks for variety; resume this task later to scan `MessageOptions`/`InputOptions`/
`CustomThemeExtension` the same way, and to make the deliberate design call on `scrollThreshold`.

**Notes:** This is a "trust" investment per #41's thesis — prevents the next silent-no-op bug report.
