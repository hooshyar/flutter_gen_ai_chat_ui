**Priority:** P2
**Component:** lib/src/agents/, result renderers
**Origin:** Issue #41 Phase 3 (unchecked item)

**Acceptance criteria:**
- [ ] Audit current default renderers for tool-call/agent status (pending/running/success/error).
- [ ] Polish default visuals (consistent with theme system, dark-mode aware) without requiring
      consumers to supply custom `resultRenderers`.
- [ ] Add widget tests per status state.
- [ ] Document in cookbook.
