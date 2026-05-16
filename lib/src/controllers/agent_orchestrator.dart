import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/ai_agent.dart';

/// Multi-agent orchestration system similar to CopilotKit's CoAgents.
///
/// `AgentOrchestrator` registers a fleet of [AIAgent]s, scores them on each
/// incoming [AgentRequest], routes the request to the best match, surfaces
/// the response on a broadcast stream, and supports delegation between
/// agents and (optionally) multi-agent collaboration sessions.
///
/// The orchestrator is a [ChangeNotifier]; consumers own its lifecycle and
/// must call [dispose] when finished. [dispose] cancels per-agent state
/// subscriptions, closes both broadcast streams, and disposes every
/// registered agent in turn.
///
/// Example:
/// ```dart
/// final orchestrator = AgentOrchestrator();
/// await orchestrator.registerAgent(TextAnalysisAgent());
/// await orchestrator.registerAgent(CodeAnalysisAgent());
///
/// final response = await orchestrator.processRequest(AgentRequest(
///   id: 'r1',
///   query: 'Refactor this Python function',
///   type: AgentRequestType.standard,
///   timestamp: DateTime.now(),
/// ));
/// debugPrint(response.content);
///
/// // Streaming variant:
/// await for (final partial in orchestrator.streamResponse(request)) {
///   debugPrint(partial.content);
/// }
///
/// await orchestrator.dispose();
/// ```
class AgentOrchestrator extends ChangeNotifier {
  final Map<String, AIAgent> _agents = {};
  final Map<String, AgentCollaboration> _activeCollaborations = {};
  // Per-agent subscriptions to each registered agent's state stream. Tracked so
  // that unregisterAgent can cancel cleanly, and dispose() can cancel all
  // before closing the orchestrator's own broadcast controllers — otherwise
  // an agent emitting on its way down (e.g. inside its own dispose) would
  // forward to a closed controller and throw "Cannot add events after
  // closing".
  final Map<String, StreamSubscription<AgentState>> _agentStateSubscriptions =
      {};
  final StreamController<AgentResponse> _responseStreamController =
      StreamController<AgentResponse>.broadcast();
  final StreamController<AgentState> _stateStreamController =
      StreamController<AgentState>.broadcast();
  bool _disposed = false;

  /// Maximum number of in-flight requests the orchestrator will accept
  /// concurrently. Currently advisory; reserved for future back-pressure
  /// support.
  final int maxConcurrentRequests;

  /// Per-request timeout. Currently advisory; reserved for future
  /// orchestration-level timeout enforcement.
  final Duration requestTimeout;

  /// Whether multi-agent collaboration is allowed.
  ///
  /// When false, [startCollaboration] throws an [UnsupportedError].
  final bool enableCollaboration;

  /// Creates an [AgentOrchestrator].
  ///
  /// All parameters are optional. The defaults are tuned for interactive
  /// chat use: 10 concurrent requests, 30 second timeout, collaboration on.
  AgentOrchestrator({
    this.maxConcurrentRequests = 10,
    this.requestTimeout = const Duration(seconds: 30),
    this.enableCollaboration = true,
  });

  /// All currently registered agents, in insertion order.
  List<AIAgent> get agents => _agents.values.toList();

  /// All active collaboration sessions started via [startCollaboration].
  List<AgentCollaboration> get activeCollaborations =>
      _activeCollaborations.values.toList();

  /// Broadcast stream of every [AgentResponse] the orchestrator emits,
  /// including responses returned synchronously via [processRequest] and
  /// chunks yielded by [streamResponse].
  Stream<AgentResponse> get responseStream => _responseStreamController.stream;

  /// Broadcast stream of every [AgentState] emitted by registered agents.
  ///
  /// The orchestrator forwards each agent's state stream onto this single
  /// merged stream while the agent is registered.
  Stream<AgentState> get stateStream => _stateStreamController.stream;

  /// Register an agent with the orchestrator
  Future<void> registerAgent(AIAgent agent) async {
    // If an agent with this id was previously registered, cancel its old
    // subscription before overwriting (defensive against re-registration).
    await _agentStateSubscriptions.remove(agent.id)?.cancel();
    _agents[agent.id] = agent;

    // Listen to agent state changes. Track the subscription so it can be
    // cancelled in unregisterAgent / dispose. Forwarding via a closure
    // (rather than tear-off) lets us drop events after the orchestrator is
    // disposed, in case the agent emits during its own teardown.
    _agentStateSubscriptions[agent.id] = agent.streamState().listen((state) {
      if (_disposed || _stateStreamController.isClosed) return;
      _stateStreamController.add(state);
    });

    // Initialize agent
    await agent.initialize({
      'orchestrator_id': 'main',
      'collaboration_enabled': enableCollaboration,
    });

    notifyListeners();
  }

