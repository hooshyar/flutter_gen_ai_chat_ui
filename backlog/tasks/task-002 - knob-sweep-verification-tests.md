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
      this tick: `enableMathRendering` (was wired but untested — added
      `test/widgets/enable_math_rendering_test.dart`). Remaining from the 31-field gap list found so
      far (still untested): `autoLoadOnScroll`, `cacheExtent`, `distanceToTriggerLoadPixels`,
      `enableHapticFeedback`, `loadMoreDebounceTime`, `loadingIndicator`, `loadingIndicatorOffset`,
      `loadingText`, `loadingWidgetMargin`, `loadingWidgetPadding`, `markdownStyleSheet`,
      `messageBubbleInnerPadding`, `messageBubbleOuterPadding`, `messageFooterTopPadding`,
      `messageListPadding`, `messageMediaSpacing`, `messageUsernameBottomPadding`,
      `noMoreMessagesText`, `quickRepliesPadding`, `scrollThreshold`, `showCenteredIndicator`,
      `showTimestamp`, `streamingFadeInCurve`, `streamingFadeInDuration`, `streamingFadeInEnabled`,
      `typingIndicatorMargin`, `typingIndicatorPadding`, `typingIndicatorSize` (padding/spacing knobs
      are lower risk — likely just plumbed straight into a `Padding`/`SizedBox` — but still unverified).
- [x] Document any knob found to be dead-wired; fix or deprecate it — found `AiChatWidget.aiName`
      completely dead (documented as "Name of the AI assistant (for display)" but never read anywhere;
      the real display name always comes from `aiUser.name`). Deprecated with a message pointing to
      `aiUser.name`, added `test/widgets/ai_name_dead_parameter_test.dart` to lock in the real behavior.
- [x] `dart analyze --fatal-infos` clean, `flutter test` green (377/377) — for this tick's changes.
- [ ] Reply progress on issue #41 — deferred until a more complete pass (or several ticks) is done;
      not worth a comment yet for two findings.

**Status:** IN PROGRESS — resume with the remaining untested-knob list above, then the not-yet-scanned
model files (`MessageOptions`, `InputOptions`, `CustomThemeExtension`, etc.), then reply on #41.

**Notes:** This is a "trust" investment per #41's thesis — prevents the next silent-no-op bug report.
