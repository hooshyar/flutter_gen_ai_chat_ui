import 'dart:async';

/// Abstract base class for AI agents in the orchestration system
/// Equivalent to CopilotKit's agent system with multi-agent coordination
abstract class AIAgent {
  final String id;
  final String name;
  final String specialization;
  final List<String> capabilities;
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
  final String id;
  final String query;
  final Map<String, dynamic> context;
  final AgentRequestType type;
  final DateTime timestamp;
  final String? parentRequestId; // For delegated requests

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
  final String id;
  final String requestId;
  final String agentId;
  final String content;
  final AgentResponseType type;
  final double confidence;
  final Map<String, dynamic> metadata;
  final List<AgentAction>? suggestedActions;
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
  final String agentId;
  final AgentStatus status;
  final String? currentTask;
  final double workload; // 0.0 to 1.0
  final Map<String, dynamic> stateData;
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
  final String id;
  final String name;
  final String description;
  final Map<String, dynamic> parameters;
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
  initializing,
  idle,
  processing,
  streaming,
  delegating,
  error,
  offline,
}

/// Priority level assigned to an agent request or task.
enum AgentPriority {
  low,
  normal,
  high,
  critical,
}

/// Categorizes the kind of request sent to an agent.
enum AgentRequestType {
  query,
  command,
  delegation,
  collaboration,
  contextUpdate,
}

/// Categorizes the kind of response returned by an agent.
enum AgentResponseType {
  answer,
  delegation,
  partial,
  finalAnswer,
  error,
  collaborationRequest,
}

/// Priority level for an agent-suggested action.
enum ActionPriority {
  low,
  normal,
  high,
  critical,
}

/// Routing decision for agent orchestration
class RoutingDecision {
  final String targetAgentId;
  final double confidence;
  final String reasoning;
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
  final String id;
  final List<String> participantAgentIds;
  final String coordinatorAgentId;
  final String topic;
  final CollaborationStatus status;
  final List<AgentResponse> responses;
  final DateTime startedAt;
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
  active,
  completed,
  failed,
  cancelled,
}
