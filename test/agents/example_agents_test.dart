import 'dart:async';

import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tests for the shipped example agents in
/// `lib/src/agents/example_agents.dart`. These agents are exported from the
/// package and consumers will read them as references (and often subclass
/// them), so their public behaviour is contract-level.
///
/// Note: each agent's `processRequest` includes a real `Future<void>.delayed`
/// of 500-1200ms. The tests use a longer per-test `timeout` and ordinary
/// `await` (no `fakeAsync`) so they exercise the production code path
/// unmodified.
void main() {
  AgentRequest _req(String query, {String id = 'r1'}) => AgentRequest(
        id: id,
        query: query,
        type: AgentRequestType.query,
        timestamp: DateTime.now(),
      );

  group('TextAnalysisAgent', () {
    late TextAnalysisAgent agent;

    setUp(() {
      agent = TextAnalysisAgent();
    });

    tearDown(() async {
      // Idempotent: dispose may have already been awaited by the test body.
      try {
        await agent.dispose();
      } on StateError {
        // Stream already closed — fine.
      }
    });

    test('exposes the documented id, name, and capabilities', () {
      expect(agent.id, 'text_analysis_001');
      expect(agent.name, 'Text Analysis Specialist');
      expect(agent.priority, AgentPriority.high);
      expect(agent.capabilities, contains('sentiment_analysis'));
      expect(agent.capabilities, contains('text_summarization'));
      expect(agent.capabilities, contains('grammar_check'));
    });

    test('canHandle: returns true for in-domain prompts', () {
      expect(agent.canHandle(_req('analyze this text')), isTrue);
      expect(agent.canHandle(_req('check sentiment of my message')), isTrue);
      expect(agent.canHandle(_req('please summarize this')), isTrue);
      expect(agent.canHandle(_req('run a sentiment analysis on it')), isTrue,
          reason:
              'matches the "sentiment_analysis" capability with underscores '
              'replaced by spaces');
    });

    test('canHandle: returns false for out-of-domain prompts', () {
      expect(agent.canHandle(_req('refactor my function please')), isFalse,
          reason: 'no analyze/text/sentiment/summarize keyword');
      expect(agent.canHandle(_req('what is the weather like')), isFalse);
      expect(agent.canHandle(_req('hello there')), isFalse);
    });

    test(
        'initialize + processRequest: happy path returns a non-error '
        'AgentResponse with analysis metadata', () async {
      await agent.initialize(const {});
      expect(agent.status, AgentStatus.idle);

      final response = await agent.processRequest(_req('analyze sentiment'));
      expect(response.type, AgentResponseType.finalAnswer);
      expect(response.agentId, agent.id);
      expect(response.requestId, 'r1');
      expect(response.confidence, greaterThanOrEqualTo(0.85));
      expect(response.confidence, lessThanOrEqualTo(1.0));
      // Agent-specific assertion: sentiment branch sets analysis_type metadata
      // and the content explicitly mentions "Sentiment Analysis".
      expect(response.metadata['analysis_type'], 'sentiment');
      expect(response.content, contains('Sentiment Analysis'));
      // Returned to idle after work.
      expect(agent.status, AgentStatus.idle);
    }, timeout: const Timeout(Duration(seconds: 5)));

    test(
        'processRequest: routes to summary branch when the query contains '
        '"summarize"', () async {
      await agent.initialize(const {});
      final response = await agent
          .processRequest(_req('please summarize this long paragraph for me'));
      expect(response.metadata['analysis_type'], 'summary');
      expect(response.content, contains('Summary'));
    }, timeout: const Timeout(Duration(seconds: 5)));

    test(
        'processRequest: routes to grammar branch when the query contains '
        '"grammar"', () async {
      await agent.initialize(const {});
      final response =
          await agent.processRequest(_req('check grammar in teh sentence'));
      expect(response.metadata['analysis_type'], 'grammar');
      expect(response.content, contains('Grammar Check'));
    }, timeout: const Timeout(Duration(seconds: 5)));

    test('dispose: closes state stream so no pending timers/subs leak',
        () async {
      // Subscribe so we can confirm the stream completes.
      final events = <AgentState>[];
      final completer = Completer<void>();
      final sub = agent.streamState().listen(
            events.add,
            onDone: completer.complete,
          );
      await agent.initialize(const {});

      await agent.dispose();
      // Subscription must complete normally now that the controller is closed.
      await completer.future.timeout(const Duration(seconds: 1));
      await sub.cancel();

      // At least the idle-after-initialize event should have arrived.
      expect(events, isNotEmpty);
      expect(events.first.agentId, agent.id);
    });
  });

  group('CodeAnalysisAgent', () {
    late CodeAnalysisAgent agent;

    setUp(() {
      agent = CodeAnalysisAgent();
    });

    tearDown(() async {
      try {
        await agent.dispose();
      } on StateError {
        // Already closed.
      }
    });

    test('exposes the documented id, name, and capabilities', () {
      expect(agent.id, 'code_analysis_001');
      expect(agent.name, 'Code Analysis Specialist');
      expect(agent.priority, AgentPriority.high);
      expect(agent.capabilities, contains('code_review'));
      expect(agent.capabilities, contains('bug_detection'));
      expect(agent.capabilities, contains('security_analysis'));
    });

    test('canHandle: recognises code-shaped prompts', () {
      expect(agent.canHandle(_req('review this code')), isTrue);
      expect(agent.canHandle(_req('debug the function please')), isTrue);
      expect(agent.canHandle(_req('optimize this loop')), isTrue);
      // Capability keyword variant.
      expect(agent.canHandle(_req('do a code review')), isTrue);
    });

    test('canHandle: returns false for non-code prompts', () {
      expect(agent.canHandle(_req('what is the capital of France')), isFalse);
      expect(agent.canHandle(_req('how do I cook pasta')), isFalse);
      expect(agent.canHandle(_req('summarize this paragraph')), isFalse,
          reason: 'no code/function/debug/optimize/review keyword');
    });

    test(
        'initialize + processRequest: happy path returns a non-error '
        'AgentResponse with code-analysis metadata', () async {
      await agent.initialize(const {});
      expect(agent.status, AgentStatus.idle);

      final response = await agent.processRequest(_req('review my code'));
      expect(response.type, AgentResponseType.finalAnswer);
      expect(response.agentId, agent.id);
      expect(response.confidence, closeTo(0.9, 1e-9));
      // Agent-specific assertion: code agent stamps analysis_type =
      // code_review and the content mentions "Code Analysis Results".
      expect(response.metadata['analysis_type'], 'code_review');
      expect(response.metadata['language'], 'multiple');
      expect(response.content, contains('Code Analysis Results'));
      expect(agent.status, AgentStatus.idle);
    }, timeout: const Timeout(Duration(seconds: 5)));

    test('dispose: closes state stream so no pending timers/subs leak',
        () async {
      final events = <AgentState>[];
      final completer = Completer<void>();
      final sub = agent.streamState().listen(
            events.add,
            onDone: completer.complete,
          );
      await agent.initialize(const {});

      await agent.dispose();
      await completer.future.timeout(const Duration(seconds: 1));
      await sub.cancel();
      expect(events, isNotEmpty);
    });
  });

  group('GeneralAssistantAgent', () {
    late GeneralAssistantAgent agent;

    setUp(() {
      agent = GeneralAssistantAgent();
    });

    tearDown(() async {
      try {
        await agent.dispose();
      } on StateError {
        // Already closed.
      }
    });

    test('exposes the documented id, name, and capabilities', () {
      expect(agent.id, 'general_assistant_001');
      expect(agent.name, 'General Assistant');
      expect(agent.priority, AgentPriority.normal);
      expect(agent.capabilities, contains('general_questions'));
      expect(agent.capabilities, contains('delegation'));
    });

    test('canHandle: is a fallback that always returns true', () {
      expect(agent.canHandle(_req('anything')), isTrue);
      expect(agent.canHandle(_req('')), isTrue);
      expect(agent.canHandle(_req('weather forecast tomorrow')), isTrue);
    });

    test(
        'processRequest: produces a delegation response when the query '
        'matches the text-analyst delegation rules', () async {
      await agent.initialize(const {});
      final response = await agent
          .processRequest(_req('please analyze the sentiment of this text'));
      expect(response.type, AgentResponseType.delegation);
      expect(response.metadata['delegate_to'], 'text_analysis_001');
      expect(response.metadata['delegated_query'], isNotNull);
    }, timeout: const Timeout(Duration(seconds: 5)));

    test(
        'processRequest: produces a delegation response when the query '
        'matches the code-analyst delegation rules', () async {
      await agent.initialize(const {});
      final response =
          await agent.processRequest(_req('please debug this code'));
      expect(response.type, AgentResponseType.delegation);
      expect(response.metadata['delegate_to'], 'code_analysis_001');
    }, timeout: const Timeout(Duration(seconds: 5)));

    test(
        'processRequest: falls through to a general answer for unmatched '
        'queries (no delegation)', () async {
      await agent.initialize(const {});
      // No code/function/debug/optimize, no analyze+text combo, no sentiment,
      // no summarize, no grammar — should not delegate.
      final response = await agent.processRequest(_req('hello there'));
      expect(response.type, AgentResponseType.finalAnswer);
      expect(response.metadata.containsKey('delegate_to'), isFalse);
      expect(response.content, contains('general assistant'));
      expect(response.confidence, closeTo(0.75, 1e-9));
    }, timeout: const Timeout(Duration(seconds: 5)));

    test(
        'orchestrator integration: register + processRequest end-to-end '
        'returns a non-error response', () async {
      final orch = AgentOrchestrator();
      await orch.registerAgent(agent);

      final response = await orch.processRequest(_req('hello there'));
      expect(response.type, isNot(AgentResponseType.error));
      expect(response.agentId, agent.id);

      orch.dispose();
    }, timeout: const Timeout(Duration(seconds: 5)));

    test('dispose: closes state stream so no pending timers/subs leak',
        () async {
      final events = <AgentState>[];
      final completer = Completer<void>();
      final sub = agent.streamState().listen(
            events.add,
            onDone: completer.complete,
          );
      await agent.initialize(const {});

      await agent.dispose();
      await completer.future.timeout(const Duration(seconds: 1));
      await sub.cancel();
      expect(events, isNotEmpty);
    });
  });

  group('All three agents integrated with AgentOrchestrator', () {
    test(
        'orchestrator routes a text-analysis query to TextAnalysisAgent '
        'when both text and general agents are registered', () async {
      final textAgent = TextAnalysisAgent();
      final generalAgent = GeneralAssistantAgent();
      final orch = AgentOrchestrator();
      await orch.registerAgent(textAgent);
      await orch.registerAgent(generalAgent);

      final response = await orch.processRequest(_req('analyze the sentiment'));
      // The text agent matches its keyword filter; the general agent always
      // returns true. Orchestrator's scorer must prefer the more specific
      // match. If routing accidentally goes to general the response would
      // come back as a delegation — assert it doesn't.
      expect(response.type, isNot(AgentResponseType.delegation),
          reason: 'A direct match should not require delegation.');
      expect(response.agentId, textAgent.id,
          reason: 'Capability-matching agent should win over the fallback.');

      orch.dispose();
    }, timeout: const Timeout(Duration(seconds: 5)));

    test(
        'orchestrator routes a non-domain query to GeneralAssistantAgent '
        'when only general is a match', () async {
      final textAgent = TextAnalysisAgent();
      final codeAgent = CodeAnalysisAgent();
      final generalAgent = GeneralAssistantAgent();
      final orch = AgentOrchestrator();
      await orch.registerAgent(textAgent);
      await orch.registerAgent(codeAgent);
      await orch.registerAgent(generalAgent);

      final response = await orch.processRequest(_req('hello, how are you'));
      // Only the general agent's canHandle returns true here.
      expect(response.agentId, generalAgent.id);
      expect(response.type, AgentResponseType.finalAnswer);

      orch.dispose();
    }, timeout: const Timeout(Duration(seconds: 5)));
  });
}
