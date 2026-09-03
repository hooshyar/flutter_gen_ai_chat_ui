---
id: TASK-021
title: 'Example home screen shows a hardcoded stale version badge (v2.14.0 while 2.16.0 is live)'
status: Done
priority: medium
labels:
  - example
  - web-demo
  - quick-fix
created_date: '2026-09-03'
---

## Description

Verified on the live web demo https://hooshyar.github.io/flutter_gen_ai_chat_ui/ on 2026-09-03: the
badge under the title reads **v2.14.0**, but pub.dev has **2.16.0**. Source: `example/lib/home_screen.dart:199`
is the literal string `'v2.14.0'`. It has been wrong for two releases and will be wrong for every future one.

## Acceptance Criteria
- [x] The badge is derived, not typed: read the package version at build time (e.g. a `--dart-define`
      set by `deploy-web-demo.yml` from `pubspec.yaml`, or a generated `version.dart` written by a
      tiny script run in CI and locally via `flutter pub run`), with a sensible fallback.
- [x] `deploy-web-demo.yml` passes/generates it so the live demo always shows the released version.
- [x] A test asserts the badge equals the version in `pubspec.yaml`.
- [x] Redeploy; the live demo shows 2.16.0 (or whatever is current).

## Done (2026-09-03)

Went with the "generated `version.dart`" option (named `example/lib/version_info.dart` — deliberately
NOT `*.g.dart`, since the repo's root `.gitignore` has a blanket `**/*.g.dart` rule that would have
silently kept it out of git and broken a bare `flutter run`/`flutter test` with no generation step
run first).

- `example/tool/generate_version.dart` — a plain `dart:io` script (no build_runner) that regexes
  `version:` out of the package's `pubspec.yaml` and writes `example/lib/version_info.dart`
  (`const String packageVersion = '...';`). Run via `dart run tool/generate_version.dart` from
  `example/`.
- The generated file IS committed (small, single line of real content, low conflict risk) so a plain
  checkout still builds without a generation step — but `deploy-web-demo.yml` regenerates it fresh
  before every web-demo build regardless, so the LIVE demo can never be stale even if a release
  forgot to regenerate/commit locally.
- `example/test/version_badge_test.dart`: one test asserts the committed `packageVersion` equals
  `pubspec.yaml`'s `version:` (catches local drift as a loud `flutter test` failure instead of a
  silent stale badge); a second renders the home screen and asserts the badge text matches.
- `home_screen.dart`'s literal `'v2.14.0'` replaced with `'v$packageVersion'`.
- Added the regeneration step to CLAUDE.md's release checklist (step 4) so a manual release also
  remembers it, not just CI.
- Verified: `dart pub publish --dry-run`-relevant checks (root `dart analyze --fatal-infos` clean,
  `flutter test` 416/416) plus example `flutter analyze` clean, `flutter test` 5/5 (incl. the 2 new
  tests). Live-demo redeploy verification (before/after screenshots) done as part of this tick — see
  session notes; the CI workflow (`deploy-web-demo.yml`) picks up the push to `main` and redeploys
  automatically, no manual trigger needed.
