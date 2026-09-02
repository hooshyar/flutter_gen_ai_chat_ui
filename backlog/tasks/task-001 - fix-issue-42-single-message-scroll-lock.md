**Priority:** P0
**Component:** ScrollBehaviorConfig / scroll controller
**Origin:** GitHub issue #42 (2026-08-13, @bernd70)

**Problem:** `ScrollBehaviorConfig` handles autoscroll across multiple agent responses, but there's
no way to stop autoscrolling once a *single* long streaming message's top edge reaches the top of
the visible viewport. User wants to pin the top of the streaming answer in view instead of
continuously autoscrolling to the bottom as it streams.

**Acceptance criteria:**
- [ ] Read `ScrollBehaviorConfig` and the autoscroll logic in the controller/widget to confirm current behavior.
- [ ] Add an option (e.g. `scrollToFirstResponseMessage` extension, or a new config knob) that lets a single long streaming message stop autoscrolling once its top reaches the viewport top — additive, no breaking change.
- [ ] Add a regression/widget test reproducing the reported scenario (one long streaming message, verify scroll position stabilizes at the top instead of chasing the bottom).
- [ ] `flutter analyze` clean, `flutter test` green.
- [ ] Reply on GitHub issue #42 with the fix, version it'll ship in, and a short usage snippet.
- [ ] Update CHANGELOG.md.

**Notes:** This is the highest-value fix — it's a live user complaint, not a roadmap nice-to-have.
