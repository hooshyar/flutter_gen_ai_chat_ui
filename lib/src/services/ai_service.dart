import 'dart:async';
import 'dart:convert';

import '../models/ai_action.dart';

/// Abstract interface for AI services (OpenAI, Anthropic, etc.)
abstract class AiService {
  /// Send a message to the AI service and get a response
  Future<String> sendMessage(String message);

  /// Send a message and get a streaming response
  Stream<String> sendMessageStream(String message);

  /// Send a message with function calling capabilities
  Future<AiFunctionCallResult> sendMessageWithFunctions(
    String message,
    List<AiAction> availableActions,
  );

  /// Send a message with function calling and get streaming response
  Stream<AiFunctionCallStreamResult> sendMessageWithFunctionsStream(
    String message,
    List<AiAction> availableActions,
  );
}

/// Result from AI function calling
class AiFunctionCallResult {
  final String? textResponse;
  final AiFunctionCall? functionCall;
  final bool isComplete;

  const AiFunctionCallResult({
    this.textResponse,
    this.functionCall,
    this.isComplete = true,
  });
}

/// Streaming result from AI function calling
class AiFunctionCallStreamResult {
  final String? textChunk;
  final AiFunctionCall? functionCall;
  final bool isComplete;
  final AiFunctionCallResultType type;

  const AiFunctionCallStreamResult({
    this.textChunk,
    this.functionCall,
    this.isComplete = false,
    required this.type,
  });
}

/// The kind of chunk an [AiFunctionCallStreamResult] carries.
enum AiFunctionCallResultType {
  /// A partial text token, as it streams in.
  textChunk,

  /// A complete function/tool call the model wants to invoke.
  functionCall,

  /// The stream has finished.
  complete,
}

/// Function call from AI
class AiFunctionCall {
  final String name;
  final Map<String, dynamic> arguments;
  final String? id;

  const AiFunctionCall({
    required this.name,
    required this.arguments,
    this.id,
  });

