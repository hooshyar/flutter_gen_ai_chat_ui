**Priority:** P1
**Component:** Package-wide config surface
**Origin:** Issue #41 Phase 0.5 (unchecked item)

**Problem:** Historical bug pattern: documented parameters that silently do nothing (#40, #30, #18,
#20, #9, #38, #24, #28, #3, #6 — all fixed individually, but no systematic guard exists).

**Acceptance criteria:**
- [ ] Enumerate every public, documented config knob across `AiChatWidget`, `MessageOptions`,
      `InputOptions`, `ScrollBehaviorConfig`, `CustomThemeExtension`, etc.
- [ ] For each knob without an existing test asserting visible effect, add one (widget test that
      toggles the knob and asserts the rendered/behavioral difference).
- [ ] Document any knob found to be dead-wired; fix or deprecate it.
- [ ] `flutter analyze` clean, `flutter test` green.
- [ ] Reply progress on issue #41.

**Notes:** This is a "trust" investment per #41's thesis — prevents the next silent-no-op bug report.
