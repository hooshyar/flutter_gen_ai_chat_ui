**Priority:** P3
**Component:** example/ (or sibling packages)
**Origin:** Issue #41 Phase 4

**Acceptance criteria:**
- [ ] Add example snippets/screens wiring OpenAI, Anthropic, Gemini, and Ollama streaming
      responses into `ChatMessagesController` in ~10 lines each.
- [ ] Keep heavy HTTP/SDK deps out of the core package — examples only, or clearly separate
      sibling-package proposal documented in docs/AWARD-PLAN.md if a real package is warranted.
- [ ] Document in README "Cookbook" or a new "Integrations" doc section.
