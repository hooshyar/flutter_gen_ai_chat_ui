import 'dart:async';

/// Abstract base class for AI agents in the orchestration system
/// Equivalent to CopilotKit's agent system with multi-agent coordination
abstract class AIAgent {
  /// Unique identifier for this agent.
  final String id;

  /// Display name for this agent.
  final String name;

  /// What this agent is responsible for, e.g. `'weather'` or `'billing'` —
  /// used by orchestration to route requests to the right agent.
  final String specialization;

  /// Named capabilities this agent advertises (free-form, orchestration- and
  /// agent-specific).
  final List<String> capabilities;

  /// Relative priority when multiple agents could handle the same request.
  final AgentPriority priority;

  const AIAgent({
    required this.id,
    required this.name,
    required this.specialization,
    required this.capabilities,
    this.priority = AgentPriority.normal,
  });

  /// Process a request and return a response
  Future<AgentResponse> processRequest(AgentRequest request);

  /// Stream agent state for real-time updates
  Stream<AgentState> streamState();

  /// Check if this agent can handle a specific request
  bool canHandle(AgentRequest request);

  /// Get current agent status
  AgentStatus get status;

  /// Initialize agent with configuration
  Future<void> initialize(Map<String, dynamic> config);

  /// Clean up agent resources
  Future<void> dispose();
}

/// Request sent to an agent
class AgentRequest {
  /// Unique identifier for this request.
  final String id;

  /// The user's (or delegating agent's) query text.
  final String query;

  /// Arbitrary contextual data available to the handling agent.
  final Map<String, dynamic> context;

  /// What kind of request this is.
  final AgentRequestType type;

  /// When this request was created.
  final DateTime timestamp;

  /// The id of the request this one was delegated from, if any.
  final String? parentRequestId;

  const AgentRequest({
    required this.id,
    required this.query,
    this.context = const {},
    required this.type,
    required this.timestamp,
    this.parentRequestId,
  });

  AgentRequest copyWith({
    String? id,
    String? query,
    Map<String, dynamic>? context,
    AgentRequestType? type,
    DateTime? timestamp,
    String? parentRequestId,
  }) {
    return AgentRequest(
      id: id ?? this.id,
      query: query ?? this.query,
      context: context ?? this.context,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      parentRequestId: parentRequestId ?? this.parentRequestId,
    );
  }
}

/// Response from an agent
class AgentResponse {
  /// Unique identifier for this response.
  final String id;

  /// The id of the [AgentRequest] this responds to.
  final String requestId;

  /// The id of the [AIAgent] that produced this response.
  final String agentId;

  /// The response text.
  final String content;

  /// What kind of response this is.
  final AgentResponseType type;

  /// The agent's own confidence in this response, from `0.0` to `1.0`.
  final double confidence;

  /// Arbitrary agent-specific metadata about this response.
  final Map<String, dynamic> metadata;

  /// Actions the agent suggests as a follow-up, if any.
  final List<AgentAction>? suggestedActions;

  /// When this response was produced.
  final DateTime timestamp;

  const AgentResponse({
    required this.id,
    required this.requestId,
    required this.agentId,
    required this.content,
    required this.type,
    this.confidence = 1.0,
    this.metadata = const {},
    this.suggestedActions,
    required this.timestamp,
  });

