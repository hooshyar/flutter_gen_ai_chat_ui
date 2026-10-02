---
name: flutter-tooling-churn-and-pana
description: Flutter 3.47.x pub get auto-edits analysis_options.yaml (dirties tree, fake publish dry-run warning); pana's first local run can time out on pub get and report bogus 70/160
metadata:
  type: project
---

Flutter 3.47.5 `flutter pub get` (and anything that triggers it: `flutter test`, `dart analyze` in a Flutter package) prints "Upgrading analysis_options.yaml to exclude build and platform directories" and rewrites root + example `analysis_options.yaml` (and bumps example/pubspec.lock path version). That dirty tree alone makes `dart pub publish --dry-run` report "1 warning" (modified checked-in files).

**Why:** seen 2026-10-02 verifying flutter_streaming_text_markdown 1.11.0; the warning vanished after `git checkout --` of those files.
**How to apply:** before judging a dry-run warning count, revert that churn and re-run; always revert it at the end of a read-only verify. Run pana on a `git archive HEAD` copy; if the log shows `Exceeded timeout of 0:02:00` on pub get/outdated, the score (e.g. 70/160) is bogus. Re-run once the pub cache is warm (second run gave the real 160/160).
