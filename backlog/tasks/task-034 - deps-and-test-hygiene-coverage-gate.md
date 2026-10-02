---
id: TASK-034
title: 'Dependency + test hygiene: raise lower bounds, replace network_image_mock, cover untested exported files, add a CI coverage gate'
status: To Do
priority: medium
labels:
  - P1
  - deps
  - tests
  - improvement-plan-2026-09
created_date: '2026-09-24'
---

## Description

Findings from 2026-09-24 (see docs/IMPROVEMENT-PLAN-2026-09.md §1.2 and §1.4):

- **Deps.** `clock` is locked at 1.1.2, but 1.1.3 is out. Lower bounds lag the latest stable
  (`flutter_markdown_plus ^1.0.3` vs 1.0.12, `url_launcher ^6.3.1` vs 6.3.2, `flutter_math_fork
  ^0.7.2` vs 0.7.4). The dev dep `network_image_mock` is unmaintained (last release 2022-06). The
  example uses `flutter_lints ^3.0.1` while the latest is 6.0.0. `speech_to_text` 7.5.0 is out
  (dev-only; it needs Flutter >=3.44). There are 19 stale locked transitives.
- **Tests.** A full `flutter test --coverage` run could not finish on 2026-09-24. It hung at
  "loading" twice while 3 other `flutter test` jobs ran on the machine, so no lcov number exists
  yet. A static proxy found **27 `lib/src` files (~6.9k lines) that no test references by class
  name**. Among the exported ones: `citation_chip.dart` (593), `adaptive_ui_components.dart` (554),
  `action_result_widget.dart` (520), `rich_message_content.dart` (460, which holds the dead
  `enableSyntaxHighlighting` knob), `ai_action_provider.dart` (446, the human-in-the-loop surface
  the README markets), `headless_chat_controller.dart` (214), `ai_service.dart` (339), and
  `models/chat/citation.dart` (258).
- **Duplication.** `glassmorphic_container.dart` exists in both `utils/` and `widgets/`, and both
  are exported.

## Acceptance Criteria
- [ ] Raise the dependency lower bounds to the current latest stable where the Flutter 3.35 floor
      still resolves. Replace `network_image_mock`, for example with `mocktail_image_network`
      (check that its latest stable is maintained) or an in-repo `HttpOverrides` helper. Bump
      example `flutter_lints` to ^6.0.0 and fix any new lints. Run `flutter pub upgrade` in the
      root and example. The sdk-matrix floor leg stays green.
- [ ] Get a real coverage baseline on an uncontended machine or in CI. Add `--coverage` to the CI
      test job, upload `lcov.info` as an artifact, and add a summary step that prints the line %.
- [ ] Add tests for the exported untested files above. Priority: `ai_action_provider` (HITL
      confirm/deny), `citation_chip` + `citation`, `headless_chat_controller`,
      `rich_message_content`, and `action_result_widget`.
- [ ] Add a no-regression coverage floor in CI: baseline minus 1%.
- [ ] Deduplicate the glassmorphic container. Keep one export and `@Deprecated` the other.
- [ ] pana 160/160. `flutter analyze` clean.
