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

## Done — v2.18.0 (2026-09-03)

Minor release for the one substantial item unreleased since v2.17.1: the opt-in `ChatPersistence`
hook for long-running threads (task-009), plus the `PaginationConfig.scrollThreshold` deprecation.
Minor-version bump (not patch) since `ChatPersistence` is genuinely new public API surface, not just
a fix. Zero breaking changes.

- Tag `v2.18.0` pushed → `publish.yml` run 33750084621 succeeded → confirmed live at
  `pub.dev/packages/flutter_gen_ai_chat_ui` (latest version 2.18.0 via the pub.dev API).
- Live web demo redeployed automatically.
- **Confirmed 160/160 pub points** on a fresh, uncontended `pana` run.
- 443/443 root tests + 8/8 example tests green, both `analyze --fatal-infos` clean, `dart format`
  clean, all CI jobs green pre- and post-tag.

## Done — v2.17.1 (2026-09-03)

Small patch release bundling the 2 items unreleased since v2.17.0: the scroll-debounce clock
injection fix (task-019 — an internal test-reliability fix, zero runtime behavior change for
consumers) and the provider integration cookbook recipes (task-011, docs-only). Zero breaking
changes; patch-level bump since neither item touches public API surface.

- Tag `v2.17.1` pushed → `publish.yml` run 33747314755 succeeded → confirmed live at
  `pub.dev/packages/flutter_gen_ai_chat_ui` (latest version 2.17.1 via the pub.dev API).
- Live web demo redeployed automatically.
- **Confirmed 160/160 pub points** on a fresh, uncontended `pana` run — the new `package:clock`
  dependency didn't cost anything.
- 436/436 root tests + 8/8 example tests green, both `analyze --fatal-infos` clean, `dart format`
  clean, all CI jobs green pre- and post-tag.

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

## Done — v2.17.0 (2026-09-03)

Bundled everything unreleased since 2.16.2: the Flutter floor correction to `>=3.35.0` (task-012 —
the previously-documented `>=3.27.0` never actually resolved for a real consumer, found by the new
`sdk-matrix` CI job), the `shimmer` dependency removal (hand-rolled the loading-widget sweep effect),
the new performance-benchmark suite (task-014), and the doc-drift + SDK-matrix CI checks themselves
(task-012). Zero breaking changes for anyone who could previously build the package.

- Tag `v2.17.0` pushed → `publish.yml` run 33743319101 succeeded → confirmed live at
  `pub.dev/packages/flutter_gen_ai_chat_ui` (latest version 2.17.0 + corrected `environment:` via the
  pub.dev API) shortly after the workflow completed.
- Live web demo redeployed automatically (`deploy-web-demo.yml` on the release-prep push).
- **Confirmed 160/160 pub points** on a fresh, uncontended `pana` run against v2.17.0 — the
  `shimmer` dependency-freshness warning that used to show up here is gone now that the dependency
  itself was removed.
- Updated issue #41's checklist (checked off golden tests, a11y tap-targets, CI SDK matrix, example
  gallery, doc/code-drift CI — all shipped since the last update) and posted a detailed progress
  comment. #42 unchanged this round (release doesn't touch that feature).
- 434 root tests + 8 example tests green, both `analyze --fatal-infos` clean, `dart format` clean,
  all 5 CI jobs green pre-tag.
