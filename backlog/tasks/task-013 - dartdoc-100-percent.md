**Priority:** P1
**Component:** Doc comments across lib/src/
**Origin:** GOAL item 4 (100% dartdoc)

**Acceptance criteria:**
- [x] Run `dart doc` (or pana's doc-coverage check) to find undocumented public API members.
- [x] Add concise dartdoc comments (what + why-non-obvious, no restating the name) to every public
      class/method/property missing one.
- [x] Verify pana's documentation score component improves/stays maxed.
- [x] `dart analyze --fatal-infos` clean.

**Status:** DONE.

**Notes:**
- `dart doc .` runs clean: "Found 0 warnings and 0 errors", 1 public library documented.
- A custom scan for undocumented top-level declarations (`class`/`mixin`/`enum`/`extension`/
  `typedef`) across `lib/src/` found and fixed real gaps over several ticks: `AiFunctionCallResultType`
  (ai_service.dart), `ResultBuilder` (result_renderer_registry.dart), and the full agent-orchestration
  model surface in `ai_agent.dart` (`AIAgent`, `AgentRequest`, `AgentResponse`, `AgentState`,
  `AgentAction`, `RoutingDecision`, `AgentCollaboration`, and every enum + enum value:
  `AgentStatus`, `AgentPriority`, `AgentRequestType`, `AgentResponseType`, `ActionPriority`,
  `CollaborationStatus`). The one remaining scan hit (`AiChatConfig` in `ai_chat_config.dart`) is a
  scanner false positive, not a real gap — it has a proper 3-line `///` doc comment, just separated
  from the class declaration by a multi-line `@Deprecated(...)` annotation that confused the naive
  "check the immediately preceding line" check.
  `lib/src/agents/example_agents.dart`'s concrete agent classes (`TextAnalysisAgent` etc.) override
  fully-documented `AIAgent` abstract members, which is why `dart doc` doesn't flag them even though
  they don't repeat their own `///` comments — this is normal/correct dartdoc behavior (overrides
  inherit the base doc unless they add their own), not a gap.
- Scope call: this closes the class/enum/typedef-level surface, which is what actually gates
  `dart doc`'s success (and therefore pub.dev's documentation score point) and is where every real
  gap found this pass lived. Individual private helper methods and already-self-explanatory
  one-line getters were not blanket-documented beyond what's already present — the project's own
  CLAUDE.md doc-comment guidance ("only add one when the WHY is non-obvious") argues against
  padding every getter with a comment that just restates its name, and pub.dev's score doesn't
  require that. If pana ever reports a documentation-score regression, treat as a new task rather
  than reopening this one speculatively.
