---
id: TASK-024
title: 'Rich Widgets: "Add to Cart" on the product card gives no feedback'
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

Repro: Rich Widgets -> "Show me a product" -> click Add to Cart. Nothing happens (no toast, state change or message), so it reads as a dead button. Either wire a visible confirmation (snackbar + cart badge or a follow-up bot message) or remove the button from the demo.
