**Priority:** P1
**Component:** Accessibility
**Origin:** Issue #41 Phase 1 (unchecked item)

**Problem:** Send button and other icon-only tap targets may be under the 48dp Material/WCAG
minimum. `sendButtonTooltip` a11y label already shipped in 2.15.0; tap-target sizing is the
remaining gap.

**Acceptance criteria:**
- [x] Audit tap targets across `ChatInput`, message actions, and any icon buttons — used
      `tester.ensureSemantics()` + `meetsGuideline(androidTapTargetGuideline)` against the real
      `AiChatWidget` render tree to find actual violations empirically rather than reasoning about
      layout abstractly. Found 2 real violations (below) plus one out-of-scope known quirk.
- [x] Fix any under-48dp targets (padding/InkWell hit area, not visual size) without changing visual
      design:
      - Default send button — the `IconButton` has its own 48x48 minimum constraint, but a
        fixed-height `Container` around it in `chat_input.dart` (`(contentPadding.vertical ?? 14) +
        24` ≈ 38px with default `InputOptions`) was capping it below that. Floored the fallback
        computation at 48 (an explicit consumer-set `inputHeight` is left alone — that's a
        deliberate choice, not a bug).
      - Icon-only scroll-to-bottom button (`ScrollToBottomOptions.showText` defaults to `false`) —
        its tap area came directly from a `Padding(vertical: 8, horizontal: 12)` around a 20px icon
        (~36-44px). Bumped to `EdgeInsets.all(14)` (icon 20 + 14 + 14 = 48).
      - Bonus: fixed a stale doc comment on `ScrollToBottomOptions.showText` claiming its default
        was `true`; it's actually `false`.
      - Known, NOT fixed: the default `TextField`'s own semantics node also fails the guideline (it
        reports its intrinsic single-line text content box, ~24px, not the full decorated input
        area) — a known Flutter quirk unrelated to this package. Fixing it would mean deliberately
        growing the default input row's height as a visual redesign decision, which is explicitly
        out of scope for a "no visual design change" tap-target fix. Documented, not silently
        ignored.
      - Both real fixes DO make the icons' *containers* modestly taller/larger (by design — that's
        the whole point of a tap-target fix) while the icons themselves are pixel-identical; the 5
        golden baselines were regenerated and reviewed to reflect this.
- [x] Add a widget test asserting the guideline passes for the input row and message action buttons
      — `test/widgets/accessibility_tap_targets_test.dart` (3 tests). Asserts each button's measured
      size directly (`tester.getSize(...) >= Size(48,48)`) rather than running the blanket
      `meetsGuideline` matcher against the whole tree, specifically to avoid the known TextField
      false-positive above swallowing real regressions in unrelated future guideline runs.
- [x] `dart analyze --fatal-infos` clean, `flutter test` green (396/396).

**Status:** DONE.
