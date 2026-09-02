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
      `.typingIndicatorSize` (were genuinely DEAD — see below — now wired + tested).
      Correction from the first pass: several of the originally-flagged 31 fields belong to the
      already-`@Deprecated`-at-the-class-level `AiChatConfig` shim (`showTimestamp`, `userName`, plus
      `aiName`/`markdownStyleSheet`/etc. duplicated there) — those are EXPECTED to be unwired (the
      whole class is legacy/unused by `AiChatWidget`) and are OUT OF SCOPE for this sweep; don't
      re-flag them. Remaining real (non-`AiChatConfig`) untested knobs still to check:
      `autoLoadOnScroll`, `cacheExtent` (PaginationConfig, confirmed wired via
      `ListView.builder.cacheExtent` — just needs a test), `distanceToTriggerLoadPixels`,
      `enableHapticFeedback`, `loadMoreDebounceTime`, `loadingIndicatorOffset`, `loadingWidgetMargin`,
      `loadingWidgetPadding`, `markdownStyleSheet` (the live one on `MessageOptions`/`AiChatWidget`,
      not the `AiChatConfig` duplicate), `messageBubbleInnerPadding`, `messageBubbleOuterPadding`,
      `messageFooterTopPadding`, `messageListPadding`, `messageMediaSpacing`,
      `messageUsernameBottomPadding`, `quickRepliesPadding`, `scrollThreshold`,
      `streamingFadeInCurve`, `streamingFadeInDuration`, `streamingFadeInEnabled`,
      `typingIndicatorMargin`, `typingIndicatorPadding` (padding/spacing knobs are lower risk — likely
      just plumbed straight into a `Padding`/`SizedBox` — but still unverified). `loadingText`/
      `noMoreMessagesText`/`loadingIndicator`/`showCenteredIndicator` confirmed wired during this
      tick's investigation (still worth a quick test each, but not dead).
- [x] Document any knob found to be dead-wired; fix or deprecate it:
      - `AiChatWidget.aiName` — completely dead (documented as "Name of the AI assistant (for
        display)" but never read anywhere; the real display name always comes from `aiUser.name`).
        Deprecated with a message pointing to `aiUser.name`.
      - `LoadingConfig.typingIndicatorColor` / `.typingIndicatorSize` — documented but never threaded
        past `AiChatWidget` into the actual dot-indicator widget. Unlike `aiName` this described a
        real, wantable customization, so it was WIRED (not deprecated): threaded through
        `CustomChatWidget` → `_DotIndicator`, additive/no breaking change.
- [x] `dart analyze --fatal-infos` clean, `flutter test` green (379/379) — for this tick's changes.
- [ ] Reply progress on issue #41 — deferred until a more complete pass (or several ticks) is done;
      not worth a comment yet for three findings across two ticks.

**Status:** IN PROGRESS — resume with the remaining untested-knob list above (now scoped to genuinely
live, non-`AiChatConfig` fields only), then the not-yet-scanned model files (`MessageOptions`,
`InputOptions`, `CustomThemeExtension`, etc.), then reply on #41.

**Notes:** This is a "trust" investment per #41's thesis — prevents the next silent-no-op bug report.