  /// Unregister an agent
  Future<void> unregisterAgent(String agentId) async {
    final agent = _agents[agentId];
    if (agent != null) {
      // Cancel the agent's state subscription before disposing the agent so
      // any final emissions from the agent's dispose path don't forward to
      // the orchestrator's stream.
      await _agentStateSubscriptions.remove(agentId)?.cancel();
      await agent.dispose();
      _agents.remove(agentId);
      notifyListeners();
    }
  }

  /// Process a request through intelligent agent routing
  Future<AgentResponse> processRequest(AgentRequest request) async {
    // Find the best agent for this request
    final routingDecision = await _routeRequest(request);
    final targetAgent = _agents[routingDecision.targetAgentId];

    if (targetAgent == null) {
      throw AgentException(
          'Target agent ${routingDecision.targetAgentId} not found');
    }

    try {
      final response = await targetAgent.processRequest(request);
      _responseStreamController.add(response);

      // Handle delegation if needed
      if (response.type == AgentResponseType.delegation) {
        return await _handleDelegation(request, response);
      }

      // Handle collaboration requests
      if (response.type == AgentResponseType.collaborationRequest) {
        return await _handleCollaborationRequest(request, response);
      }

      return response;
    } catch (e) {
      final errorResponse = AgentResponse(
        id: 'error_${DateTime.now().millisecondsSinceEpoch}',
        requestId: request.id,
        agentId: targetAgent.id,
        content: 'Error processing request: $e',
        type: AgentResponseType.error,
        timestamp: DateTime.now(),
      );

      _responseStreamController.add(errorResponse);
      return errorResponse;
    }
  }

  /// Stream responses for real-time processing
  Stream<AgentResponse> streamResponse(AgentRequest request) async* {
    final routingDecision = await _routeRequest(request);
    final targetAgent = _agents[routingDecision.targetAgentId];

    if (targetAgent == null) {
      yield AgentResponse(
        id: 'error_${DateTime.now().millisecondsSinceEpoch}',
        requestId: request.id,
        agentId: 'orchestrator',
        content: 'Target agent ${routingDecision.targetAgentId} not found',
        type: AgentResponseType.error,
        timestamp: DateTime.now(),
      );
      return;
    }

    try {
      // For now, simulate streaming by yielding partial responses
      yield AgentResponse(
        id: 'partial_${DateTime.now().millisecondsSinceEpoch}',
        requestId: request.id,
        agentId: targetAgent.id,
        content: 'Processing request with ${targetAgent.name}...',
        type: AgentResponseType.partial,
        timestamp: DateTime.now(),
      );

      final finalResponse = await targetAgent.processRequest(request);
      _responseStreamController.add(finalResponse);
      yield finalResponse;
    } catch (e) {
      yield AgentResponse(
        id: 'error_${DateTime.now().millisecondsSinceEpoch}',
        requestId: request.id,
        agentId: targetAgent.id,
        content: 'Error processing request: $e',
        type: AgentResponseType.error,
        timestamp: DateTime.now(),
      );
    }
  }

  /// Start a collaboration between multiple agents
  Future<AgentCollaboration> startCollaboration({
    required List<String> participantAgentIds,
    required String coordinatorAgentId,
    required String topic,
  }) async {
    if (!enableCollaboration) {
      throw UnsupportedError('Collaboration is disabled');
    }

    final collaboration = AgentCollaboration(
      id: 'collab_${DateTime.now().millisecondsSinceEpoch}',
      participantAgentIds: participantAgentIds,
      coordinatorAgentId: coordinatorAgentId,
      topic: topic,
      startedAt: DateTime.now(),
    );

    _activeCollaborations[collaboration.id] = collaboration;
    notifyListeners();

    return collaboration;
  }

  /// Returns the agent registered under [agentId], or `null` if not found.
  AIAgent? getAgent(String agentId) => _agents[agentId];

  /// Returns every registered agent whose `capabilities` list contains
  /// [capability]. Matching is case-sensitive.
  List<AIAgent> getAgentsByCapability(String capability) {
    return _agents.values
        .where((agent) => agent.capabilities.contains(capability))
        .toList();
  }

  /// Returns every registered agent currently in [AgentStatus.idle].
  ///
  /// Useful for showing a "ready" indicator or for picking a free agent
  /// when the routing scorer comes up empty.
  List<AIAgent> getAvailableAgents() {
    return _agents.values
        .where((agent) => agent.status == AgentStatus.idle)
        .toList();
  }

  // Private methods

  /// Route a request to the most appropriate agent
  Future<RoutingDecision> _routeRequest(AgentRequest request) async {
    if (_agents.isEmpty) {
      throw const AgentException('No agents available');
    }

    // Simple routing algorithm - can be enhanced with ML models
    var bestScore = 0.0;
    String? bestAgentId;
    var reasoning = 'Default routing';

    for (final agent in _agents.values) {
      if (!agent.canHandle(request)) continue;

      final score = _calculateRoutingScore(agent, request);
      if (score > bestScore) {
        bestScore = score;
        bestAgentId = agent.id;
        reasoning =
            'Best match: ${agent.specialization} (score: ${score.toStringAsFixed(2)})';
      }
    }

    if (bestAgentId == null) {
      // Fallback to first available agent
      final availableAgents = getAvailableAgents();
      if (availableAgents.isNotEmpty) {
        bestAgentId = availableAgents.first.id;
        reasoning = 'Fallback to available agent';
      } else {
        throw const AgentException('No suitable agent found for request');
      }
    }

    return RoutingDecision(
      targetAgentId: bestAgentId,
      confidence: bestScore,
      reasoning: reasoning,
    );
  }

