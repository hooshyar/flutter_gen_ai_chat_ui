---
id: TASK-023
title: 'Attachments and Voice Input demos reply with a canned "switch themes" message that does not fit the screen'
status: To Do
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
