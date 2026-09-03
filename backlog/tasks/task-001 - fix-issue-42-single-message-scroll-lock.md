**Priority:** P0
**Component:** ScrollBehaviorConfig / scroll controller
**Origin:** GitHub issue #42 (2026-08-13, @bernd70)

**Problem:** `ScrollBehaviorConfig` handles autoscroll across multiple agent responses, but there's
no way to stop autoscrolling once a *single* long streaming message's top edge reaches the top of
the visible viewport. User wants to pin the top of the streaming answer in view instead of
continuously autoscrolling to the bottom as it streams.

**Acceptance criteria:**
- [x] Read `ScrollBehaviorConfig` and the autoscroll logic in the controller/widget to confirm current behavior.
- [x] Root cause found: `scrollToMessage`/`forceScrollToFirstMessageInChain` computed the target from `index/itemCount` (assumes uniform message heights), which collapses to "just show the bottom" for reverse:true lists with one short + one very long message. Fixed by measuring the real rendered position via a `BuildContext` resolver + `Scrollable.ensureVisible` (alignment corrected for reverse lists) — additive, no breaking change, existing `scrollToFirstResponseMessage: true` knob now works correctly for a single message.
- [x] Added `test/controllers/scroll_to_first_response_single_message_test.dart` (2 tests).
- [x] `dart analyze --fatal-infos` clean, `flutter test` green (374/374).
- [x] Replied on GitHub issue #42: https://github.com/hooshyar/flutter_gen_ai_chat_ui/issues/42#issuecomment-5515729977
- [x] CHANGELOG.md updated (Unreleased section).

**Status:** DONE — commit 7022038 on main, pushed to origin.

**Notes:** This is the highest-value fix — it's a live user complaint, not a roadmap nice-to-have.


## Follow-up (2026-09-03)
bernd70 tested this fix and reports it is not the behaviour he wants (he wants a streaming-time pin, not an end-of-stream jump). See TASK-020 (Done 2026-09-03, shipped in v2.16.0).
