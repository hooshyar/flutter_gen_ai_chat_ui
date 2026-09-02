**Priority:** P2
**Component:** ChatMessage / controller API
**Origin:** GitHub issue #37, Issue #41 Phase 3 (unchecked item)

**Problem:** The "thinking → streamed answer" pattern (show a loading/thinking indicator, then
morph into the streamed final answer) is currently only documented as a cookbook recipe using
existing primitives (`ChatMessage.loading` → `updateMessage` → streamed text). No first-class API.

**Acceptance criteria:**
- [ ] Design an additive factory/helper (e.g. `ChatMessage.thinking(...)` or a controller helper)
      that wraps the existing loading→streaming morph pattern into one call.
- [ ] No breaking changes to existing `ChatMessage`/`ChatMessagesController` API.
- [ ] Add unit + widget tests.
- [ ] Update cookbook doc to reference the new first-class API instead of (or alongside) the manual pattern.
- [ ] Reply progress on issue #37 if still open, and on #41.
