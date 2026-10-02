---
name: pana-downgrade-lower-bounds
description: CI here has no `pub downgrade` check, so code using an API newer than a dep's declared lower bound passes CI but costs 20 pana points (and breaks consumers on older locks)
metadata:
  type: project
---

ci.yml never runs `flutter pub downgrade` + analyze; only pana does ("Compatible with dependency constraint lower bounds", 20 pts). The 2.20.0 gate (2026-10-02) found `MarkdownStyleSheet.tableHeadCellsDecoration` (added in flutter_markdown_plus 1.0.6) used while pubspec still said `^1.0.3`: CI fully green, pana 140/160.

**Why:** the redesign branch used new dep APIs without raising the constraint floors; nothing mechanical caught it.
**How to apply:** on every pre-publish gate, run pana on a `git archive HEAD` copy (see [[flutter-tooling-churn-and-pana]]), or fast path: archive copy, delete example/, `flutter pub downgrade && dart analyze lib`. Any error there is blocking. Confirmed reliable 2026-10-02: after raising the floor to ^1.0.12 the fast path was clean and full pana gave 160/160 (lower bounds 20/20) on the same commit. Related: [[pr-ci-runs-merge-ref]].
