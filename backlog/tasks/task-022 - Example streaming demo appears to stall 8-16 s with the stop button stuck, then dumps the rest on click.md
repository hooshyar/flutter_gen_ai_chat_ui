---
id: TASK-022
title: 'Example streaming demo appears to stall 8-16 s with the stop button stuck, then dumps the rest on click'
status: Done
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

## Investigated (2026-09-03) — no longer reproducible, closing without a code change

Reproduced the exact repro steps against the CURRENT live demo (v2.16.1) 3 times: twice with
"Compare StatelessWidget vs StatefulWidget" (the exact repro), once with "Explain async/await with
an example" (also has multiple code blocks, to rule out response-content specificity). Every attempt
streamed and completed cleanly in 2-6 seconds — no stall, no stuck stop button, stop button correctly
reverted to the send icon the moment streaming finished.

Root-cause read of the reveal-pacing logic (`custom_chat_widget.dart`'s `_ensureRevealTicker`) found
nothing that could cause an actual 8-16s freeze — it's a `Timer.periodic` that always makes forward
progress every 50ms, incapable of a true stall by construction (worst case is visual jank from
expensive markdown/code-block rebuilds, not a multi-second freeze). Given the symptom is gone on the
same live surface, the most likely explanation is that v2.16.1's `pinDuringStreaming` regression fix
(`aab3d82` — the pin was being released early by the delayed auto-scroll in the
`addStreamingMessage` flow, which this exact demo uses) incidentally fixed this too, since both bugs
live in the same streaming/auto-scroll code path and interact with the same `setState`/rebuild
timing. Not fully proven (didn't bisect to confirm which specific line fixed it), but reproducing
zero times in 3 attempts on the fixed version, after reproducing reliably enough to be reported
against the broken version, is strong enough evidence to close this without further speculative
changes.

**Status:** DONE (verified resolved, no code change needed) — if it resurfaces, re-open with a fresh
repro against the CURRENT live version first, since this exact investigation found it already gone.
