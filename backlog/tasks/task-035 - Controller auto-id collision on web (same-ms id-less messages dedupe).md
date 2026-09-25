---
id: TASK-035
title: Controller auto-id collision on web (same-ms id-less messages dedupe)
status: To Do
priority: medium
labels:
  - bug
  - controller
  - web
created_date: '2026-09-25'
---

## Description

`ChatMessagesController._getMessageId` derives an id for a message with no explicit `id` from
`'${message.user.id}_${message.createdAt.millisecondsSinceEpoch}'`. On web, `DateTime.now()` is
backed by JS `Date.now()` and only has millisecond resolution (unlike the VM's microsecond-resolution
clock), so two id-less messages from the same user added a few statements apart in the same
synchronous handler — e.g. a tool-call JSON block immediately followed by a `ChatMessage.rich`
result card — can reliably land on the exact same generated id there, even though this almost
never reproduces in a plain `flutter test` run on the VM.

When that happens, the second `addMessage` call is treated as a duplicate of the first (same
generated id → same cache slot) and is silently dropped, even though the two messages have
completely different content. Concretely this dropped the result card after `/calculate` and
`/weather` in `example/lib/examples/actions_chat.dart` on the deployed web demo.

**Current workaround (shipped, see CHANGELOG "Known limitation" and the README note near Quick
Start):** callers that add several id-less messages for the same user in quick succession must
give each one an explicit `id` — `ChatMessage(customProperties: {'id': ...})` or
`ChatMessage.rich(id: ...)`. `example/lib/examples/actions_chat.dart` now does this with a
`tool-call-<n>` / `tool-result-<n>` counter.

## Why round 10/11's in-controller fixes were reverted

Two earlier attempts tried to fix this inside `ChatMessagesController` itself, and both caused
regressions serious enough that this round reverted the controller back to its pre-fix state
(commit `7586895`) rather than ship either:

1. **Stored-copy mutation.** One approach mutated/replaced the stored message's id in place when a
   collision with a genuinely different message was detected (suffixing the generated id, e.g.
   `..._1`). This corrupted identity for anything that had already captured or compared against the
   original generated id before the mutation happened (e.g. a caller reading the id back
   immediately after `addMessage`, or `updateMessage`/streaming code paths that recompute
   `_getMessageId` from the original id-less message object rather than reading the id the message
   was actually stored under).
2. **Suffixed id unreachable through the public API.** Even once the collision was disambiguated
   internally, nothing surfaced the actual suffixed id back to the caller — `addMessage` returns
   `void` — so a caller had no reliable way to address the second message afterwards (for
   `updateMessage`, `pinMessage`, `scrollToMessage`, etc.) short of re-deriving the same suffix
   logic themselves. `addStreamingMessage` in particular recomputed the id from the original
   (id-less) message right after calling `addMessage(message)`, which — on a collision — silently
   produced the EARLIER message's unsuffixed id instead of the new message's actual stored id, so
   the stream/pin/update all targeted the wrong message.

Both rounds' regression tests were reverted along with the controller change; see
`test/chat_messages_controller_test.dart` and `test/streaming_message_test.dart` at `7586895` for
the pre-fix baseline the suite is back on.

## Candidate designs for a real fix

- **Assign a unique id at `ChatMessage` construction** (e.g. an internal monotonic counter or a
  UUID) rather than deriving one lazily from user id + timestamp in the controller. This removes
  the timestamp-collision class of bug entirely, but is a larger, more visible API change (every
  `ChatMessage` would carry a real id from creation, not just an internal cache key) and needs a
  compatibility plan for existing code that assumes the current `user_timestamp` id shape.
- **Monotonic counter plus an id-returning `addMessage`.** Keep timestamp-derived ids as the
  default but disambiguate collisions with a process-local monotonic counter instead of a suffix
  scheme, and change `addMessage` (and `addStreamingMessage`) to return the id the message was
  actually stored under, so callers (and internal code like the streaming path) never have to
  re-derive it. This is closer to what rounds 10/11 attempted, but fixes the specific bug that sank
  them: nothing downstream should ever recompute an id from the original message object after
  `addMessage` — it should read back the id `addMessage` returns.

Either design needs the same regression coverage rounds 10/11 wrote (same-millisecond collision
with distinct messages must not drop one; an identical re-added id-less message must still dedupe;
streaming/update calls after a collision must target the correct message) plus new coverage for
whatever identity/return-value contract the fix introduces.
