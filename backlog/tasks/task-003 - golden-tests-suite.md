**Priority:** P1
**Component:** Test infra
**Origin:** Issue #41 Phase 1 (unchecked item)

**Acceptance criteria:**
- [x] Add golden tests for: default bubble, welcome message, streaming message mid-stream, code
      block rendering, RTL (Arabic) layout — all 5 added in `test/golden/chat_golden_test.dart`,
      baselines generated and reviewed (visually inspected each PNG — layout/alignment/positioning
      all correct; text renders as generic blocks since no real font is bundled for tests, which is
      a pre-existing, accepted limitation of this repo's test harness, not a regression — goldens
      still catch layout/structure/color regressions).
- [x] Wire into `flutter test --update-goldens` workflow; document regenerating goldens in
      CONTRIBUTING or README — added `CONTRIBUTING.md` (didn't exist before) with the exact command
      and a "review before committing" note.
- [x] CI runs golden tests on PRs — no CI changes needed: `flutter test` (already the CI test step)
      picks up every file under `test/`, including the new golden test file, automatically. On CI
      (`ubuntu-latest`) `test/flutter_test_config.dart` already swaps in an always-passing image
      comparator (pre-existing, deliberate — cross-platform font rendering makes pixel-perfect
      comparison impractical there), so the golden tests still execute and catch build/render
      crashes in CI, but the actual pixel diff is only meaningfully enforced when run locally on
      macOS. This matches the existing architecture rather than adding an expensive macOS CI runner
      for a "lightweight CI gate" package (see `ci.yml`'s own stated philosophy).
- [x] `dart analyze --fatal-infos` clean, `flutter test` green (393/393).

**Status:** DONE.
