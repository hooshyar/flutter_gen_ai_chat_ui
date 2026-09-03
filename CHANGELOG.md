## [Unreleased]

### Changed
- **Removed the `shimmer` package dependency.** It was the sole holdout pinning this package's dependency-freshness pana score (`shimmer` 4.0.0 requires Flutter `>=3.44.0`/Dart `^3.12.0`, above this package's declared floor) — see `docs/AWARD-PLAN.md`'s "time-sensitive" item. Replaced its one usage site (`LoadingWidget`'s shimmering loading text) with a small hand-rolled `ShaderMask` + `AnimationController` sweep that reproduces the same visual effect (a highlight band sliding across the text). No public API changes — `LoadingWidget.shimmerBaseColor`/`shimmerHighlightColor` behave identically. Removes a dependency and the recurring SDK-floor tension for good.

## 2.16.2 - 2026-09-03

Zero breaking changes. A real bug fix for a previously-inert, marketed feature
(`CustomThemeExtension`), a batch of dead/superseded-field deprecations from the ongoing
documented-knob audit, a completed dartdoc pass, verified WebAssembly support, and three
live-demo polish fixes.

### Fixed
- **Example app: two visual-QA findings from the live web demo (tasks 023, 024).** The Attachments and Voice Input demos shared `ResponseStyle.conversational` with the Custom Themes demo, so every reply — including ones about an attached file or a recognized voice phrase — was "Try switching between the Ocean/Sunset/Default themes above", even though neither screen has a theme selector. Both now use a new `ResponseStyle.assistant` with context-appropriate replies (file/report-aware, weather/fun-fact/summarize-aware for the voice demo's simulated phrases). Separately, the Rich Widgets demo's "Add to Cart" button had an empty `onPressed: () {}` — tapping it did nothing at all, reading as a dead button; it now shows a confirmation `SnackBar`. Example-app-only, no package API changes.
- **(Investigated, no fix needed) Task-022 — reported streaming "stall" is no longer reproducible.** A 2026-09-03 visual QA pass of v2.16.0 found the Streaming + Markdown demo appearing to freeze for 8-16s with the stop button stuck, then dumping the rest of the response on click. Reproduced the exact repro steps 3 times against the current live demo (now v2.16.1) — every attempt streamed and completed cleanly in 2-6 seconds with no stall and a correctly-reverting stop button. The most likely explanation: v2.16.1's unrelated `pinDuringStreaming` regression fix (a fix to the same streaming/auto-scroll code path) incidentally resolved this too. Left as an investigation note on the task rather than a speculative fix for a bug that no longer reproduces.

### Added
- **`docs/AWARD-PLAN.md` (task-016)** — a living, ranked (value/effort) plan of what's left to push this package toward Flutter Favorite / award-grade status, cross-referencing the `backlog/tasks/` decomposition instead of duplicating it. Re-checked (not assumed) two pre-existing historical audit docs while writing it — `doc/ONBOARDING_AUDIT.md`'s 5 queued items are now all independently resolved by later work. Surfaced a real, time-sensitive item: the `shimmer` dependency's pana "up-to-date" grace window has ~2.5 weeks left (see task-006).
- **Repo polish**: `.github/FUNDING.yml` (GitHub-native Sponsor button) and `.github/ISSUE_TEMPLATE/bug_report.md`/`feature_request.md` (the repo only had a custom "showcase" template before).
- **Verified and documented WebAssembly (`--wasm`) support (task-015).** `flutter build web --wasm` on the example app succeeds with zero source changes needed — no `dart:html`/`dart:js` legacy interop anywhere in the package. Confirmed end-to-end, not just "it compiles": served the wasm build locally, verified `main.dart.wasm` actually loads (not a silent JS fallback), and exercised the streaming markdown demo with no runtime errors. Added a `wasm-build` CI job (`.github/workflows/ci.yml`) so a future regression is caught automatically, and documented the status in the README's new "Web / WebAssembly" section.

### Fixed
- **`CustomThemeExtension` now actually applies to the chat UI (task-002 knob sweep).** `Theme.of(context).extension<CustomThemeExtension>()` was called nowhere in the widget tree — the entire theme extension (all 11 color knobs, and by extension the README-advertised `.chatgpt()`/`.claude()`/`.gemini()` brand presets and the `.modern()`/`.minimal()` `ColorScheme`-derived presets) had **zero visual effect** no matter what a consumer set on `ThemeData.extensions`. The existing `brand_presets_test.dart` only verified the extension round-tripped through `ThemeData`, not that any widget read it back out. Now wired as a fallback layer, consulted only when the more specific `BubbleStyle`/`MessageOptions`/`InputOptions` value is unset (so explicit per-widget colors still win, and nothing changes for the many existing consumers who haven't opted into a `CustomThemeExtension`): `chatBackground` → the overall chat surface; `messageBubbleColor`/`userBubbleColor`/`messageTextColor` → message bubbles and their text; `inputBackgroundColor`/`inputBorderColor`/`inputTextColor`/`hintTextColor` → the input field (when `InputOptions.decoration`/`.textStyle` are unset); `sendButtonColor` → the default send button icon; `backToBottomButtonColor` → the scroll-to-bottom button icon. `sendButtonIconColor` remains unused — the default send button is a plain icon with no colored background/circle for it to apply to; revisit if a filled-button treatment is added. No breaking changes — the extension defaults to unset (`null`), so behavior is identical to before unless a consumer explicitly adds one to `ThemeData.extensions`.

### Fixed (cont'd)
- **Example app: the home screen's version badge is no longer a hand-typed literal (task-021).** It had sat at `v2.14.0` on the live web demo through two releases (2.15.0 and 2.16.0) because it was a hardcoded string in `home_screen.dart`. It's now read from a generated `example/lib/version_info.dart` (`dart run tool/generate_version.dart` from `example/`, parsed straight from the package's own `pubspec.yaml`), which `deploy-web-demo.yml` also regenerates before every web-demo build so the live demo can't go stale again regardless of whether a release remembers to regenerate/commit it locally. `example/test/version_badge_test.dart` fails loudly if the committed generated file and `pubspec.yaml` ever drift apart in the meantime. No package API changes (example-app-only).

### Fixed (cont'd 2)
- **`InputOptions.autocorrect` now actually applies.** Documented, defaults to `true`, but was never passed to the underlying `TextField` — setting it to `false` had no effect.

### Deprecated
- **`InputOptions.textDirection` and `.inputTextDirection`** — both no-ops: the input's `TextField` always follows the ambient `Directionality` from `BuildContext` by design (this is what makes RTL auto-detection work without per-widget configuration), so neither field's value was ever read.
- **`InputOptions.positionedLeft`/`.positionedRight`/`.positionedBottom`/`.positionedTop`** — no-ops: nothing wraps the input in a `Stack`/`Positioned` for these to apply to (`AiChatWidget` lays it out as a regular `Column` child).
- **`MessageOptions.timestampSpacing`** — no-op, superseded by `ChatSpacingConfig.messageFooterTopPadding`, which is what actually controls the footer's spacing.
- **`MessageOptions.maxReactions`/`.reactionSize`/`.enableQuickReply`** — no-ops: no reaction UI exists anywhere in the widget tree to apply them to. Quick replies are a real, separate, working feature — driven by `QuickReplyOptions` on `AiChatWidget`, not this flag.

All four groups above will be removed in v3.0.0; no behavior changes from deprecating them (they already did nothing).

### Removed
- **Two fully dead, duplicate `ThemeProvider`/`CustomThemeExtension` classes** (`lib/src/providers/theme_provider.dart`, `lib/src/theme/theme_provider.dart`) — neither was exported from the package's main library file nor imported by anything else in `lib/`, `test/`, or `example/`. The `providers/` copy additionally bundled its own duplicate `CustomThemeExtension` class (with a different field set than the real, exported one), which would have collided if anyone ever imported it. Found during the same knob-sweep audit that led to actually wiring up the real `CustomThemeExtension` above.

### Tests
- Added `test/theme/custom_theme_extension_applies_test.dart` (6 tests: `chatBackground`, bubble/text colors, send button color, and input field colors all actually render from a `CustomThemeExtension`, and explicit `BubbleStyle`/`MessageOptions`/`InputOptions` values still take precedence over it), `test/widgets/input_autocorrect_dead_parameter_test.dart` (2 tests), and one more golden (`goldens/chatgpt_theme_preset.png`, visually pinning the ChatGPT preset actually changing bubble/input/send-button colors). Net test count: 416 → 425.

## 2.16.1 - 2026-09-03

### Fixed
- **`pinDuringStreaming` was released a few hundred milliseconds after arming when the answer was started with `addStreamingMessage`** — i.e. in the example app and for every consumer using the `addStreamingMessage` → `updateMessage` → `stopStreamingMessage` flow, the pin held for a moment and then the list "silently jumped forward" (found by a visual QA pass of the 2.16.0 web demo). `addMessage` schedules its delayed auto-scroll before `addStreamingMessage` arms the pin; when that timer fired it went through the public `scrollToBottom`, which 2.16.0 treats as "the reader took over" and therefore released the pin. The controller's own automatic scrolls now use an internal path that never releases the pin, and the delayed auto-scroll re-checks the pin when it fires. Regression test: `test/widgets/streaming_pin_delayed_autoscroll_test.dart` (fails on 2.16.0, passes now). No API changes.

## 2.16.0 - 2026-09-03

### Added
- **`ScrollBehaviorConfig.pinDuringStreaming` — hold the start of a streaming answer (or the user's question) at the top of the viewport (#42 follow-up).** After the first #42 fix, the reporter clarified what they actually wanted: not a scroll back to the answer's first line *once it finishes*, but a pin *while it streams* — "hit Go, the screen starts scrolling, and then my question or the start of the answer should not scroll out of the viewport; the scroll-to-bottom button appears; I read at my own pace." New `StreamingPinAnchor { none, responseStart, userMessage }`. While the answer is short the list follows it exactly as before; once the anchor reaches the top of the viewport it is held there (measured from the real render position, direction-agnostic — works for `reverseOrder: false` too) and new text arrives below the fold. A scroll gesture (drag/fling/wheel — a non-idle `UserScrollNotification`, which programmatic scrolls never emit) or the scroll-to-bottom button releases it for the rest of that answer; the end of the stream never jumps. In a reverse list, after a release, the text being read also stays still as chunks arrive (the offset advances by the answer's measured growth), instead of being pushed upwards. New controller surface: `isStreamingPinActive`, `streamingPinAnchorMessageId`, `releaseStreamingPin()`, `maintainStreamingPin()` (the last is called by the widget; consumers normally never need it). `ScrollBehaviorConfig` also gained `copyWith`. **Fully backward compatible:** the default is `StreamingPinAnchor.none`, every existing constructor/preset keeps its old behaviour, and no existing parameter changed meaning — verified by the full suite plus new tests covering the default path, both anchors, release by gesture and by button, end-of-stream, chronological lists, and the `addStreamingMessage` flow.

### Fixed
- **`ScrollBehaviorConfig.scrollToFirstResponseMessage` now correctly pins a single long streaming answer's top edge to the viewport top (#42).** `scrollToMessage`/`forceScrollToFirstMessageInChain` previously computed their scroll target from `index / itemCount`, which assumes uniform message heights — with the common case of one short user question followed by one very long AI answer, that heuristic badly mistargeted the scroll position (for the default `reverse: true` list it effectively collapsed to "just show the bottom", i.e. the exact bug reported: the top of the answer scrolls out of view as it streams). Both methods now measure the message's actual rendered position and use `Scrollable.ensureVisible`, with the alignment edge corrected for `reverse: true` lists. No public API changes. The measurement is done via a plain element-tree walk (matching the message's existing list-item key) rather than a per-item `GlobalKey` — an earlier iteration of this fix used a `GlobalKey`, which triggered a Flutter framework semantics assertion the moment the list was actually scrolled (`ListView.builder` recycles/repositions items as it scrolls, which doesn't mix safely with a long-lived `GlobalKey` on the recycled item); caught before release by `test/widgets/scroll_jump_no_crash_test.dart`.

### Fixed (cont'd)
- **`LoadingConfig.typingIndicatorColor` / `.typingIndicatorSize` now actually apply.** Found during the same knob-sweep audit — both were documented ("Color for the typing indicator", "Size of the typing indicator") but never threaded past `AiChatWidget`; the default typing-dots indicator was always a hardcoded grey at a fixed 8px regardless of what you set. Now plumbed through `CustomChatWidget` into the dot indicator. No API changes — existing code that didn't set these keeps the same default look.
- **`AiChatWidget.paginationConfig` now actually applies.** Found during the same audit — this top-level convenience parameter (documented "Configuration for pagination") was never read in `AiChatWidget`'s build method; pagination only worked if set via `AiChatWidget(messageListOptions: MessageListOptions(paginationConfig: ...))` instead. Now merged into the effective `messageListOptions`, matching the precedence the widget already gives its `scrollController` shortcut over `messageListOptions.scrollController`. No API changes.
- **`PaginationConfig.enableHapticFeedback` now actually applies.** Found during the same audit — documented "Whether to enable haptic feedback when loading more messages" but never read anywhere; load-more never triggered haptic feedback regardless of the setting. Now fires `HapticFeedback.lightImpact()` when auto-load-more actually triggers. No API changes — defaults to `true`, matching the documented default, so existing consumers get haptic feedback they previously expected but didn't receive; set it to `false` to restore the old (silent) behavior.
- **`AiChatWidget.padding` now actually applies.** Found during the same audit — documented "Padding around the entire widget" but never read; setting it had zero visual effect. Now wraps the whole widget. No API changes — defaults to `null` (no padding), same as before.
- **`AiChatWidget.markdownStyleSheet` now actually applies without also setting `messageOptions`.** Found during the same audit — this top-level convenience parameter was never merged into the effective `MessageOptions`, so it only worked if set via `AiChatWidget(messageOptions: MessageOptions(markdownStyleSheet: ...))` instead. Now merged the same way `paginationConfig` was fixed above. No API changes.
- **Two icon-only tap targets were under the Material/WCAG 48x48dp minimum (#41 Phase 1).** The default send button's `IconButton` has its own 48x48 minimum constraint, but a fixed-height `Container` around it (approximating the text field's height as `contentPadding.vertical + 24`) capped it at ~38px tall with the default `InputOptions`. The icon-only scroll-to-bottom button (`ScrollToBottomOptions.showText` defaults to `false`) sized its tap area directly from a small `Padding`, landing at ~36-44px. Both now meet the 48x48 minimum — the icons themselves are unchanged, only their tap areas grew, which makes the default input row and the scroll-to-bottom pill each modestly (a few px) taller/larger. Also fixed a stale doc comment: `ScrollToBottomOptions.showText` said its default was `true`; the default has always been `false`.

### Deprecated
- **`AiChatWidget.aiName`** — found during the documented-knob verification sweep (#41 Phase 0.5) to have no effect: the displayed AI name always comes from `aiUser.name` (and each message's `user.name`). Deprecated rather than removed; will be removed in v3.0.0.
- **`PaginationConfig.loadingIndicatorOffset` and `.loadMoreIndicator`** — found during the same sweep to have no effect: the loading indicator's visibility is actually driven by `MessageListOptions.isLoadingMore`, and its widget is actually built via `PaginationConfig.loadingBuilder` (or the built-in default) — not by these two, which look superseded rather than simply forgotten. Deprecated pointing at the mechanisms that actually work; will be removed in v3.0.0.
- **`AiChatWidget.enableAnimation`** — found during the same sweep to have no effect: no single animation system reads it anymore (streaming/fade-in animations are each controlled by their own dedicated flag: `enableMarkdownStreaming`, `streamingWordByWord`, `streamingFadeInEnabled`). Deprecated pointing at those; will be removed in v3.0.0.

### Added
- **Two new example screens** (issue #41 Phase 2): `Attachments` (file upload button + attached-file rendering via `FileUploadOptions`) and `Voice Input` (mic/send toggle via `InputOptions.sendOrMicBuilder` + the package's `VoiceSendButton`). Both simulate the platform-specific part (a real file picker / real speech recognition) since the package deliberately doesn't bundle either — same reasoning as `FileUploadOptions.onFilesSelected` already documents — so the demos work without extra permissions or a picker dependency while still showing the actual package API.

### Changed
- **Dependencies audited against latest stable (`flutter pub outdated` / pub.dev, not from memory).** `flutter_streaming_text_markdown` pin raised to `^1.9.1` (confirmed the actual latest published version). `shimmer` deliberately held at `^3.0.0` — 4.0.0 requires Flutter `>=3.44.0` / Dart `^3.12.0`, above this package's declared floor (Flutter `>=3.27.0` / Dart `>=3.6.0`); revisit once the floor is raised. All other direct dependencies were already at the latest resolvable version. Refreshed the example app's lockfile (`flutter pub upgrade`, within existing constraints — `gpt_markdown`, `jni`/`jni_flutter`, `url_launcher_*`, `vector_graphics*`, etc.).
- Example app: removed the now-`@Deprecated` `enableAnimation` from `basic_chat.dart` and the integration-test helper/call sites (it never had any effect); the one test whose name implied it verified "no animation when disabled" now actually does, via `enableMarkdownStreaming: false` instead.

### Tests
- Added `test/controllers/scroll_to_first_response_single_message_test.dart` (2 tests: `scrollToMessage` and `forceScrollToFirstMessageInChain` both pin a single long streaming answer's top to the viewport top), `test/widgets/enable_math_rendering_test.dart` (2 tests: `enableMathRendering` actually switches between `MathMarkdown` and plain markdown rendering), `test/widgets/ai_name_dead_parameter_test.dart` (locks in `aiUser.name` as the only display-name source), `test/widgets/typing_indicator_customization_test.dart` (2 tests: typing-indicator color/size are applied, and default fallback still holds when unset), `test/widgets/streaming_fade_in_config_test.dart` (2 tests: `streamingFadeIn*` config reaches the underlying `StreamingText` widget), `test/widgets/pagination_config_dead_parameter_test.dart` (the top-level `paginationConfig` shortcut reaches the loading indicator), `test/widgets/pagination_haptic_feedback_test.dart` (2 tests: haptic feedback fires on load-more when enabled, not when disabled), `test/widgets/scroll_jump_no_crash_test.dart` (regression guard: scrolling via `jumpTo` with many messages doesn't throw — see the #42 fix note above), `test/widgets/pagination_deprecated_fields_test.dart` (locks in that `loadingBuilder`, not the deprecated `loadMoreIndicator`, is what actually renders), and `test/widgets/ai_chat_widget_top_level_shortcuts_test.dart` (2 tests: `padding` and `markdownStyleSheet` top-level shortcuts both actually apply). Net test count: 372 → 388.
- Added `test/golden/chat_golden_test.dart` — 5 golden (screenshot-diff) tests pinning the visual appearance of the default bubble, welcome message, a mid-stream response, a markdown code block, and RTL layout. Meaningful on macOS locally; a no-op image comparison on non-macOS CI (font rendering differs too much across platforms — see `test/flutter_test_config.dart`), so it still catches build/render crashes there without false-failing on font differences. See `CONTRIBUTING.md` for the regeneration workflow. Net test count: 388 → 393.
- Added `test/widgets/accessibility_tap_targets_test.dart` (3 tests: send button, file upload button, and the icon-only scroll-to-bottom button all measure at least 48x48). Regenerated the golden baselines above to reflect the (intentionally) slightly taller input row and scroll-to-bottom pill from the tap-target fix. Net test count: 393 → 396.
- Example app: added widget tests for the two new demo screens (`example/test/attachments_chat_test.dart`, `example/test/voice_chat_test.dart`) and replaced the placeholder no-op `widget_test.dart` with a real smoke test of the home gallery.

### Docs
- Added `CONTRIBUTING.md` (test commands, the golden-test regeneration workflow, pre-submit checklist).

## [2.15.0] - 2026-07-10

Zero breaking changes. Reliability + packaging release driven by a full package audit — fixes a dead public parameter and a set of resource-lifecycle leaks.

### Added
- **Brand theme presets** — `CustomThemeExtension.chatgpt()`, `.claude()`, `.gemini()` (each with `dark: true`) so the README's "ChatGPT/Claude/Gemini ready" claim is a one-liner: `ThemeData(extensions: [CustomThemeExtension.chatgpt()])`.
- **`InputOptions.sendButtonTooltip`** (default `'Send message'`) — the default send button is icon-only and previously had no accessibility label; it now exposes a screen-reader tooltip, localizable like the other 2.13 i18n hooks.
- **`MessageOptions.bubbleBuilder`** — a 4-arg builder `(context, message, isCurrentUser, defaultBubble)` that hands you the fully-styled default bubble so you can *wrap* it (add a feedback/report button, badge, gesture) instead of rebuilding it from scratch. Takes precedence over the existing 3-arg `customBubbleBuilder`. This is the capability the README documented but the code never implemented (the root of #18/#30); the README is now correct and shows both builders living on `MessageOptions`.

### Fixed
- **Streaming reveal pacing is now owned by the widget.** Messages streamed via `addStreamingMessage` + repeated `updateMessage` were animated by handing the growing text to `StreamingText`, whose fixed-speed typing restarts/free-runs when the text prop churns faster than it can type — with real streams (a chunk every ~20ms) this produced the "types a bit, then everything slams in at once / restarts from the top" family of bugs, and completion could never be observed reliably. `CustomChatWidget` now paces the reveal itself with a single ticker, so controller-driven streams animate smoothly regardless of chunk cadence.
- **`FileUploadOptions.fileDisplayBuilder` now actually renders (#40).** The builder was declared on the model but never read by the render tree, so customizing how media attachments appear in a message had no effect. It is now threaded `AiChatWidget` → `CustomChatWidget` → `MessageAttachment`, so you can fully control attachment display (tap-to-enlarge, custom borders/radius, etc.).
- **`AiContextController.watchNotifier` no longer leaks.** It registered a listener on the watched `ValueNotifier` that was never removed, pinning the controller (and its context map) alive for the notifier's lifetime and firing `notifyListeners()` after `dispose()`. Listeners are now tracked and removed in `dispose()`.
- **`ContextAwareChatController` now disposes the sub-controllers it creates.** When you don't pass your own `ChatMessagesController` / `ReadableContextController` / `ActionController`, the ones it constructs are now disposed in `dispose()` (consumer-owned controllers are left untouched, as before).
- **`TextPainter` instances are disposed** after measurement on two hot paths (the per-bubble layout helper in `CustomChatWidget` and the per-keystroke ghost overlay in the inline autocomplete field), removing native-resource churn and disposal-tracking warnings on newer Flutter.
- **`SmartChatInput` removes its text/focus listeners on dispose** even when the controller is consumer-owned, preventing a State-subtree leak.

### Changed
- **SDK floor corrected to Flutter `>=3.27.0` / Dart `>=3.6.0`** (was `>=3.7.0` / `>=2.19.0`). The package's color code uses the wide-gamut `Color` API (`.r`/`.g`/`.b`/`.a` and `withValues`), introduced in Flutter 3.27 — the older accessors are deprecated and fail `analyze --fatal-infos`, so the package never actually compiled below 3.27 despite the lower declared bound. This aligns the constraint with reality and prevents the version-solve/compile failures reported in #7 and #12. If you're on an older Flutter, pin to an earlier release of this package.
- **`watchNotifier` now returns a `VoidCallback` disposer** (on both `AiContextController` and the `AiContextHook`) so you can stop watching before the controller is disposed. Existing callers that ignore the return value are unaffected.
- **Deprecation messages** on the legacy `chat_user.dart` / `chat_options.dart` import shims now name a removal target (v3.0.0).
- **Packaging:** trimmed internal agent logs (`WORK_LOG.md`, `AGENTS.md`), tool dirs (`.claude/`, `.cto/`), and unreferenced dev screenshots from the published tarball via `.pubignore`; added a `screenshots:` section to `pubspec.yaml` so the pub.dev listing renders them.
- **Dependencies upgraded to latest stable** (including `flutter_markdown_plus` 1.0.11); the example app's lockfile is now tracked so its dependency state is reproducible.

### Tests
- Added `test/widgets/file_display_builder_test.dart` (custom builder is used; default renderer still works), `test/controllers/controller_dispose_leak_test.dart` (watchNotifier listener removal + disposer; sub-controller ownership), `test/widgets/bubble_builder_test.dart` (bubbleBuilder wraps the default bubble; precedence over customBubbleBuilder), `test/widgets/accessibility_test.dart` (send-button semantic tooltip, default + localized), and `test/theme/brand_presets_test.dart` (brand presets populated/distinct/applied). Net test count: 351 → 365. Validated locally on Flutter 3.44.2 — `analyze --fatal-infos` clean, full suite green.

## [2.14.0] - 2026-05-31

Zero breaking changes. Visual-polish release — the remaining items from the live example-app audit.

### Added
- **`WelcomeMessageConfig.centerVertically`** (default `false`) — center the welcome/empty-state vertically while the conversation is empty, instead of anchoring it to the bottom of the (reverse) list which left a large gap above on tall screens. Opt-in, so existing apps are unchanged; once the first message is sent normal layout resumes.

### Changed
- **Default fenced-code-block styling** is now a padded, rounded, bordered card (theme-aware) instead of a flat low-contrast fill — code reads as a distinct block. Inline `code` gets a subtler tinted chip. Consumers who pass their own `MessageOptions.markdownStyleSheet` are unaffected. (No tokenized syntax highlighting yet — that needs a highlighter dependency and is left as a deliberate future opt-in.)
- Example app: all six demos opt into `centerVertically`, navigate with snappy fade transitions (replacing the slow per-platform slide), and the home version badge is current.

### Tests
- Added 2 tests for `centerVertically` (centered SingleChildScrollView path when empty + opted in; default keeps the welcome in the list). Net test count: 349 to 351.

## [2.13.0] - 2026-05-31

Zero breaking changes. Localization hooks + responsive layout, driven by a live audit of the example app.

### Added
- **`AiChatWidget.maxWidth` now centers the chat column** on wide viewports instead of hugging the left edge. On narrow screens the column is clamped to the available width (no overflow), so this is a no-op on phones. Makes the widget look correct out of the box on web/desktop/tablet.
- **`MessageOptions.copyButtonLabel`** and **`MessageOptions.copiedToClipboardText`** — localize the AI-message copy button and its confirmation snackbar (e.g. `'نسخ'` / `'تم نسخ الرسالة'` for Arabic). Default to `'Copy'` / `'Message copied to clipboard'`.
- **`AiChatWidget.persistentExampleQuestionsTitle`** — localize the header above the persistent example-questions bar (defaults to `'Suggested Questions'`). Previously hardcoded English.

### Changed
- Example app polish: constrained + centered chat columns (`maxWidth: 720`) across all six demos, snappier mock streaming, corrected version badge, and the RTL demo is now fully Arabic-localized (header, copy button, relative timestamp) using the new hooks above.

### Tests
- Added 7 tests (`test/i18n_and_layout_test.dart`): custom/default copy label, custom/default persistent-questions title, `copyWith` propagation of the new labels, and `maxWidth` centering + no-overflow on narrow viewports. Net test count: 342 to 349.

## [2.12.0] - 2026-05-31

Zero breaking changes. Two additive features close long-standing issue requests, plus the accumulated maintenance work below.

### Added
- **Stop-generating button** (#39). New `AiChatWidget(onCancelGenerating: ...)` callback. When it's non-null and `loadingConfig.isLoading` is true, the input's send button is automatically replaced by a stop button so users can cancel an in-flight response; tapping it invokes your callback (where you cancel your own stream / HTTP request). Customize via `InputOptions.cancelButtonBuilder` (full custom widget) or `InputOptions.stopButtonIcon` / `stopButtonColor` (default button). Send-on-Enter (hardware and soft keyboard) is suppressed while the stop button is showing. The streaming example (`example/lib/examples/streaming_chat.dart`) now wires it up end-to-end.
- **Per-bubble timestamp styles** (#29). `MessageOptions.userTimeTextStyle` and `MessageOptions.aiTimeTextStyle` let you style the timestamp differently on user vs AI bubbles (e.g. a light timestamp on a colored user bubble). Both fall back to the shared `timeTextStyle`, which falls back to the built-in default — fully backward compatible.

### Fixed
- `ChatMessagesController.simulateStreamingCompletion` no longer leaks a pending `Timer` after `dispose()`. Widget tests using the simulation path can exit cleanly without `pumpAndSettle`.
- `ChatMessagesController` post-render scroll and manual-scroll-reset timers are now tracked and cancelled in `dispose()` (replaces prior untracked `Future.delayed` calls).
- `ActionController` no longer leaks the 2-second post-completion cleanup `Timer` if the controller is disposed before the timer fires.
- Internal `StreamingTextWidget` no longer leaks its recursive step `Timer` on dispose.
- Internal `AnimatedBubble` no longer leaks its start-delay `Timer` on dispose.
- `CopilotTextarea` no longer leaks its 500ms suggestion-debounce timer on dispose, and no longer crashes the widget tree when unmounted while a suggestion overlay is visible.
- `AgentOrchestrator` now tracks per-agent state-stream subscriptions and cancels them on `unregisterAgent` / `dispose` (before closing its own broadcast controllers). Fixes a latent "Cannot add events after closing" risk when an agent emits state from within its own `dispose`. Re-registering an agent under an existing id now also cancels the orphaned subscription instead of silently leaking it.

### Changed
- Dartdoc coverage raised on the highest-traffic public types: `AiChatWidget`, `ChatMessagesController`, `ChatMessage`, `AiActionProvider`, `AiActionConfig`, `AiActionHook`, `AiActionBuilder`, and `AgentOrchestrator` now carry class-level summaries, primary-constructor docs, runnable code-example blocks, and documented public getters / methods (units, nullability, and when-to-use guidance). `dart doc --validate-links` is clean.

### Tests
- Added 19 unit tests covering `AgentOrchestrator` (registration, routing, delegation, collaboration, streaming, error wrapping, and dispose). Public API behaviour pinned: routing prefers capability matches; delegation with missing target metadata returns an error response rather than throwing.
- Added 3 stream-subscription-lifecycle regression tests pinning the orchestrator's per-agent subscription tracking, dispose ordering, and re-registration cancellation.
- Added 5 regression tests pinning timer-lifecycle fixes across `ChatMessagesController`, `ActionController`, `StreamingTextWidget`, `AnimatedBubble`, and `CopilotTextarea`.
- Added 21 unit tests covering the shipped example agents (`TextAnalysisAgent`, `CodeAnalysisAgent`, `GeneralAssistantAgent`) — `canHandle` routing, happy-path execution, dispose-no-leaks, and agent-specific assertions including delegation routing.
- Added 2 frame-callback lifecycle regression tests pinning the `addPostFrameCallback` `mounted` guards in `SmartChatInput` and `CustomChatWidget`. Net test count: 278 to 328.
- Added 12 tests for the new stop-generating button and per-bubble timestamp styles (`test/stop_generating_test.dart`): stop-button visibility (generating + callback present/absent, loading on/off, toggle back to send), tap-invokes-callback, custom `cancelButtonBuilder`, `effectiveStopButtonBuilder` fallbacks, independent user/AI timestamp colors, and shared-style fallback. Net test count: 330 to 342.

### Dependencies
- Raised `flutter_streaming_text_markdown` floor from `^1.4.0` to `^1.8.0`. Picks up the 1.7.0 Arabic/RTL word-splitting fix and emoji-resume fix that consumers of this package's RTL surface will benefit from. No code change required — the existing API surface used by `AnimatedTextMessage` / `MessageContentText` / `CustomChatWidget` is unchanged across 1.4 → 1.8.
- Raised `google_fonts` floor from `^8.0.1` to `^8.1.0`. Picks up the 8.0.2 async-exception-handling fix.

### Tooling
- Added `.github/workflows/ci.yml`: runs `dart format --set-exit-if-changed`, `flutter analyze --fatal-infos`, and `flutter test` on push and PR to `main`. The formatter step exists because `flutter analyze` does not catch formatter drift, and pana's lint+format check (50/50 of the pub.dev score) silently dropped to 40/50 during iter 6 from a dartdoc edit that exceeded 80 columns. CI now turns that class of regression into a 5-second red check.

### Notes
- pana score: 160/160 baseline (run with `pana --no-warning`). All 11 sections perfect including dartdoc, formatting, dependencies, and platform support.
- Zero breaking changes — no public API surface changed, no exports added or removed. Backwards compatible from 2.11.x.
- Discoverability: package now ships an `AGENTS.md` at the repo root (LLM-friendly quick reference for AI coding assistants) and an expanded `topics:` list in `pubspec.yaml` (10 tags covering AI, agents, LLM, streaming, markdown, RTL). Pubspec description rewritten for keyword density.
- README install snippet updated to `^2.11.1` (matches actual current version).

## 2.11.1 - [2026-05-04] Hardware Enter Sends on Desktop / Web

### Fixed
- **`sendOnEnter: true` now actually works on macOS, Windows, Linux, web, and any device with an attached physical keyboard** (closes #38). Previously `sendOnEnter` only fired via the soft keyboard's submit action, so on desktop hardware Enter just inserted a newline. `ChatInput` now wraps its `TextField` in a `Focus(onKeyEvent:)` that intercepts Enter and `numpadEnter` before `EditableText`'s internal newline shortcut runs.
- Shift+Enter falls through to insert a newline (ChatGPT/Claude style).
- Held-Enter (`KeyRepeatEvent`) does not fire `onSend` repeatedly.
- IME composing range is respected — Enter during CJK composition commits the composition rather than sending.

### Changed
- `options.onSubmitted` now also fires when hardware Enter sends, mirroring the soft-keyboard submit path. Consumers using `onSubmitted` for analytics will see additional events on desktop where they previously saw none.

### Notes
- Zero breaking changes — no public API surface changed. The default `textInputAction: TextInputAction.newline` is preserved (the documented mobile focus-issue fix is unaffected).
- The `Focus` wrapper uses `canRequestFocus: false` and `skipTraversal: true` so focus and tab order are unchanged.

## 2.11.0 - [2026-04-11] Mic/Send Toggle + Streaming Rich Widgets + Per-Kind Loading

### Added
- **`sendOrMicBuilder`** on `InputOptions` — receives both `onSend` callback and `isEmpty` bool, enabling ChatGPT-style mic/send toggle that auto-switches based on text field content.
- **`ChatMessage.loading()`** factory — creates a shimmer placeholder that can be replaced in-place via `controller.updateMessage()` with a rich widget or text.
- **`loadingKind`** parameter on `ChatMessage.loading()` — specify which type of loading widget to render (e.g., `'contract'`, `'lawyer_search'`).
- **`resultLoadingRenderers`** on `AiChatWidget` — register custom loading widgets per kind. When a `ChatMessage.loading(loadingKind: 'contract')` is rendered, the matching builder shows a custom loading state instead of default shimmer.
- **`loadingBuilders`** on `ResultRendererRegistry` — per-kind loading widget map with `buildLoading()` method.
- **Default shimmer bars** — messages with `isLoading: true` but no matching `loadingKind` renderer show animated shimmer placeholders.

### Changed
- **`ChatInput`** converted from `StatelessWidget` to `StatefulWidget` — listens to `TextEditingController` changes to track empty state for mic/send toggle. Non-breaking: same constructor API.
- **Rich messages render full-width** — `ChatMessage.rich()` and `ChatMessage.loading()` messages bypass bubble decoration entirely. No background, no border radius, no username header, no max-width constraint. The widget controls its own layout edge-to-edge.

### Fixed
- **Safe area bottom padding** — Material input path now respects device safe area (home indicator). Input was previously clipped behind the bottom bar on iPhone X+ devices.

### Notes
- Zero breaking changes — all new parameters are optional with null defaults
- Rich messages auto-detect via `customProperties['resultKind']` or `customProperties['isLoading']`; existing text messages are unaffected
- 50 new tests across all features

## 2.10.0 - [2026-04-11] Input Customization + Rich Message ID

### Added
- **`inputLeadingBuilder`** on `InputOptions` — render widgets (mic, attach, etc.) inside the input row, to the left of the text field. ChatGPT-style inline action buttons.
- **`attachmentPreviewBuilder`** on `InputOptions` — render a file/image preview strip above the input area before sending.
- **`id`** parameter on `ChatMessage.rich()` — explicit message ID for stable tracking via `customProperties['id']`.

### Notes
- Zero breaking changes — all new parameters are optional with null defaults
- Existing `inputToolbarBuilder` (below input) still works alongside new builders

## 2.9.0 - [2026-04-10] Rich Widget Messages

### Added
- **`ChatMessage.rich()`** factory — render custom widgets by type via `ResultRendererRegistry`. AI responses can now include interactive cards, forms, and data visualizations inline in chat.
- **`ChatMessage.widget()`** factory — render a one-off custom widget inline without needing a registry.
- **`resultRenderers`** parameter on `AiChatWidget` — register widget builders by kind string. Messages created with `ChatMessage.rich()` are automatically rendered by matching builders.
- **`ResultRendererRegistry` wired into rendering pipeline** — the existing registry (exported since v2.5) is now actually used in `_buildMessageContent()`. Falls through to text rendering when no matching builder is found.
- 12 new tests covering rich message factories, registry rendering, and fallback behavior.

### Example
```dart
// Register renderers
AiChatWidget(
  resultRenderers: {
    'weather': (context, data) => WeatherCard(city: data['city']),
    'product': (context, data) => ProductCard(data: data),
  },
  // ...existing params
);

// AI sends a rich message
controller.addMessage(ChatMessage.rich(
  user: aiUser,
  resultKind: 'weather',
  data: {'city': 'Baghdad', 'temp': 42},
));

// Or a one-off widget
controller.addMessage(ChatMessage.widget(
  user: aiUser,
  builder: (context) => const MyCustomCard(),
));
```

### Notes
- Zero breaking changes — all new APIs are additive
- Existing `customBuilder` and `customProperties` behavior unchanged
- `ResultRendererRegistry` was previously exported but unused; now functional

## 2.8.0 - [2026-04-08] Input Toolbar, Dark Mode Fix, Example Overhaul

### Added
- **`inputToolbarBuilder`** on `InputOptions` — render a custom toolbar row below the text field (ChatGPT/Claude-style action buttons)
- **AI Actions example** — new example demonstrating `ActionController`, `AiActionProvider`, and function calling with calculator, weather, and color actions
- **Persistent example questions** demonstrated in streaming example
- **Regression tests** for user message display (#36) and action execution (#35)

### Fixed
- **Critical: `withOpacityCompat` color corruption** — `Color.r/g/b` return 0.0-1.0 doubles in modern Flutter; the old code used `.toInt()` which truncated them to 0 or 1, turning white into near-black. Fixed by scaling with `(r * 255).round()`. This fixes dark mode contrast across the entire package.
- **Dark mode contrast throughout examples** — AI bubbles, welcome containers, question chips, and text colors now have proper contrast against dark backgrounds
- **Persistent questions container** now uses theme-aware `colorScheme.surfaceContainerHigh/Low` instead of hardcoded dark colors
- **User messages not appearing in example apps** — all examples now call `_controller.addMessage(message)` in `onSendMessage` (closes #36)
- **Timezone-dependent test failure** — `streaming_message_test.dart` now uses `DateTime.utc()` instead of local time

### Changed
- Example app home screen redesigned with visual hierarchy (featured card + compact list), staggered animations, scrollable layout
- All example inputs styled with rounded pill, filled background, arrow-up send button, contextual hint text
- Themed chat example now has proper dark mode variants for Ocean and Sunset themes
- Cleaned up 10 stale git branches (5 merged, 5 superseded)

## 2.7.0 - [2026-02-16] Community PRs + Issue Fixes

### Added
- **LaTeX/Math rendering** (`enableMathRendering: true` on `AiChatWidget`) — closes #25
  - Block math: `$$...$$`
  - Inline math: `$...$`
  - Powered by `flutter_math_fork`; graceful fallback on parse errors
  - New `MathMarkdown` widget exported for direct use
- **Custom avatar builders** (`aiAvatarWidgetBuilder` / `userAvatarWidgetBuilder` on `BubbleStyle`) — closes PR #26
  - Renders a custom widget next to the AI or user name
  - Falls back to the default robot icon when not provided
- **Custom AI name icon** (`aiNameIcon` on `MessageOptions`) — closes PR #34
  - Replace the default `Icons.smart_toy_outlined` with any widget
  - Use `SizedBox.shrink()` to hide it entirely

### Fixed
- **Word-by-word animation now works with `addMessage()`** — closes #28
  - Previously only worked with `addStreamingMessage()` / streaming pattern
  - Now also triggers for messages added via `addMessage()` or external state providers (e.g., Riverpod, Provider)
  - Animation plays once per new message and stops cleanly
  - Timers are cancelled on widget dispose (no test leaks)

## 2.6.2 - [2026-02-16] Streaming Dependency Upgrade

### Changed
- Bumped `flutter_streaming_text_markdown` from `^1.3.2` to `^1.4.0`
  - Fixes setState race conditions (prevents navigation crashes)
  - Fixes timer memory leaks in long-running chats
  - Fixes AnimationController disposal errors
  - 500x faster RTL/Arabic text processing

## 2.6.1 - [2026-02-16] Formatting Fix

### Fixed
- Applied `dart format` to 6 library files to restore full 160/160 pub.dev score

## 2.6.0 - [2026-02-16] Citations, Text Selection & Example Overhaul

### Added
- **Citation Support**: New `Citation` model and `CitationChip` widget for displaying source references on AI messages
  - `citations` field on `ChatMessage` for attaching source URLs/titles
  - `showCitations` and `citationStyle` on `MessageOptions` for display control
- **Interactive Text Selection**: New `enableInteractiveSelection` parameter on `InputOptions` to control text selection in the input field
  - Fixed `copyWith` bugs in `InputOptions` and related models

### Changed
- **Example App Overhaul**: Replaced 35+ scattered example files with 3 focused, professional examples
  - **Basic Chat** — minimal setup, plain text, no extras
  - **Streaming + Markdown** — code assistant with rich markdown, custom bubble styles
  - **Custom Themes** — Ocean/Sunset/Default theme switcher with per-theme colors and input decoration
  - Each example has distinct AI personality, response style, and shimmer loading text
  - `ExampleAiService` with `ResponseStyle` enum (plain/markdown/conversational)
- **Dependency Updates**: Bumped dependencies to latest compatible versions

### Fixed
- Name collision between package's `MockAiService` and example's mock service (renamed to `ExampleAiService`)
- `copyWith` bugs in `InputOptions`, `MessageOptions`, and related config classes

## 2.5.0 - [2025-11-08] Community Contributions - Spacing Control & UX Enhancements

### Added
- **ChatSpacingConfig**: New centralized configuration for all spacing and padding throughout the chat UI (#27 by @ducnguyenenterprise)
  - Consistent control over message bubble padding and margins
  - Customizable message list padding
  - Configurable quick replies spacing
  - Loading widget spacing control
  - Typing indicator spacing configuration
  - Includes `.compact()` and `.comfortable()` factory methods for common layouts
- **Custom Icon Support**: Added `iconData` parameter to example questions for full icon customization (#27)
- **Keyboard Dismiss Behavior**: New `keyboardDismissBehavior` parameter in `MessageOptions` for scroll-based keyboard dismissal (#27)

### Changed
- **Improved Animation Performance**: Loading animation speed improved from 800ms to 300ms for snappier UX (#27)
- **Optimized Cursor Animations**: Reduced unnecessary cursor animations when not needed (#27)

### Improved
- **Developer Experience**: Centralized spacing configuration makes it much easier to create consistent custom themes
- **Code Organization**: Refactored hardcoded spacing values into configurable system
- **Backward Compatibility**: All changes are optional with defaults matching previous behavior

### Technical
- Refactored spacing from hardcoded `EdgeInsets` to configurable `ChatSpacingConfig`
- All defaults preserve exact previous behavior (verified for backward compatibility)
- Zero breaking changes - completely backward compatible

### Contributors
- @ducnguyenenterprise (Dean Nguyen) - Thank you for this excellent contribution! 🙏

*This release demonstrates our commitment to community-driven development. Special thanks to our contributors for helping make this package better!*

---

## 2.4.2 - [2025-09-10] Critical Bug Fixes & Focus Control Enhancement

### Fixed
- **Streaming Animation Disable**: Fixed critical issue where `enableAnimation: false`, `enableMarkdownStreaming: false`, and `streamingWordByWord: false` parameters were ignored for markdown messages. Markdown messages would always stream regardless of these settings.
  - Updated streaming logic in `CustomChatWidget` to properly respect disable flags
  - Fixed hardcoded streaming parameters that bypassed user configuration  
  - Added proper conditional rendering for static vs streaming markdown
- **Test Coverage**: Added comprehensive tests for streaming disable functionality

### Added
- **Focus Control**: New `autofocus` and `focusNode` parameters in `InputOptions` for enhanced input field control
  - `autofocus: bool` - Automatically focus the input field when widget loads
  - `focusNode: FocusNode?` - Custom focus node for external focus management
  - Available in all factory constructors: `minimal()`, `glassmorphic()`, and default constructor
- **Enhanced API**: Updated `ChatInput` widget to support autofocus functionality
- **Test Coverage**: Added comprehensive tests for focus control features

### Improved  
- **Developer Experience**: Better focus management reduces need for external focus handling
- **API Consistency**: Focus parameters available across all `InputOptions` constructors
- **Documentation**: Updated README with new focus control examples and streaming fix notes

### Technical
- **Breaking Changes**: None - all changes are backward compatible
- **Memory Management**: Proper focus node disposal to prevent memory leaks
- **Test Coverage**: Added 11 new test cases covering focus and streaming scenarios

## 2.4.1 - [2025-09-04] Perfect 160/160 Pub.dev Score Achievement

### Fixed
- **Static Analysis**: Resolved all 33 lint issues for perfect static analysis score
  - Fixed cascade invocation warnings across multiple controller files
  - Removed unnecessary type annotations (int → var, bool → var, etc.)
  - Converted string concatenation to interpolation syntax
  - Escaped HTML angle brackets in documentation comments
  - Removed unnecessary Container wrapper
  - Fixed curly braces in flow control structures
- **Code Formatting**: Resolved all formatting issues identified by pana analysis
- **Directive Ordering**: Sorted import sections alphabetically per Dart conventions

### Improved
- **Pub.dev Score**: Achieved perfect 160/160 points via comprehensive pana analysis
  - Convention: 30/30 points
  - Documentation: 20/20 points (including dartdoc generation)
  - Platform Support: 20/20 points (all 6 platforms + WASM compatibility)
  - Static Analysis: 50/50 points (zero errors, warnings, lints, or formatting issues)
  - Dependencies: 40/40 points (up-to-date dependencies and SDK support)
- **Code Quality**: Significantly improved code maintainability and consistency
- **Documentation**: Complete API documentation with zero dartdoc warnings/errors

### Technical
- **Analysis Score**: Improved from 150/160 to perfect 160/160 pub.dev score
- **Lint Issues**: Reduced from 33 issues to zero blocking issues
- **Package Health**: Achieved excellent validation status with minimal non-scoring warnings
- **Performance**: Optimized code patterns for better runtime performance

## 2.3.6 - [2025-01-31] Package Optimization & Pub.dev Preparation

### Removed
- **Package Cleanup**: Removed unnecessary documentation files and examples to reduce package size
- **Simplified Structure**: Cleaned up doc/ directory, removed duplicate examples and internal documentation
- **File Optimization**: Removed development artifacts and test files not needed in published package

### Improved  
- **Package Metadata**: Optimized pubspec.yaml for better pub.dev scoring with proper topics and metadata
- **Documentation**: Streamlined package structure for better maintainability
- **Performance**: Reduced package footprint by removing non-essential files

### Technical
- **Pub.dev Optimization**: Package prepared for 160/160 pub.dev score achievement
- **Clean Architecture**: Maintained only essential files for production use
- **Better Discovery**: Improved package discoverability with optimized topics and keywords

*This release focuses on package optimization and pub.dev preparation, removing unnecessary files while maintaining full functionality.*

---

## 2.3.6 - [2025-01-31] Issue #18 Fix - CustomBubbleBuilder Implementation

### Fixed
- **CustomBubbleBuilder Functionality**: Fixed Issue #18 where `MessageOptions.customBubbleBuilder` was defined but not implemented
- **Import Resolution**: Fixed ChatMessage import conflict between `models/chat_message.dart` and `models/chat/chat_message.dart`

### Added
- **Custom Bubble Builder Support**: Fully functional customBubbleBuilder allows complete customization of message bubble appearance
- **Comprehensive Test Coverage**: Added extensive test suite for customBubbleBuilder functionality
- **Example Implementation**: Added CustomBubbleBuilderExample demonstrating various customization patterns

### Improved
- **Developer Experience**: CustomBubbleBuilder now works as documented with proper parameter passing
- **Backward Compatibility**: Existing behavior preserved when customBubbleBuilder is null
- **Code Quality**: Enhanced type safety and removed duplicate ChatMessage imports

### Technical
- Enhanced `_buildMessageBubble()` method in custom_chat_widget.dart to use customBubbleBuilder when provided
- Fixed import paths in message_options.dart to use correct ChatMessage type
- Added `_buildDefaultMessageBubble()` helper method for better code organization
- Comprehensive test coverage ensuring reliability and proper parameter handling

*This fix resolves Issue #18 and enhances the package's customization capabilities significantly.*

---

## 2.3.5 - [2025-01-27] PR #16 Integration - Enhanced Link Handling

### Added
- **Automatic URL Launching**: Markdown links now automatically open in external browser when tapped
- **Enhanced onTapLink**: Intelligent link handling with fallback to custom handlers
- **url_launcher Integration**: Added url_launcher dependency for seamless external link support

### Improved  
- **Developer Experience**: Links work out-of-the-box without requiring custom onTapLink implementation
- **Backward Compatibility**: Custom onTapLink handlers still take precedence when provided
- **User Experience**: Smooth link navigation enhances chat interaction flow

### Technical
- Added `url_launcher: ^6.3.1` dependency for external link launching
- Enhanced custom_chat_widget.dart with intelligent URL handling
- Maintained full compatibility with existing MessageOptions.onTapLink customizations

*Special thanks to @AmanuelYosief for PR #16 - these improvements are now integrated!*

---

## 2.3.4 - [2025-01-27] Package Visibility & Marketing Enhancement Release

### Enhanced
- **Package Discoverability**: Improved description, keywords, and metadata for better pub.dev search rankings
- **Marketing Optimization**: Added funding information, enhanced README with performance benchmarks and showcases
- **Developer Experience**: Removed adoption barriers and enhanced documentation clarity
- **Pub.dev Score**: Optimized dependencies and package configuration for maximum scoring

### Fixed
- **Documentation**: Updated version references throughout documentation to v2.3.4
- **Dependencies**: Updated to latest compatible versions for better security and performance
- **Linting**: Fixed unnecessary library naming issues for cleaner code

### Improved
- **SEO Optimization**: Enhanced keywords and descriptions for better package discovery
- **Community Features**: Added showcase section, testimonials, and contribution guidelines
- **Professional Presentation**: Streamlined messaging and removed technical barriers to adoption

---

## 2.3.3 - [2025-01-26] Critical Dependency Update - Professional Quality Release

### Fixed
- **Breaking Dependency Issue**: Replaced discontinued `flutter_markdown` package with `flutter_markdown_plus` for continued support and updates
- **API Compatibility**: Updated all markdown-related code to work seamlessly with `flutter_markdown_plus` API
- **Pub.dev Score Optimization**: Eliminated discontinued dependency warnings that negatively impact package scoring

### Improved
- **Future-Proof Dependencies**: All dependencies are now actively maintained and supported
- **Enhanced Package Reliability**: No more dependency deprecation warnings or security concerns
- **Better Developer Experience**: Smoother installation and usage without discontinued package warnings

### Technical Improvements
- Migrated from `flutter_markdown ^0.7.7` to `flutter_markdown_plus ^1.0.3`
- Updated `flutter_streaming_text_markdown` to latest v1.2.0 with new LLM animation presets
- Updated all import statements across library and example code
- Fixed `imageBuilder` API changes for custom image handling
- Maintained full backward compatibility for existing implementations

## 2.3.2 - [2025-01-26] Professional Quality Release - Comprehensive Package Improvements

### Fixed
- **Critical Memory Leak**: Fixed timer memory leak in ChatMessagesController that was causing test failures and potential production issues
- **Enhanced UI Layouts**: Improved example app interfaces with better responsive design and accessibility
- **Code Quality**: Resolved multiple code quality issues and improved package stability
- **Testing Reliability**: Fixed all failing tests and improved test coverage for streaming functionality

### Improved
- **Example App Design**: Enhanced all example screens with better layouts, improved accessibility, and professional styling
- **Scroll Behavior**: Optimized scroll behavior in intermediate example with better streaming message positioning
- **AppBar Layout**: Fixed responsive design issues in advanced example AppBar with proper title and button sizing
- **Home Screen**: Improved example discovery with better text visibility and optimized information density
- **Documentation**: Updated internal documentation and improved code comments for better maintainability

### Technical Improvements
- Enhanced timer management in ChatMessagesController with proper disposal patterns
- Improved widget lifecycle handling in scroll behavior examples
- Better error handling and state management in streaming examples
- Optimized example app performance with reduced unnecessary rebuilds

## 2.3.0 - [2024-07-12] File Upload & Media Attachments

### Added
- **File Upload Support**: Comprehensive file upload capabilities for images, documents, videos, and more
- **Flexible Media Attachments**: ChatMedia model to represent various media types in messages
- **Customizable Upload Options**: FileUploadOptions to control upload behavior, buttons, and limits
- **Image Caption Support**: Added the ability to include captions with uploaded images
- **Multiple File Support**: Ability to upload and display multiple files in a single message
- **Full Platform Permissions**: Documentation for required permissions on iOS, Android, and macOS
- **Full Example Implementation**: Complete real-world file upload example in the example app

### Fixed
- Fixed several code quality issues to improve the package's pub score
- Resolved deprecated method usage throughout the codebase
- Fixed type inference issues for better static analysis compatibility

## 2.2.1 - [2024-05-16] Better Image Control & Developer Experience

### Added
- **Image Interaction Control**: Added `enableImageTaps` parameter to `MessageOptions` to control whether images in markdown content respond to tap events
- **Enhanced Documentation**: Added comprehensive usage examples for controlling image interactions

### Fixed
- Prevented unintended navigation when tapping images in markdown content by default

## 2.2.0 - [2024-05-05] Scroll Behavior Controls & UX Improvements

### Added
- **New Scroll Behavior Controls**: Fix for Issue #13 - Prevent auto-scrolling that hides the top of long responses
- **ScrollBehaviorConfig**: Configure when and how the chat should auto-scroll
  - Control auto-scroll behavior with options: always, onNewMessage, onUserMessageOnly, or never
  - Optional feature to scroll to the first message of a response rather than the last
  - Customizable animation duration and curve for scrolling
- **Enhanced User Experience**: Better control over scrolling behavior for long AI responses
- **Comprehensive Example**: Added a dedicated example demonstrating all scrolling options

### Fixed
- **Fixed Issue #13**: Resolved the problem where long AI responses would auto-scroll, pushing the beginning of the response out of view
- **Improved Accessibility**: Users can now read the beginning of long responses without manual scrolling

## 2.1.2 - [2024-04-22] Dependency Cleanup & Broader Compatibility

### Changed
- **Removed permission_handler**: Removed as a core dependency since it's only needed for optional speech-to-text functionality
- **Enhanced SDK Compatibility**: Further improved compatibility by eliminating unnecessary dependencies
- **Updated Documentation**: Clarified speech-to-text implementation needs to be handled by the app developer
- **Dependency Optimization**: Removed several unused dependencies (intl, flutter_animate, provider, scrollable_positioned_list, url_launcher) to reduce package footprint

### Benefits
- No more SDK version conflicts with permission_handler dependency
- Significantly smaller package footprint (~60% reduction in external dependencies)
- Faster installation and build times
- More flexibility for implementing speech recognition with your preferred tools
- Reduced risk of version conflicts with other packages in your app

## 2.1.1 - [2024-04-22] Critical SDK Compatibility Fixes

### Fixed
- **SDK Compatibility**: Lowered minimum Dart SDK to `>=2.19.0` to ensure broader compatibility
- **Color Extensions**: Fixed `withOpacityCompat` to avoid using `withValues` internally, resolving errors on older Dart SDKs
- **Dependency Compatibility**: Downgraded `permission_handler` to version 10.2.0 for compatibility with Dart SDK 2.19+

### Changed
- Improved implementation of color opacity handling to work across all supported SDK versions
- Enhanced documentation around SDK compatibility requirements
- Extensive testing across multiple Flutter and Dart SDK versions

## 2.1.0 - Major Update: Dart 3.5+ & ChatGPT‑Style UI Enhancements

### Added
- Bumped Dart SDK lower bound to `>=3.5.0` for `permission_handler` compatibility
- Introduced ChatGPT‑style input capsule: full capsule radius, exact fill colors, and border
- Quick‑prompt chips above the text field with horizontal scroll support
- Inline action icons row merged into the same capsule material as input
- Animated send‑button opacity and scale based on content presence

### Changed
- Updated `ChatGPTTokens` to use official ChatGPT dark mode hex values
- Revised `InputOptions.chatGPTDefaults` for full capsule styling and padding
- Bumped package version to **2.1.0**
- Updated installation instructions in README & USAGE docs

### Fixed
- Formatted codebase and resolved all static analysis warnings
- Aligned `pubspec.yaml` environment SDK constraint with dependencies

## 2.0.8 - [2024-06-22] Pub Points & Static Analysis Fixes

### Changed
- Bumped package version to 2.0.8
- Shortened pubspec description for pub.dev guidelines
- Added valid issue_tracker URL

### Fixed
- Removed duplicate import in custom_chat_widget.dart
- Simplified withOpacityCompat implementation
- Resolved all static analysis warnings

## 2.0.7 - [2024-06-21] Pub Points & Static Analysis Fixes

### Changed
- Shortened pubspec description for pub.dev guidelines

### Fixed
- Removed duplicate import in custom_chat_widget.dart
- Removed deprecated withOpacity fallback in color_extensions.dart
- All static analysis warnings resolved

# Changelog

## 2.0.4 - [2024-07-05] Code Quality & Publication Improvements

### Changed
- Fixed all static analysis warnings to achieve top pub.dev score
- Made property types more consistent with proper nullability
- Improved type safety throughout the codebase
- Fixed import paths to avoid deprecated references
- Updated example question config to handle nullable properties correctly
- Enhanced review analysis widget with proper type annotations

## 2.0.3 - [2024-06-30] SEO & Static Analysis Improvements

### Changed
- Enhanced package description with more AI-specific keywords for better discoverability
- Added comprehensive keywords section to pubspec.yaml for improved searchability
- Updated permission_handler dependency to v12.0.0+1
- Fixed static analysis warnings and errors in ai_chat_widget.dart
- Improved example app descriptions with AI model-specific terms
- Added detailed AI model integration section to README
- Enhanced feature descriptions for better discoverability

## 2.0.2 - [2023-03-15] Input Behavior Improvements

### Changed
- Made send button always visible by default at the package level
- Completely removed the `alwaysShowSend` property as it's now redundant
- Modified default input behavior to prevent focus issues when typing
- Updated documentation to reflect the new send button behavior

## 2.0.0 - [2023-06-10] API Streamlining & Dila Alignment

### Breaking Changes
- Overhauled API to align more closely with Dila patterns
- Moved from centralized `AiChatConfig` to direct parameters in `AiChatWidget`
- Streamlined redundant and deprecated properties
- Reorganized configuration classes for better usability

### Improvements
- Enhanced documentation with comprehensive usage guide
- Added detailed migration guide from 1.x to 2.0
- Better IDE autocompletion support
- More intuitive parameter naming
- Cleaner code organization
- Simplified configuration objects

### Backward Compatibility
- Added `@Deprecated` markers to guide migration
- Maintained core functionality while improving API
- Preserved configuration objects but made them more focused
- See `docs/MIGRATION.md` for detailed migration guidance

## 1.3.0 - [2023-03-12] Feature Enhancements & Refinements

### New Features
- Enhanced markdown support with better code block styling
- Improved dark theme contrast and readability
- Better message bubble animations
- Fixed layout overflow issues
- Enhanced error handling

### Configuration Updates
1. All widget-level configurations now flow through `AiChatConfig`
2. Improved input handling with standalone `InputOptions`
3. Enhanced pagination with `PaginationConfig`
4. Better loading states with `LoadingConfig`
5. Centralized callbacks in `CallbackConfig`

## 1.2.0 - [2023-01-25] Improved UI & Performance

### New Features
- Improved message bubble design
- Added glassmorphic input option
- Enhanced streaming text animation
- Better error recovery
- Optimized performance for long chats

## 1.1.0 - [2022-12-08] Core Feature Updates

### Added
- RTL language support
- Improved markdown rendering
- Message pagination
- Better loading indicators
- Customizable welcome message

## 1.0.0 - [2022-11-15] Initial Release

### Initial Features
- Basic chat UI with AI-specific features
- Dark/light mode support
- Streaming text animation
- Markdown support
- Customizable styling
- Message management
- Simple welcome message

## [1.3.0] - 2024-03-21
### Breaking Changes
- Consolidated all widget configurations into `AiChatConfig`
- Deprecated widget-level properties in favor of config-based approach
- Improved input handling with standalone `InputOptions`
- Enhanced configuration structure for better developer experience

### Added
- Full markdown support with proper styling and dark mode compatibility
- Enhanced input customization with comprehensive options
- Improved pagination with better error handling
- Added markdown syntax help dialog
- Added proper blockquote and code block styling
- Added comprehensive error handling for markdown parsing

### Fixed
- Fixed overflow issues in welcome message layout
- Improved dark theme contrast and readability
- Enhanced message bubble animations
- Fixed input field spacing and margins
- Resolved all open GitHub issues (#1-#4)

## [1.2.0] - 2024-02-11
### Changed
- Made speech-to-text an optional dependency
- Updated documentation for optional STT integration
- Improved example implementation for speech-to-text
- Streamlined package dependencies
- Enhanced README structure and clarity

## [1.1.9] - 2024-02-07
### Added
- Updated streaming text performance with flutter_streaming_text_markdown
- Enhanced markdown rendering capabilities
- Improved dark theme with consistent colors
- Fixed various bugs and improved performance
- Added proper null checks and error handling
- Updated dependencies to latest stable versions

## [0.1.0] - 2024-10-19
### Added
- Initial release of flutter_gen_ai_chat_ui package.
- Customizable chat UI with theming, animations, and markdown streaming support using flutter_streaming_text_markdown.
- Streaming example updated to use flutter_streaming_text_markdown package.

### Changed
- Reverted Dila dependency to ^0.0.21 for compatibility.

### Fixed
- Minor UI and linter issues.

## 1.1.7

* Made speech-to-text an optional dependency
* Improved error handling for missing STT dependency
* Updated documentation for optional STT setup
* Fixed platform-specific STT implementation
* Added clear error messages for STT requirements
* Fixed speech-to-text button function return type inference
* Added proper type annotations for callback functions
* Fixed missing await warnings
* Code quality improvements

## 1.1.6

* Enhanced speech-to-text functionality with visual feedback
* Added sound level visualization with animated bars
* Added pulsing animation for active recording state
* Improved error handling for iOS speech recognition
* Added automatic language detection
* Added theme-aware styling for speech button
* Updated documentation with new speech-to-text features

## 1.1.5

* Enhanced loading indicator text size and visibility
* Improved shimmer effect contrast in both light and dark themes
* Optimized color values for better accessibility

## 1.1.4

* Improved loading indicator visibility in both light and dark themes
* Enhanced shimmer effect contrast and animation
* Increased loading text size and readability
* Optimized loading animation timing

## 1.1.3

* Added comprehensive test coverage
* Fixed dependency conflicts
* Updated platform support information
* Improved documentation
* Fixed unused variables in example files
* Updated dependencies to latest compatible versions
* Added const constructors for better performance
* Improved code organization and structure

## 1.1.2

* Added platform support information
* Updated package description
* Fixed linting issues
* Removed unused variables
* Updated dependencies

## 1.1.1

* Initial release with basic features
* Added customizable chat UI
* Added support for streaming responses
* Added code highlighting
* Added markdown support
* Added dark mode support
* Added RTL support
* Added example applications

## 1.1.8

* Improved dark theme contrast and visibility
* Enhanced AI message animations in streaming example
* Fixed package dependencies and imports
* Improved message bubble animations and transitions
* Updated theme toggle button styling
* Fixed various linter issues
* Removed redundant dependencies
* Added CustomThemeExtension to package exports

## 1.1.9

* Updated flutter_streaming_text_markdown to version 1.1.0
* Improved streaming text performance and reliability
* Enhanced markdown rendering capabilities

## [1.3.0] - Unreleased
### Breaking Changes
- Moved all widget-level configurations into `AiChatConfig`
- Added deprecation warnings for widget-level properties
- Improved configuration structure for better developer experience
- Enhanced documentation and property descriptions

### Added
- New loading state configurations in `AiChatConfig`
- Improved error messages and assertions
- Better documentation for input options and animations

## 0.0.x - Unreleased

### Added
- Enhanced loading indicator functionality with two display modes:
  - Bottom-aligned typing indicator (default) - shows loading near the input box like ChatGPT/Claude
  - Centered overlay indicator (optional) - shows loading in the center of the chat area
- Added `showCenteredIndicator` property to `LoadingConfig` to control loading indicator position
- New loading example demonstrating both loading styles

### Changed
- Default message order now shows newest messages at the bottom (like ChatGPT/Claude)
  - Changed default for `PaginationConfig.reverseOrder` from `true` to `false`
  - Updated documentation and comments to reflect the change
- Improved scroll-to-bottom behavior to work correctly in both chronological and reverse order modes
- Enhanced loading indicator handling for better UX

### Fixed
- Scroll position detection for the scroll-to-bottom button
- Message ordering when adding new messages

## [2.0.x] - YYYY-MM-DD
### Fixed
- Added `withOpacityCompat` extension for full compatibility with all Flutter/Dart SDKs.
- Migrated all usages of `.withOpacity(x)` and `.withValues(alpha: x)` to `.withOpacityCompat(x)`.
- No more build errors for users on Flutter <3.27.0.

## [2.0.5] - 2024-06-09
### Fixed
- Added `withOpacityCompat` extension for full compatibility with all Flutter/Dart SDKs.
- Migrated all usages of `.withOpacity(x)` and `.withValues(alpha: x)` to `.withOpacityCompat(x)`.
- No more build errors for users on Flutter <3.27.0.

## [2.0.6] - 2024-06-20
### Changed
- Prepare for next release by bumping version to 2.0.6

<!-- Next version changes go here -->
