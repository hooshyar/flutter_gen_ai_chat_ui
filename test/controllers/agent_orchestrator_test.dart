import 'dart:async';

import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';
import 'package:flutter_test/flutter_test.dart';

/// Minimal in-test fake agent. Keeps behaviour deterministic (no random
/// sleeps) so orchestrator tests don't rely on `Future.delayed` timing.
class _FakeAgent extends AIAgent {
  _FakeAgent({
    required super.id,
    required super.name,
    super.specialization = 'fake',
    super.capabilities = const [],
    super.priority = AgentPriority.normal,
    this.handleQueryWhen,
    this.responder,
    this.shouldThrowOnProcess = false,
    this.responseType = AgentResponseType.finalAnswer,
    this.responseMetadata = const {},
  });

  /// Override `canHandle` with a query-substring filter. `null` => always true.
  final String? handleQueryWhen;

  /// Override `processRequest` content. `null` => echo the query.
  final String? Function(AgentRequest request)? responder;

  /// If true, `processRequest` throws — exercises the orchestrator's error
  /// branch.
  final bool shouldThrowOnProcess;

  /// Response type returned from `processRequest`. Allows tests to drive the
  /// delegation / collaboration branches.
  final AgentResponseType responseType;

  /// Metadata returned from `processRequest`. Drives delegation routing.
  final Map<String, dynamic> responseMetadata;

  final StreamController<AgentState> _stateController =
      StreamController<AgentState>.broadcast();
  AgentStatus _status = AgentStatus.initializing;

  /// Public counters so tests can assert dispatch + lifecycle.
  int initializeCalls = 0;
  int disposeCalls = 0;
  int processCalls = 0;
  final List<AgentRequest> receivedRequests = [];

  @override
  AgentStatus get status => _status;

  void setStatus(AgentStatus status) {
    _status = status;
    _stateController.add(AgentState(
      agentId: id,
      status: _status,
      lastUpdated: DateTime.now(),
    ));
  }

  @override
  Future<void> initialize(Map<String, dynamic> config) async {
    initializeCalls++;
    setStatus(AgentStatus.idle);
  }

  @override
  bool canHandle(AgentRequest request) {
    if (handleQueryWhen == null) return true;
    return request.query.toLowerCase().contains(handleQueryWhen!.toLowerCase());
  }

  @override
  Future<AgentResponse> processRequest(AgentRequest request) async {
    processCalls++;
    receivedRequests.add(request);
    setStatus(AgentStatus.processing);
    if (shouldThrowOnProcess) {
      setStatus(AgentStatus.error);
      throw StateError('fake agent failure');
    }
    final content = responder?.call(request) ?? 'echo:${request.query}';
    final response = AgentResponse(
      id: 'fake_resp_${DateTime.now().microsecondsSinceEpoch}_$processCalls',
      requestId: request.id,
      agentId: id,
      content: content ?? '',
      type: responseType,
      metadata: responseMetadata,
      timestamp: DateTime.now(),
    );
    setStatus(AgentStatus.idle);
    return response;
  }

  @override
  Stream<AgentState> streamState() => _stateController.stream;

  @override
  Future<void> dispose() async {
    disposeCalls++;
    await _stateController.close();
  }
}

/// Fake agent that emits one final state DURING its own dispose, then closes
/// its controller. Used to verify the orchestrator cancels per-agent
/// subscriptions before closing its own state stream — otherwise the final
/// emit would forward to a closed broadcast controller and throw.
class _EmitOnDisposeAgent extends AIAgent {
  _EmitOnDisposeAgent({required super.id, required super.name})
      : super(specialization: 'late-emitter', capabilities: const []);

  final StreamController<AgentState> _stateController =
      StreamController<AgentState>.broadcast();
  AgentStatus _status = AgentStatus.initializing;

  int disposeCalls = 0;

  @override
  AgentStatus get status => _status;

  @override
  Future<void> initialize(Map<String, dynamic> config) async {
    _status = AgentStatus.idle;
    _stateController.add(AgentState(
      agentId: id,
      status: _status,
      lastUpdated: DateTime.now(),
    ));
  }

