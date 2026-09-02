**Priority:** P2
**Component:** test/ (benchmark harness)
**Origin:** GOAL item 4

**Acceptance criteria:**
- [ ] Add a benchmark test (e.g. `flutter test` with a timed harness, or `benchmark_harness`) that
      measures build/scroll performance with 500-2000+ messages in `ChatMessagesController`.
- [ ] Record baseline numbers in the PR/CHANGELOG so regressions are visible over time.
- [ ] If a real bottleneck is found (e.g. no item-extent/lazy building), file it as a follow-up task
      rather than scope-creeping this one.
