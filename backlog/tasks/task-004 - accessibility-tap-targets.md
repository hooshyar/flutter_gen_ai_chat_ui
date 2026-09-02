**Priority:** P1
**Component:** Accessibility
**Origin:** Issue #41 Phase 1 (unchecked item)

**Problem:** Send button and other icon-only tap targets may be under the 48dp Material/WCAG
minimum. `sendButtonTooltip` a11y label already shipped in 2.15.0; tap-target sizing is the
remaining gap.

**Acceptance criteria:**
- [ ] Audit tap targets across `ChatInput`, message actions, and any icon buttons using
      Flutter's `labeledTapTargetGuideline` / `meetsTapTargetGuideline` test matchers.
- [ ] Fix any under-48dp targets (padding/InkWell hit area, not visual size) without changing visual design.
- [ ] Add a widget test asserting the guideline passes for the input row and message action buttons.
- [ ] `flutter analyze` clean, `flutter test` green.
