**Priority:** P3
**Component:** example/ (or sibling packages)
**Origin:** Issue #41 Phase 4

**Acceptance criteria:**
- [x] Add example snippets/screens wiring OpenAI, Anthropic, Gemini, and Ollama streaming
      responses into `ChatMessagesController` in ~10 lines each.
- [x] Keep heavy HTTP/SDK deps out of the core package — examples only, or clearly separate
      sibling-package proposal documented in docs/AWARD-PLAN.md if a real package is warranted.
- [x] Document in README "Cookbook" or a new "Integrations" doc section.

## Done (2026-09-03)

Added a new "Wire up a real LLM provider" section to `doc/cookbook/README.md` with 4 snippets
(OpenAI Chat Completions, Anthropic Messages API, Google Gemini `streamGenerateContent`, Ollama
`/api/chat`), each showing the real SSE/NDJSON parsing loop feeding `controller.updateMessage(...)`
via `package:http` directly — no vendor SDK dependency added anywhere, matching the "keep heavy deps
out of core" requirement. Verified each provider's current streaming wire format via web search/fetch
before writing (not from training-data memory, per the "never trust memory for what's current" repo
policy) rather than assuming a remembered API shape:
- OpenAI: SSE `data: {...}` lines, `choices[0].delta.content`, terminated by `data: [DONE]`.
- Anthropic: SSE events, filtered to `type == "content_block_delta"`, text in `delta.text`.
- Gemini: confirmed `streamGenerateContent?alt=sse` (the long-standing REST endpoint) is still
  current via two independent corroborating sources (`googleai_dart` and `flutter_gemini` package
  docs), after an initial web search surfaced an unfamiliar "interactions" endpoint that couldn't be
  independently corroborated — didn't take that single result at face value.
- Ollama: NDJSON (not SSE) lines from `/api/chat`, `message.content` per line, final line has
  `"done": true`. Long-stable local API, not independently re-verified beyond existing knowledge.

Model names are illustrative with an inline comment pointing at each vendor's current-models page,
deliberately not hardcoded as if permanently current — model names rotate faster than this doc will
be revisited, and the technically load-bearing part of each snippet is the streaming/parsing shape,
not the exact model string. Linked from README's "Works Great With" section. No test coverage added
(matches the existing cookbook's convention — illustrative snippets, not compiled/tested code; no
`http` dependency was added to `example/` or the root package). `analyze --fatal-infos` clean,
`dart format` clean, 436/436 tests unaffected (no .dart files touched), doc-drift checker unaffected
(only scans README.md/AGENTS.md, not doc/cookbook/).

**Status:** DONE.