  /// Calculate routing score for an agent
  double _calculateRoutingScore(AIAgent agent, AgentRequest request) {
    var score = 0.0;

    // Check if agent can handle the request
    if (!agent.canHandle(request)) return 0.0;

    // Capability match score
    final queryLower = request.query.toLowerCase();
    for (final capability in agent.capabilities) {
      if (queryLower.contains(capability.toLowerCase())) {
        score += 0.3;
      }
    }

    // Agent availability score
    switch (agent.status) {
      case AgentStatus.idle:
        score += 0.5;
        break;
      case AgentStatus.processing:
        score += 0.1;
        break;
      case AgentStatus.streaming:
        score += 0.2;
        break;
      default:
        score -= 0.2;
    }

    // Priority bonus
    switch (agent.priority) {
      case AgentPriority.high:
        score += 0.2;
        break;
      case AgentPriority.critical:
        score += 0.3;
        break;
      default:
        break;
    }

    // Random factor to prevent always selecting the same agent
    score += Random().nextDouble() * 0.1;

    return score;
  }

  /// Handle delegation to another agent
  Future<AgentResponse> _handleDelegation(
      AgentRequest originalRequest, AgentResponse delegationResponse) async {
    // Extract delegation information from response metadata
    final targetAgentId = delegationResponse.metadata['delegate_to'] as String?;
    final delegatedQuery =
        delegationResponse.metadata['delegated_query'] as String? ??
            originalRequest.query;

    if (targetAgentId == null) {
      throw const AgentException('Delegation target not specified');
    }

    final targetAgent = _agents[targetAgentId];
    if (targetAgent == null) {
      throw AgentException('Delegation target agent not found: $targetAgentId');
    }

    // Create delegated request
    final delegatedRequest = originalRequest.copyWith(
      id: 'delegated_${DateTime.now().millisecondsSinceEpoch}',
      query: delegatedQuery,
      type: AgentRequestType.delegation,
      parentRequestId: originalRequest.id,
    );

    return await targetAgent.processRequest(delegatedRequest);
  }

  /// Handle collaboration request
  Future<AgentResponse> _handleCollaborationRequest(
      AgentRequest originalRequest, AgentResponse collaborationResponse) async {
    final participantIds =
        collaborationResponse.metadata['participants'] as List<String>?;
    final coordinatorId =
        collaborationResponse.metadata['coordinator'] as String?;
    final topic = collaborationResponse.metadata['topic'] as String? ??
        originalRequest.query;

    if (participantIds == null || coordinatorId == null) {
      throw const AgentException('Collaboration parameters not specified');
    }

    final collaboration = await startCollaboration(
      participantAgentIds: participantIds,
      coordinatorAgentId: coordinatorId,
      topic: topic,
    );

    return AgentResponse(
      id: 'collab_response_${DateTime.now().millisecondsSinceEpoch}',
      requestId: originalRequest.id,
      agentId: 'orchestrator',
      content:
          'Started collaboration ${collaboration.id} with ${participantIds.length} agents',
      type: AgentResponseType.finalAnswer,
      metadata: {'collaboration_id': collaboration.id},
      timestamp: DateTime.now(),
    );
  }

  /// Releases all resources held by this orchestrator.
  ///
  /// Cancels every per-agent state subscription, closes the response and
  /// state broadcast streams, and calls `dispose` on each registered
  /// agent. Safe to call multiple times; subsequent calls are no-ops on
  /// already-closed controllers.
  @override
  void dispose() {
    _disposed = true;

    // Cancel every per-agent state subscription FIRST. This guarantees that
    // any state an agent emits as it's torn down below cannot forward to
    // _stateStreamController (which we're about to close).
    for (final sub in _agentStateSubscriptions.values) {
      sub.cancel();
    }
    _agentStateSubscriptions.clear();

    _responseStreamController.close();
    _stateStreamController.close();

    // Dispose all agents
    for (final agent in _agents.values) {
      agent.dispose();
    }
    _agents.clear();

    super.dispose();
  }
}

/// Exception thrown when agent routing, delegation, or collaboration fails.
///
/// `processRequest` translates these into an error [AgentResponse] for
/// callers so the public API never throws on a normal agent failure.
/// `_routeRequest` and `_handleDelegation` may throw [AgentException]
/// directly when there is no possible recovery (e.g. no agents
/// registered, missing delegation target).
class AgentException implements Exception {
  /// Human-readable failure description.
  final String message;

  /// Creates an [AgentException] with the given [message].
  const AgentException(this.message);

  @override
  String toString() => 'AgentException: $message';
}
