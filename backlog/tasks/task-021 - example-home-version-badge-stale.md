---
id: TASK-021
title: 'Example home screen shows a hardcoded stale version badge (v2.14.0 while 2.16.0 is live)'
status: To Do
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
- [ ] The badge is derived, not typed: read the package version at build time (e.g. a `--dart-define`
      set by `deploy-web-demo.yml` from `pubspec.yaml`, or a generated `version.dart` written by a
      tiny script run in CI and locally via `flutter pub run`), with a sensible fallback.
- [ ] `deploy-web-demo.yml` passes/generates it so the live demo always shows the released version.
- [ ] A test asserts the badge equals the version in `pubspec.yaml`.
- [ ] Redeploy; the live demo shows 2.16.0 (or whatever is current).
