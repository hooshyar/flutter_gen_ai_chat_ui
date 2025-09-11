import 'package:flutter/widgets.dart';
import '../models/ai_action.dart';
import '../models/chat/chat_message.dart';
import '../models/chat/chat_user.dart';
import 'action_controller.dart';
import 'chat_messages_controller.dart';
import 'readable_context_controller.dart';

/// A chat controller that automatically integrates readable context and actions
/// Similar to CopilotKit's automatic context sharing during conversations
class ContextAwareChatController extends ChangeNotifier {
  final ChatMessagesController _chatController;
  final ReadableContextController _readableController;
  final ActionController _actionController;

  /// Whether to automatically include context in AI prompts
  bool includeContextInPrompts = true;

  /// Whether to include available actions in AI prompts
  bool includeActionsInPrompts = true;

  /// Maximum context length to include in prompts
  int maxContextLength = 2000;

  ContextAwareChatController({
    ChatMessagesController? chatController,
    ReadableContextController? readableController,
    ActionController? actionController,
  })  : _chatController = chatController ?? ChatMessagesController(),
        _readableController = readableController ?? ReadableContextController(),
        _actionController = actionController ?? ActionController() {
    // Listen to changes in context and actions to update AI awareness
    _readableController.addListener(_onContextChanged);
    _actionController.addListener(_onActionsChanged);
  }

  /// Get the chat controller
  ChatMessagesController get chatController => _chatController;

  /// Get the readable context controller
  ReadableContextController get readableController => _readableController;

  /// Get the action controller
  ActionController get actionController => _actionController;

  /// Send a message with automatic context inclusion
  Future<void> sendMessage(
    ChatMessage message, {
    required Future<String> Function(
            String enhancedPrompt, List<AiAction> availableActions)
        onAiResponse,
  }) async {
    // Add user message first
    _chatController.addMessage(message);

    // Create enhanced prompt with context
    final enhancedPrompt = _createEnhancedPrompt(message.text);

    // Get available actions
    final availableActions = _actionController.registeredActions;

    try {
      // Get AI response with enhanced context
      final aiResponseText =
          await onAiResponse(enhancedPrompt, availableActions);

      // Create AI response message
      final aiMessage = ChatMessage(
        text: aiResponseText,
        user: const ChatUser(id: 'ai', name: 'AI Assistant'),
        createdAt: DateTime.now(),
        isMarkdown: true,
      );

      _chatController.addMessage(aiMessage);
    } catch (e) {
      // Add error message
      final errorMessage = ChatMessage(
        text: 'Sorry, I encountered an error: $e',
        user: const ChatUser(id: 'ai', name: 'AI Assistant'),
        createdAt: DateTime.now(),
      );

      _chatController.addMessage(errorMessage);
    }
  }

  /// Create an enhanced prompt that includes context and actions
  // ignore: cascade_invocations
  String _createEnhancedPrompt(String originalMessage) {
    final buffer = StringBuffer();

    // Build the complete prompt
    // ignore: cascade_invocations
    buffer.writeln('User Request: $originalMessage');

    // Add readable context if enabled and available
    if (includeContextInPrompts) {
      final context = _readableController.contextSummary;
      if (context != 'No application context available.') {
        // Truncate context if too long
        final contextToAdd = context.length > maxContextLength
            ? '${context.substring(0, maxContextLength)}...'
            : context;

        buffer
          ..writeln('\\n--- Application Context ---')
          ..writeln(contextToAdd);
      }
    }

    // Add available actions if enabled and available
    if (includeActionsInPrompts) {
      final actions = _actionController.registeredActions;
      if (actions.isNotEmpty) {
        buffer
          ..writeln('\\n--- Available Actions ---')
          ..writeln('You can call the following actions to help the user:');

        for (final action in actions) {
          buffer.writeln('- ${action.name}: ${action.description}');

          // Add parameter info
          if (action.parameters.isNotEmpty) {
            final paramNames = action.parameters.map((p) => p.name).join(', ');
            buffer.writeln('  Parameters: $paramNames');
          }
        }

        buffer.writeln(
            '\\nTo use an action, simply mention it naturally in your response.');
      }
    }

    // Add final instructions
    buffer
      ..writeln('\\n--- Instructions ---')
      ..writeln(
          'Use the provided context to give more relevant and helpful responses.')
      ..writeln('If you can help by calling an action, do so naturally.')
      ..writeln('Always be conversational and helpful.');

    return buffer.toString();
  }

