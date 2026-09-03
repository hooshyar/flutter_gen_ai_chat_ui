---
id: TASK-022
title: 'Example streaming demo appears to stall 8-16 s with the stop button stuck, then dumps the rest on click'
status: To Do
priority: medium
labels:
  - example
  - web-demo
  - qa-2026-09-03
created_date: '2026-09-03'
---

## Description

Found by the 2026-09-03 visual QA pass of the live demo https://hooshyar.github.io/flutter_gen_ai_chat_ui/ (v2.16.0). Fix, add a test where meaningful, redeploy the demo, verify live.

Repro: Streaming + Markdown, send "Compare StatelessWidget vs StatefulWidget"; after the StatefulWidget heading appears, content and timestamp freeze for 16+ s while the input shows the stop (square) state; clicking stop reveals the rest fully formed. A real user reads this as a hang. Investigate the ExampleAiService stream timing plus the widget repaint during long code blocks; make the demo stream smoothly or show a typing indicator; make sure the stop button reflects real state.
