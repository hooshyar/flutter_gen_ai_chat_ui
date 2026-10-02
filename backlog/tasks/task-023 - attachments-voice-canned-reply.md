---
id: TASK-023
title: 'Attachments and Voice Input demos reply with a canned "switch themes" message that does not fit the screen'
status: Done
priority: low
labels:
  - example
  - web-demo
  - qa-2026-09-03
created_date: '2026-09-03'
---

## Description

Found by the 2026-09-03 visual QA pass of the live demo https://hooshyar.github.io/flutter_gen_ai_chat_ui/ (v2.16.0). Fix, add a test where meaningful, redeploy the demo, verify live.

Repro: Attachments -> tap paperclip; Voice Input -> tap mic then send. Both bot replies say "Got it — I can see quarterly-report.pdf. Nice message! Try switching between the Ocean, Sunset and Default themes above..." — a shared fallback reused across demos; there are no theme buttons on these screens. Give each demo a context-appropriate reply.

## Done (2026-09-03)

Added `ResponseStyle.assistant` to `example/lib/services/mock_ai_service.dart` — a new response
style distinct from `.conversational` (which is intentionally theme-focused for `themed_chat.dart`
and should stay that way). `_assistantResponse` handles: `.pdf`/`report` (attachments demo),
`weather`/`fun fact`+`flutter`/`summarize` (the voice demo's three rotating simulated phrases), a
`hello`/short-query greeting, and a generic fallback — none of it mentions themes. Switched
`attachments_chat.dart` and `voice_chat.dart` to the new style.

Verified live on the deployed demo before fixing (both showed the exact reported theme-pitch text)
and captured before/after screenshots. Added regression tests: `example/test/attachments_chat_test.dart`
and `example/test/voice_chat_test.dart` each gained a test asserting the reply does NOT contain
"switching between"/"themes above" and DOES contain the expected context-appropriate text.

`dart analyze --fatal-infos` clean (root + example), `flutter test` green (426 root, 8 example).
Redeployed via the normal `deploy-web-demo.yml` CI trigger on push to `main`; verified live.

**Status:** DONE.