  /// Send a message and stream the response
  Stream<String> sendMessageStream(
    ChatMessage message, {
    required Stream<String> Function(
            String enhancedPrompt, List<AiAction> availableActions)
        onAiResponseStream,
  }) async* {
    // Add user message first
    _chatController.addMessage(message);

    // Create enhanced prompt with context
    final enhancedPrompt = _createEnhancedPrompt(message.text);

    // Get available actions
    final availableActions = _actionController.registeredActions;

    // Create AI message placeholder with unique ID
    final messageId = DateTime.now().millisecondsSinceEpoch.toString();
    final aiMessage = ChatMessage(
      text: '',
      user: const ChatUser(id: 'ai', name: 'AI Assistant'),
      createdAt: DateTime.now(),
      isMarkdown: true,
      customProperties: {'id': messageId},
    );

    _chatController.addMessage(aiMessage);
    final buffer = StringBuffer();

    try {
      // Stream AI response
      await for (final chunk
          in onAiResponseStream(enhancedPrompt, availableActions)) {
        buffer.write(chunk);

        // Update the message with accumulated text
        final updatedMessage = aiMessage.copyWith(
          text: buffer.toString(),
          customProperties: {'id': messageId},
        );
        _chatController.updateMessage(updatedMessage);

        // Yield the chunk for external listeners
        yield chunk;
      }
    } catch (e) {
      // Update with error message
      final errorText = 'Sorry, I encountered an error: $e';
      final errorMessage = aiMessage.copyWith(
        text: errorText,
        customProperties: {'id': messageId},
      );
      _chatController.updateMessage(errorMessage);

      yield errorText;
    }
  }

  /// Add readable context (equivalent to useCopilotReadable)
  void addReadableContext(String key, String description, dynamic value) {
    _readableController.setReadable(key, description, value);
  }

  /// Remove readable context
  void removeReadableContext(String key) {
    _readableController.removeReadable(key);
  }

  /// Register an action (equivalent to useCopilotAction)
  void registerAction(AiAction action) {
    _actionController.registerAction(action);
  }

  /// Execute an action by name
  Future<ActionResult> executeAction(
      String actionName, Map<String, dynamic> parameters) {
    return _actionController.executeAction(actionName, parameters);
  }

  /// Get the current context summary for debugging
  String getContextSummary() {
    return _readableController.contextSummary;
  }

  /// Get all registered actions for debugging
  List<AiAction> getRegisteredActions() {
    return _actionController.registeredActions;
  }

  /// Clear all messages
  void clearMessages() {
    _chatController.clearMessages();
  }

  /// Clear all context
  void clearContext() {
    _readableController.clearAll();
  }

  /// Get all messages
  List<ChatMessage> get messages => _chatController.messages;

  /// Listen to message changes
  void addMessageListener(VoidCallback listener) {
    _chatController.addListener(listener);
  }

  /// Remove message listener
  void removeMessageListener(VoidCallback listener) {
    _chatController.removeListener(listener);
  }

  void _onContextChanged() {
    // Context has changed - we could notify AI or take other actions
    debugPrint(
        'Context updated: ${_readableController.contextKeys.length} items');
  }

  void _onActionsChanged() {
    // Actions have changed
    debugPrint(
        'Actions updated: ${_actionController.registeredActions.length} actions');
  }

  @override
  void dispose() {
    _readableController.removeListener(_onContextChanged);
    _actionController.removeListener(_onActionsChanged);
    super.dispose();
  }
}

/// Widget provider for context-aware chat functionality
/// Integrates all the essential CopilotKit-like features in one place
class ContextAwareChatProvider extends StatefulWidget {
  final Widget child;
  final ContextAwareChatController? controller;

  const ContextAwareChatProvider({
    super.key,
    required this.child,
    this.controller,
  });

  @override
  State<ContextAwareChatProvider> createState() =>
      _ContextAwareChatProviderState();
}

class _ContextAwareChatProviderState extends State<ContextAwareChatProvider> {
  late ContextAwareChatController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? ContextAwareChatController();
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _ContextAwareChatInheritedWidget(
      controller: _controller,
      child: ReadableContextProvider(
        controller: _controller.readableController,
        child: widget.child,
      ),
    );
  }
}

class _ContextAwareChatInheritedWidget extends InheritedWidget {
  final ContextAwareChatController controller;

  const _ContextAwareChatInheritedWidget({
    required this.controller,
    required super.child,
  });

  static ContextAwareChatController? of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_ContextAwareChatInheritedWidget>()
        ?.controller;
  }

  @override
  bool updateShouldNotify(_ContextAwareChatInheritedWidget oldWidget) {
    return controller != oldWidget.controller;
  }
}

/// Extension to easily access context-aware chat functionality
extension ContextAwareChatExtension on BuildContext {
  /// Get the context-aware chat controller from the widget tree
  ContextAwareChatController? get contextAwareChat {
    return _ContextAwareChatInheritedWidget.of(this);
  }
}

/// Mixin to easily add context-aware chat functionality to any widget
mixin ContextAwareChatMixin<T extends StatefulWidget> on State<T> {
  ContextAwareChatController? _contextAwareChatController;

  /// Get the context-aware chat controller
  ContextAwareChatController get contextAwareChat {
    return _contextAwareChatController ??=
        context.contextAwareChat ?? ContextAwareChatController();
  }

  /// Add readable context (equivalent to useCopilotReadable in React)
  void addReadableContext(String key, String description, dynamic value) {
    contextAwareChat.addReadableContext(key, description, value);
  }

  /// Register an action (equivalent to useCopilotAction in React)
  void registerAction(AiAction action) {
    contextAwareChat.registerAction(action);
  }
}