  AgentResponse copyWith({
    String? id,
    String? requestId,
    String? agentId,
    String? content,
    AgentResponseType? type,
    double? confidence,
    Map<String, dynamic>? metadata,
    List<AgentAction>? suggestedActions,
    DateTime? timestamp,
  }) {
    return AgentResponse(
      id: id ?? this.id,
      requestId: requestId ?? this.requestId,
      agentId: agentId ?? this.agentId,
      content: content ?? this.content,
      type: type ?? this.type,
      confidence: confidence ?? this.confidence,
      metadata: metadata ?? this.metadata,
      suggestedActions: suggestedActions ?? this.suggestedActions,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}

/// Current state of an agent
class AgentState {
  /// The id of the [AIAgent] this state describes.
  final String agentId;

  /// The agent's current lifecycle status.
  final AgentStatus status;

  /// A short description of what the agent is currently doing, if any.
  final String? currentTask;

  /// How busy the agent currently is, from `0.0` (idle) to `1.0` (saturated).
  final double workload; // 0.0 to 1.0

  /// Arbitrary agent-specific state data.
  final Map<String, dynamic> stateData;

  /// When this state snapshot was taken.
  final DateTime lastUpdated;

  const AgentState({
    required this.agentId,
    required this.status,
    this.currentTask,
    this.workload = 0.0,
    this.stateData = const {},
    required this.lastUpdated,
  });

  AgentState copyWith({
    String? agentId,
    AgentStatus? status,
    String? currentTask,
    double? workload,
    Map<String, dynamic>? stateData,
    DateTime? lastUpdated,
  }) {
    return AgentState(
      agentId: agentId ?? this.agentId,
      status: status ?? this.status,
      currentTask: currentTask ?? this.currentTask,
      workload: workload ?? this.workload,
      stateData: stateData ?? this.stateData,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

/// Action that an agent can perform or suggest
class AgentAction {
  /// Unique identifier for this action.
  final String id;

  /// Short, human-readable name for this action.
  final String name;

  /// Longer description of what this action does.
  final String description;

  /// Arguments the action should run with, if any.
  final Map<String, dynamic> parameters;

  /// How urgently this action should be run relative to others.
  final ActionPriority priority;

  const AgentAction({
    required this.id,
    required this.name,
    required this.description,
    this.parameters = const {},
    this.priority = ActionPriority.normal,
  });
}

/// Lifecycle status of an AI agent (idle, processing, error, etc.).
enum AgentStatus {
  /// Setting up (e.g. running [AIAgent.initialize]); not yet ready.
  initializing,

  /// Ready and waiting for a request.
  idle,

  /// Actively working on a request.
  processing,

  /// Emitting a response incrementally via [AIAgent.streamState].
  streaming,

  /// Handed the request off to another agent.
  delegating,

  /// Failed to complete its current request.
  error,

  /// Unavailable to handle requests.
  offline,
}

/// Priority level assigned to an agent request or task.
enum AgentPriority {
  /// Handle when convenient.
  low,

  /// Default priority.
  normal,

  /// Handle ahead of normal-priority work.
  high,

  /// Handle immediately, ahead of everything else.
  critical,
}

/// Categorizes the kind of request sent to an agent.
enum AgentRequestType {
  /// A question the agent should answer.
  query,

  /// An instruction the agent should carry out.
  command,

  /// A request forwarded from another agent (see
  /// [AgentRequest.parentRequestId]).
  delegation,

  /// A request that's part of a multi-agent [AgentCollaboration].
  collaboration,

  /// Notifies the agent that shared context has changed, with no response
  /// expected.
  contextUpdate,
}

/// Categorizes the kind of response returned by an agent.
enum AgentResponseType {
  /// A complete, standalone answer.
  answer,

  /// The agent is handing the request to another agent.
  delegation,

  /// One chunk of a still-in-progress streamed response.
  partial,

  /// The last chunk of a streamed response.
  finalAnswer,

  /// The agent failed to produce a response.
  error,

  /// The agent is asking other agents to collaborate on this request.
  collaborationRequest,
}

/// Priority level for an agent-suggested action.
enum ActionPriority {
  /// Handle when convenient.
  low,

  /// Default priority.
  normal,

  /// Handle ahead of normal-priority actions.
  high,

  /// Handle immediately, ahead of everything else.
  critical,
}

/// Routing decision for agent orchestration
class RoutingDecision {
  /// The id of the [AIAgent] the request should be routed to.
  final String targetAgentId;

  /// How confident the router is in this decision, from `0.0` to `1.0`.
  final double confidence;

  /// A human-readable explanation of why this agent was chosen.
  final String reasoning;

  /// Arbitrary router-specific metadata about this decision.
  final Map<String, dynamic> routingMetadata;

  const RoutingDecision({
    required this.targetAgentId,
    required this.confidence,
    required this.reasoning,
    this.routingMetadata = const {},
  });
}

/// Collaboration between multiple agents
class AgentCollaboration {
  /// Unique identifier for this collaboration session.
  final String id;

  /// Ids of the [AIAgent]s participating in this collaboration.
  final List<String> participantAgentIds;

  /// The id of the [AIAgent] coordinating this collaboration.
  final String coordinatorAgentId;

  /// What the participating agents are collaborating on.
  final String topic;

  /// Current progress of this collaboration.
  final CollaborationStatus status;

  /// Responses contributed so far by the participating agents.
  final List<AgentResponse> responses;

  /// When this collaboration began.
  final DateTime startedAt;

  /// When this collaboration finished, or `null` while still active.
  final DateTime? completedAt;

  const AgentCollaboration({
    required this.id,
    required this.participantAgentIds,
    required this.coordinatorAgentId,
    required this.topic,
    this.status = CollaborationStatus.active,
    this.responses = const [],
    required this.startedAt,
    this.completedAt,
  });

  AgentCollaboration copyWith({
    String? id,
    List<String>? participantAgentIds,
    String? coordinatorAgentId,
    String? topic,
    CollaborationStatus? status,
    List<AgentResponse>? responses,
    DateTime? startedAt,
    DateTime? completedAt,
  }) {
    return AgentCollaboration(
      id: id ?? this.id,
      participantAgentIds: participantAgentIds ?? this.participantAgentIds,
      coordinatorAgentId: coordinatorAgentId ?? this.coordinatorAgentId,
      topic: topic ?? this.topic,
      status: status ?? this.status,
      responses: responses ?? this.responses,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}

/// Tracks the progress of a multi-agent collaboration session.
enum CollaborationStatus {
  /// Currently in progress.
  active,

  /// Finished successfully.
  completed,

  /// Ended without producing a usable result.
  failed,

  /// Ended before completion, by request.
  cancelled,
}