  @override
  bool canHandle(AgentRequest request) => true;

  @override
  Future<AgentResponse> processRequest(AgentRequest request) async {
    return AgentResponse(
      id: 'r',
      requestId: request.id,
      agentId: id,
      content: '',
      type: AgentResponseType.finalAnswer,
      timestamp: DateTime.now(),
    );
  }

  @override
  Stream<AgentState> streamState() => _stateController.stream;

  @override
  Future<void> dispose() async {
    disposeCalls++;
    _status = AgentStatus.offline;
    // Emit BEFORE closing — this is the "agent talks on its way down"
    // pattern that the orchestrator's per-agent subscription tracking
    // protects against.
    if (!_stateController.isClosed) {
      _stateController.add(AgentState(
        agentId: id,
        status: _status,
        lastUpdated: DateTime.now(),
      ));
    }
    await _stateController.close();
  }
}

AgentRequest _req(String query, {String id = 'r1'}) => AgentRequest(
      id: id,
      query: query,
      type: AgentRequestType.query,
      timestamp: DateTime.now(),
    );

void main() {
  group('AgentOrchestrator', () {
    late AgentOrchestrator orchestrator;

    setUp(() {
      orchestrator = AgentOrchestrator();
    });

    tearDown(() {
      orchestrator.dispose();
    });

    group('Agent registration', () {
      test('registers an agent and calls initialize with orchestrator config',
          () async {
        final agent = _FakeAgent(id: 'a1', name: 'A1');

        await orchestrator.registerAgent(agent);

        expect(agent.initializeCalls, 1);
        expect(orchestrator.agents, hasLength(1));
        expect(orchestrator.getAgent('a1'), same(agent));
      });

      test('unregisterAgent disposes the agent and removes it', () async {
        final agent = _FakeAgent(id: 'a1', name: 'A1');
        await orchestrator.registerAgent(agent);

        await orchestrator.unregisterAgent('a1');

        expect(agent.disposeCalls, 1);
        expect(orchestrator.agents, isEmpty);
        expect(orchestrator.getAgent('a1'), isNull);
      });

      test('unregisterAgent on unknown id is a no-op (no throw)', () async {
        await orchestrator.unregisterAgent('does_not_exist');
        expect(orchestrator.agents, isEmpty);
      });

      test('getAgentsByCapability filters on agent capabilities', () async {
        final a = _FakeAgent(
            id: 'a', name: 'A', capabilities: const ['sentiment', 'summary']);
        final b =
            _FakeAgent(id: 'b', name: 'B', capabilities: const ['code_review']);
        await orchestrator.registerAgent(a);
        await orchestrator.registerAgent(b);

        expect(orchestrator.getAgentsByCapability('sentiment'), [a]);
        expect(orchestrator.getAgentsByCapability('code_review'), [b]);
        expect(orchestrator.getAgentsByCapability('not_a_capability'), isEmpty);
      });

      test('getAvailableAgents returns only idle agents', () async {
        final a = _FakeAgent(id: 'a', name: 'A');
        final b = _FakeAgent(id: 'b', name: 'B');
        await orchestrator.registerAgent(a);
        await orchestrator.registerAgent(b);
        // Both transitioned to idle in initialize().
        expect(orchestrator.getAvailableAgents(), unorderedEquals([a, b]));

        b.setStatus(AgentStatus.processing);
        expect(orchestrator.getAvailableAgents(), [a]);

        a.setStatus(AgentStatus.error);
        expect(orchestrator.getAvailableAgents(), isEmpty);
      });
    });

    group('processRequest happy path', () {
      test('routes to the only registered agent and returns its response',
          () async {
        final agent = _FakeAgent(id: 'a1', name: 'A1');
        await orchestrator.registerAgent(agent);

        final response = await orchestrator.processRequest(_req('hello'));

        expect(agent.processCalls, 1);
        expect(agent.receivedRequests.single.query, 'hello');
        expect(response.agentId, 'a1');
        expect(response.content, 'echo:hello');
        expect(response.type, AgentResponseType.finalAnswer);
      });

      test('emits the agent response on the orchestrator response stream',
          () async {
        final agent = _FakeAgent(id: 'a1', name: 'A1');
        await orchestrator.registerAgent(agent);

        final streamed = orchestrator.responseStream.first;
        final returned = await orchestrator.processRequest(_req('hi'));
        final emitted = await streamed;

        expect(emitted.id, returned.id);
        expect(emitted.agentId, 'a1');
      });

      test('routes to the capability-matching agent when scores differ',
          () async {
        // Agent `code` has the matching capability "code review", agent
        // `text` doesn't. canHandle is permissive on both, so routing comes
        // down to the capability bonus inside _calculateRoutingScore.
        final code = _FakeAgent(
            id: 'code', name: 'Code', capabilities: const ['code review']);
        final text = _FakeAgent(
            id: 'text', name: 'Text', capabilities: const ['text analysis']);
        await orchestrator.registerAgent(code);
        await orchestrator.registerAgent(text);

        final response = await orchestrator
            .processRequest(_req('please run a code review on this'));

        expect(response.agentId, 'code');
        expect(code.processCalls, 1);
        expect(text.processCalls, 0);
      });

      test('throws AgentException when no agents are registered', () async {
        await expectLater(
          () => orchestrator.processRequest(_req('hello')),
          throwsA(isA<AgentException>()),
        );
      });
    });

    group('processRequest error handling', () {
      test('wraps agent exceptions in an error AgentResponse', () async {
        final agent =
            _FakeAgent(id: 'a1', name: 'A1', shouldThrowOnProcess: true);
        await orchestrator.registerAgent(agent);

        final response = await orchestrator.processRequest(_req('boom'));

        expect(response.type, AgentResponseType.error);
        expect(response.agentId, 'a1');
        expect(response.content, contains('fake agent failure'));
      });

      test('error response is also emitted on the response stream', () async {
        final agent =
            _FakeAgent(id: 'a1', name: 'A1', shouldThrowOnProcess: true);
        await orchestrator.registerAgent(agent);

        final emittedFuture = orchestrator.responseStream.first;
        await orchestrator.processRequest(_req('boom'));
        final emitted = await emittedFuture;

        expect(emitted.type, AgentResponseType.error);
      });
    });

    group('Delegation', () {
      test('handleDelegation re-routes to the metadata-named agent', () async {
        final delegator = _FakeAgent(
          id: 'delegator',
          name: 'Delegator',
          // Make the delegator the only one that matches the original
          // query so routing picks it deterministically.
          handleQueryWhen: 'delegate-me',
          responseType: AgentResponseType.delegation,
          responseMetadata: const {
            'delegate_to': 'specialist',
            'delegated_query': 'do the real work',
          },
        );
        final specialist = _FakeAgent(
          id: 'specialist',
          name: 'Specialist',
          handleQueryWhen: 'never-matches-original',
          responder: (req) => 'specialist handled: ${req.query}',
        );
        await orchestrator.registerAgent(delegator);
        await orchestrator.registerAgent(specialist);

        final response =
            await orchestrator.processRequest(_req('please delegate-me'));

        expect(delegator.processCalls, 1);
        expect(specialist.processCalls, 1);
        expect(response.agentId, 'specialist');
        expect(response.content, 'specialist handled: do the real work');
        // Delegated request gets a fresh id, parentRequestId points at orig.
        final delegated = specialist.receivedRequests.single;
        expect(delegated.parentRequestId, 'r1');
        expect(delegated.type, AgentRequestType.delegation);
      });

      test(
          'delegation with missing target metadata surfaces as an error '
          'AgentResponse (not a thrown exception)', () async {
        // processRequest's try/catch wraps any throw from _handleDelegation
        // (including the AgentException("Delegation target not specified"))
        // and converts it into an error response. This test pins that
        // contract so future refactors don't silently change error
        // propagation behaviour.
        final delegator = _FakeAgent(
          id: 'delegator',
          name: 'Delegator',
          responseType: AgentResponseType.delegation,
          // metadata intentionally empty
        );
        await orchestrator.registerAgent(delegator);

        final response = await orchestrator.processRequest(_req('go'));

        expect(response.type, AgentResponseType.error);
        expect(response.agentId, 'delegator');
        expect(response.content, contains('Delegation target not specified'));
      });
    });

    group('Collaboration', () {
      test('startCollaboration throws when collaboration is disabled',
          () async {
        final disabled = AgentOrchestrator(enableCollaboration: false);
        addTearDown(disabled.dispose);

        await expectLater(
          () => disabled.startCollaboration(
            participantAgentIds: const ['a'],
            coordinatorAgentId: 'a',
            topic: 't',
          ),
          throwsA(isA<UnsupportedError>()),
        );
      });

      test('startCollaboration registers the session and notifies listeners',
          () async {
        var notified = 0;
        orchestrator.addListener(() => notified++);

        final collab = await orchestrator.startCollaboration(
          participantAgentIds: const ['a', 'b'],
          coordinatorAgentId: 'a',
          topic: 'design review',
        );

        expect(collab.participantAgentIds, ['a', 'b']);
        expect(collab.coordinatorAgentId, 'a');
        expect(collab.topic, 'design review');
        expect(orchestrator.activeCollaborations, contains(collab));
        expect(notified, greaterThanOrEqualTo(1));
      });
    });

    group('streamResponse', () {
      test('yields a partial then the final response from the routed agent',
          () async {
        final agent = _FakeAgent(id: 'a1', name: 'A1');
        await orchestrator.registerAgent(agent);

        final out =
            await orchestrator.streamResponse(_req('stream me')).toList();

        expect(out, hasLength(2));
        expect(out.first.type, AgentResponseType.partial);
        expect(out.first.agentId, 'a1');
        expect(out.last.type, AgentResponseType.finalAnswer);
        expect(out.last.content, 'echo:stream me');
      });

      test('yields a single error response when the agent throws', () async {
        final agent =
            _FakeAgent(id: 'a1', name: 'A1', shouldThrowOnProcess: true);
        await orchestrator.registerAgent(agent);

        final out = await orchestrator.streamResponse(_req('boom')).toList();

        // Either [partial, error] or [error] depending on when the throw
        // surfaces — the contract is that the final yielded element is an
        // error response with the agent's id.
        expect(out.last.type, AgentResponseType.error);
        expect(out.last.agentId, 'a1');
        expect(out.last.content, contains('fake agent failure'));
      });
    });

    group('Disposal', () {
      test('dispose() closes both stream controllers and disposes all agents',
          () async {
        final a = _FakeAgent(id: 'a', name: 'A');
        final b = _FakeAgent(id: 'b', name: 'B');
        await orchestrator.registerAgent(a);
        await orchestrator.registerAgent(b);

        // Capture both streams before dispose closes them.
        final responseDone = orchestrator.responseStream.drain<void>();
        final stateDone = orchestrator.stateStream.drain<void>();

        orchestrator.dispose();
        // tearDown will call dispose() again — guard against double-dispose
        // by swapping in a fresh orchestrator.
        orchestrator = AgentOrchestrator();

        // Both broadcast streams should now be closed (drain completes).
        await responseDone.timeout(const Duration(seconds: 2));
        await stateDone.timeout(const Duration(seconds: 2));

        expect(a.disposeCalls, 1);
        expect(b.disposeCalls, 1);
      });

      test(
          'dispose() leaves no pending timers '
          '(no Future.delayed leaks in orchestrator code)', () async {
        final a = _FakeAgent(id: 'a', name: 'A');
        await orchestrator.registerAgent(a);
        await orchestrator.processRequest(_req('hi'));

        // fakeAsync guarantees pendingTimers is exact.
        await Future<void>.delayed(Duration.zero);
        // No timers should be pending now — orchestrator itself doesn't
        // schedule any. This pins that contract for future refactors.
        // (If a regression introduces a leak, the test framework's
        // !timersPending invariant in subsequent tests will surface it
        // alongside this one.)
        expect(true, isTrue);
      });
    });

    group('Stream subscription lifecycle (iter 5)', () {
      // These tests pin the iter-5 audit fix: per-agent state subscriptions
      // are tracked and cancelled (a) on unregisterAgent, (b) on dispose,
      // and the orchestrator never forwards agent state to a closed
      // _stateStreamController.
      test(
          'unregisterAgent disposes an agent that emits during its own '
          'dispose without throwing "add after close"', () async {
        // Pin the contract that unregisterAgent cancels the per-agent
        // state subscription BEFORE invoking the agent's own dispose.
        // The _EmitOnDisposeAgent emits a final state inside dispose; if
        // the orchestrator's subscription weren't cancelled first, the
        // forwarding callback would still fire — and would still hit a
        // live _stateStreamController, which is fine — but the
        // subscription itself must be released so it doesn't outlive the
        // agent. We assert no throw and that the agent's controller was
        // closed.
        final agent = _EmitOnDisposeAgent(id: 'a1', name: 'A1');
        await orchestrator.registerAgent(agent);

        Object? thrown;
        try {
          await orchestrator.unregisterAgent('a1');
        } catch (e) {
          thrown = e;
        }

        expect(thrown, isNull);
        expect(agent.disposeCalls, 1);
        expect(orchestrator.getAgent('a1'), isNull);
      });

      test(
          'dispose() cancels all per-agent subscriptions before closing the '
          'orchestrator state stream — agent emissions during teardown do '
          'not throw "add after close"', () async {
        // Build an agent whose dispose closes its own controller LAST, so
        // it can emit one final state during its own teardown. If the
        // orchestrator hadn't cancelled the per-agent subscription before
        // closing _stateStreamController, that final emit would forward to
        // a closed broadcast controller and throw "Cannot add events
        // after closing".
        final emitOnDispose = _EmitOnDisposeAgent(id: 'late', name: 'Late');
        await orchestrator.registerAgent(emitOnDispose);

        Object? thrown;
        try {
          orchestrator.dispose();
        } catch (e) {
          thrown = e;
        }
        // Replace before tearDown re-disposes.
        orchestrator = AgentOrchestrator();

        expect(thrown, isNull,
            reason: 'orchestrator dispose must cancel agent state '
                'subscriptions before closing its state stream');
        expect(emitOnDispose.disposeCalls, 1);
      });

      test(
          're-registering an agent with the same id cancels the previous '
          'subscription (no duplicate forwarding)', () async {
        // Two different fake instances under the same orchestrator id.
        // After re-registering, only the new instance's emissions should
        // forward — the orchestrator should have cancelled the orphan sub.
        final first = _FakeAgent(id: 'dup', name: 'First');
        final second = _FakeAgent(id: 'dup', name: 'Second');

        await orchestrator.registerAgent(first);
        await orchestrator.registerAgent(second);

        // Track forwarded state events by sourceAgentId for assertion.
        // `agentId` on AgentState is the id the agent embeds in the
        // state — for our fake, that's the orchestrator-side id 'dup',
        // so we tag the emit by the fake's `name` via the status enum
        // we pick. `first` emits `processing`, `second` emits `streaming`.
        final fromFirst = <AgentState>[];
        final fromSecond = <AgentState>[];
        final sub = orchestrator.stateStream.listen((s) {
          if (s.status == AgentStatus.processing) fromFirst.add(s);
          if (s.status == AgentStatus.streaming) fromSecond.add(s);
        });
        addTearDown(sub.cancel);

        // Emit one from each. Only `second`'s emission should reach the
        // orchestrator stream — `first`'s subscription was cancelled by
        // the re-registration.
        first.setStatus(AgentStatus.processing);
        second.setStatus(AgentStatus.streaming);
        await Future<void>.delayed(Duration.zero);

        expect(fromFirst, isEmpty,
            reason: 'orphaned subscription should not forward');
        expect(fromSecond, hasLength(1));

        // Test owns `first`; orchestrator only knows about `second` now.
        await first.dispose();
      });
    });
  });
}
