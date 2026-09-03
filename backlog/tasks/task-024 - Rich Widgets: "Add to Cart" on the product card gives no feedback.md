---
id: TASK-024
title: 'Rich Widgets: "Add to Cart" on the product card gives no feedback'
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

Repro: Rich Widgets -> "Show me a product" -> click Add to Cart. Nothing happens (no toast, state change or message), so it reads as a dead button. Either wire a visible confirmation (snackbar + cart badge or a follow-up bot message) or remove the button from the demo.

## Done (2026-09-03)

Went with the snackbar option (simplest, no extra state to manage). `_buildProductCard`'s
`FilledButton.onPressed` in `example/lib/examples/rich_widgets_chat.dart` now shows
`ScaffoldMessenger.of(context).showSnackBar(...)` with "{product name} added to cart 🛒" —
`context` was already available in that builder method.

Verified live on the deployed demo before fixing (tapping did nothing) and captured before/after
screenshots. Added `example/test/rich_widgets_chat_test.dart` (new file — this example had no test
coverage at all before): taps "Show me a product" then "Add to Cart" and asserts a `SnackBar`
containing "added to cart" appears where none did before.

`dart analyze --fatal-infos` clean (root + example), `flutter test` green (426 root, 8 example).
Redeployed via the normal `deploy-web-demo.yml` CI trigger on push to `main`; verified live.

**Status:** DONE.
