**Priority:** P1
**Component:** Release
**Origin:** GOAL item 6

**Problem:** Once task-001 (fix #42) and a meaningful slice of the roadmap items above are done,
cut the next release.

**Acceptance criteria:**
- [x] `flutter analyze` clean, `flutter test` green, `dart pub publish --dry-run` passes.
- [x] Bump `version:` in pubspec.yaml + README install snippet.
- [x] CHANGELOG.md entry (Added/Changed/Fixed/Notes, zero-breaking-change note if applicable).
- [x] Tag `vX.Y.Z` and push — confirm CI publish succeeds (see task-017 gate) or fall back to
      local `dart pub publish` if automated publishing still isn't enabled.
- [x] Verify the pub.dev package page reflects the new version and pana score.
- [x] Reply/close relevant GitHub issues (#42 at minimum) referencing the released version.

**Notes:** Re-run this task for each subsequent release as the backlog above gets worked through —
don't treat it as one-and-done.

## Done — v2.16.2 (2026-09-03)

First release to actually go out through the newly-enabled GitHub Actions OIDC publish (task-017) —
no manual `dart pub publish` step needed. Bundled everything unreleased at the time: the
`CustomThemeExtension` fix (task-002), 6 dead/superseded-field deprecations, the completed dartdoc
pass (task-013), verified wasm support (task-015), `docs/AWARD-PLAN.md` + repo polish (task-016),
and the 3 live-demo visual-QA fixes (tasks 022-024). Zero breaking changes.

- Tag `v2.16.2` pushed → `publish.yml` run 33736124975 succeeded → confirmed live at
  `pub.dev/packages/flutter_gen_ai_chat_ui` (latest version 2.16.2 via the pub.dev API) within ~15s
  of the workflow completing.
- Live web demo redeployed automatically (`deploy-web-demo.yml` on the release-prep push) and
  verified showing the new v2.16.2 badge.
- Replied on #42 flagging that 2.16.0's pin feature had a same-day regression (fixed in 2.16.1)
  specifically affecting the `addStreamingMessage` flow the example app itself uses — so bernd70
  doesn't waste a test cycle on the broken version — and asked him to confirm on 2.16.2.
- 426 root tests + 8 example tests green, both `analyze --fatal-infos` clean, `dart format` clean.
