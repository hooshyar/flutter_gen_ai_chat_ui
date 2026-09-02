**Priority:** P2
**Component:** ChatMessagesController
**Origin:** GitHub issue #13, Issue #41 Phase 3 (unchecked item)

**Acceptance criteria:**
- [ ] Design an opt-in lazy-pagination API for `ChatMessagesController` (load-older-messages on
      scroll-to-top) — additive, doesn't change default in-memory behavior.
- [ ] Provide a persistence hook/interface (consumer supplies storage; package doesn't force a
      specific backend) for restoring long threads.
- [ ] Add a performance benchmark test for long conversations (see task-014) to validate this
      actually helps.
- [ ] Tests + docs.