  factory AiFunctionCall.fromJson(Map<String, dynamic> json) {
    return AiFunctionCall(
      name: json['name'] as String,
      arguments: json['arguments'] is String
          ? jsonDecode(json['arguments'] as String) as Map<String, dynamic>
          : json['arguments'] as Map<String, dynamic>,
      id: json['id'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'arguments': arguments,
        if (id != null) 'id': id,
      };
}

/// Configuration for AI services
class AiServiceConfig {
  final String apiKey;
  final String? baseUrl;
  final String? model;
  final Map<String, dynamic> parameters;

  const AiServiceConfig({
    required this.apiKey,
    this.baseUrl,
    this.model,
    this.parameters = const {},
  });
}

/// Exception for AI service errors
class AiServiceException implements Exception {
  final String message;
  final String? code;
  final int? statusCode;
  final Map<String, dynamic>? details;

  const AiServiceException(
    this.message, {
    this.code,
    this.statusCode,
    this.details,
  });

  @override
  String toString() =>
      'AiServiceException: $message${code != null ? ' ($code)' : ''}';
}

/// Mock AI service for testing and development
class MockAiService extends AiService {
  final Duration delay;
  final bool shouldFail;

  MockAiService({
    this.delay = const Duration(seconds: 1),
    this.shouldFail = false,
  });

  @override
  Future<String> sendMessage(String message) async {
    await Future<void>.delayed(delay);

    if (shouldFail) {
      throw const AiServiceException('Mock service error');
    }

    return _generateMockResponse(message);
  }

  @override
  Stream<String> sendMessageStream(String message) async* {
    if (shouldFail) {
      throw const AiServiceException('Mock service error');
    }

    final response = _generateMockResponse(message);
    final words = response.split(' ');

    for (var i = 0; i < words.length; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      yield '${words[i]} ';
    }
  }

  @override
  Future<AiFunctionCallResult> sendMessageWithFunctions(
    String message,
    List<AiAction> availableActions,
  ) async {
    await Future<void>.delayed(delay);

    if (shouldFail) {
      throw const AiServiceException('Mock service error');
    }

    // Simple pattern matching to simulate function calling
    final lowerMessage = message.toLowerCase();

    if (lowerMessage.contains('calculate') || lowerMessage.contains('math')) {
      return const AiFunctionCallResult(
        functionCall: AiFunctionCall(
          name: 'basic_math',
          arguments: {'a': 10, 'b': 5, 'operation': 'add'},
        ),
      );
    } else if (lowerMessage.contains('weather')) {
      return const AiFunctionCallResult(
        functionCall: AiFunctionCall(
          name: 'get_weather',
          arguments: {'location': 'London'},
        ),
      );
    } else {
      return AiFunctionCallResult(
        textResponse: _generateMockResponse(message),
      );
    }
  }

  @override
  Stream<AiFunctionCallStreamResult> sendMessageWithFunctionsStream(
    String message,
    List<AiAction> availableActions,
  ) async* {
    if (shouldFail) {
      throw const AiServiceException('Mock service error');
    }

    // Simulate thinking
    await Future<void>.delayed(const Duration(milliseconds: 500));

    final lowerMessage = message.toLowerCase();

    if (lowerMessage.contains('calculate') || lowerMessage.contains('math')) {
      yield const AiFunctionCallStreamResult(
        type: AiFunctionCallResultType.functionCall,
        functionCall: AiFunctionCall(
          name: 'basic_math',
          arguments: {'a': 10, 'b': 5, 'operation': 'add'},
        ),
      );
    } else if (lowerMessage.contains('weather')) {
      yield const AiFunctionCallStreamResult(
        type: AiFunctionCallResultType.functionCall,
        functionCall: AiFunctionCall(
          name: 'get_weather',
          arguments: {'location': 'London'},
        ),
      );
    } else {
      // Stream text response
      final response = _generateMockResponse(message);
      final words = response.split(' ');

      for (var i = 0; i < words.length; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        yield AiFunctionCallStreamResult(
          type: AiFunctionCallResultType.textChunk,
          textChunk: '${words[i]} ',
        );
      }
    }

    yield const AiFunctionCallStreamResult(
      type: AiFunctionCallResultType.complete,
      isComplete: true,
    );
  }

  String _generateMockResponse(String message) {
    if (message.toLowerCase().contains('hello')) {
      return 'Hello! How can I help you today?';
    } else if (message.toLowerCase().contains('weather')) {
      return 'I can help you get weather information. Let me call the weather function.';
    } else if (message.toLowerCase().contains('calculate')) {
      return 'I can help with calculations. Let me perform that calculation for you.';
    } else {
      return 'I understand you said: "$message". How can I assist you with that?';
    }
  }
}

/// Helper for integrating AI services with ActionController
class AiServiceIntegration {
  final AiService aiService;

  AiServiceIntegration(this.aiService);

  /// Process AI function calling with automatic action execution
  Future<String> processMessageWithActions(
    String message,
    List<AiAction> availableActions,
    Future<ActionResult> Function(
            String actionName, Map<String, dynamic> parameters)
        executeAction,
  ) async {
    final result =
        await aiService.sendMessageWithFunctions(message, availableActions);

    if (result.functionCall != null) {
      final actionResult = await executeAction(
        result.functionCall!.name,
        result.functionCall!.arguments,
      );

      if (actionResult.success) {
        return 'Action executed successfully: ${actionResult.data}';
      } else {
        return 'Action failed: ${actionResult.error}';
      }
    }

    return result.textResponse ?? 'No response from AI service';
  }

  /// Process streaming AI function calling with automatic action execution
  Stream<String> processMessageWithActionsStream(
    String message,
    List<AiAction> availableActions,
    Future<ActionResult> Function(
            String actionName, Map<String, dynamic> parameters)
        executeAction,
  ) async* {
    await for (final result in aiService.sendMessageWithFunctionsStream(
        message, availableActions)) {
      switch (result.type) {
        case AiFunctionCallResultType.textChunk:
          if (result.textChunk != null) {
            yield result.textChunk!;
          }
          break;
        case AiFunctionCallResultType.functionCall:
          if (result.functionCall != null) {
            yield '\n\n🔄 Executing ${result.functionCall!.name}...\n\n';

            try {
              final actionResult = await executeAction(
                result.functionCall!.name,
                result.functionCall!.arguments,
              );

              if (actionResult.success) {
                yield 'Action completed: ${actionResult.data}';
              } else {
                yield 'Action failed: ${actionResult.error}';
              }
            } catch (e) {
              yield 'Error executing action: $e';
            }
          }
          break;
        case AiFunctionCallResultType.complete:
          // Stream is complete
          break;
      }
    }
  }
}
