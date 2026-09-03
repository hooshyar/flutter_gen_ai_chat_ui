**Priority:** P1
**Component:** pubspec.yaml
**Origin:** GOAL item 5 + item 4 (flutter_streaming_text_markdown pin)

**Acceptance criteria:**
- [x] Run `flutter pub outdated` (repo root and `example/`), record findings — root: only `shimmer`
      outdated (3.0.0 → 4.0.0), everything else already at latest resolvable. example/: several
      transitive deps locked-but-resolvable (refreshed via `flutter pub upgrade`), 2 constrained below
      resolvable (`shimmer`, `flutter_lints` — the latter not touched, see below).
- [x] Check pub.dev for `flutter_streaming_text_markdown`'s actual latest stable — confirmed via
      WebFetch to pub.dev (not memory): **1.9.1**, published ~54 days ago, matches what was already
      resolved in `pubspec.lock`. Raised the `pubspec.yaml` lower-bound pin from `^1.8.0` to `^1.9.1`
      to make that explicit.
- [x] Upgrade all other deps to latest stable where safe; verify `flutter analyze` + `flutter test`
      stay green after each bump. `shimmer` 4.0.0 deliberately HELD BACK — confirmed via its
      pub.dev changelog that it requires Flutter `>=3.44.0` / Dart `^3.12.0`, above this package's
      declared floor (Flutter `>=3.27.0` / Dart `>=3.6.0`); bumping it would silently raise the real
      minimum SDK for anyone using the shimmer-based `LoadingWidget`. Documented with a pubspec.yaml
      comment. `flutter pub upgrade` in `example/` refreshed 18 locked-but-resolvable transitive deps
      (no direct dep version changes there either). `example/pubspec.lock` updated + committed
      (tracked per project convention).
- [x] Cleanup surfaced by this pass: the `example/` app's own `flutter analyze` picked up 2
      `deprecated_member_use` infos for `enableAnimation` (deprecated in task-002, round 5) —
      removed the dead usage from `basic_chat.dart` and the integration-test helper/call sites; one
      test ("Should not animate streaming when disabled") had never actually verified its own stated
      intent since `enableAnimation` never worked — fixed to use `enableMarkdownStreaming: false`
      instead, which does.
- [x] Re-run `dart pub publish --dry-run` after upgrading — clean (aside from the expected
      uncommitted-files warning, resolved by the commit). `dart analyze --fatal-infos` (root) and
      `flutter analyze` (example/) both clean. `flutter test` 388/388 green.
- [x] Note in CHANGELOG.md.

**Status:** DONE.

## Re-checked (2026-09-03, post task-008/009 release round)

`flutter pub outdated` after several ticks of feature work: only real, actionable finding was
`flutter_streaming_text_markdown` `^1.9.1` → `^1.10.1` (both versions published same-day,
2026-09-03 — likely the sibling maintainer session for that package). Checked its changelog before
upgrading (backward-compatible per its own semver: real LaTeX rendering, a web clipboard fix, a
word-by-word resume bug fix, no breaking changes, no new floor pressure — `characters >=1.4.0` /
`flutter >=3.10.0` unchanged). Everything else outdated is either `clock` (deliberately held at
`^1.1.2` to match Flutter's own bundled `flutter_test` exact pin — see task-019/task-012) or
transitive deps with no direct action needed. 458/458 tests green after the bump, no code changes
required on this side.
