import 'package:flutter/material.dart';
import '../models/chat/chat_message.dart';
import '../models/chat/chat_user.dart';

/// Manages chat message state and notifies listeners of changes.
class ChatProvider with ChangeNotifier {
  ChatProvider() {
    _createNewSession();
  }
  final List<ChatMessage> _messages = [];
  final ChatUser _user = const ChatUser(
    id: '1',
    name: 'User',
    avatar: 'https://ui-avatars.com/api/?name=User',
  );
  final ChatUser _aiUser = const ChatUser(
    id: '2',
    name: 'AI',
    avatar: 'https://ui-avatars.com/api/?name=AI&background=10A37F&color=fff',
  );
  bool _showWelcomeMessage = true;
  String _currentSessionId = '';

  List<ChatMessage> get messages => _messages;
  bool get showWelcomeMessage => _showWelcomeMessage;
  String get currentSessionId => _currentSessionId;

  void _createNewSession() {
    _currentSessionId = DateTime.now().millisecondsSinceEpoch.toString();
  }

  ChatMessage _createMessage({
    required final ChatUser user,
    required final String text,
    final String? sessionId,
  }) =>
      ChatMessage(
        user: user,
        text: text,
        createdAt: DateTime.now(),
        customProperties: {
          'sessionId': sessionId ?? _currentSessionId,
        },
      );

  void handleExampleQuestionTap(final String question) {
    final message = _createMessage(
      user: _user,
      text: question,
    );
    _messages.insert(0, message);
    _showWelcomeMessage = false;
    notifyListeners();
  }

  Future<void> handleSend(
    final ChatMessage message,
    final Future<String> Function(String) onAiResponse,
  ) async {
    final userMessage = _createMessage(
      user: _user,
      text: message.text,
    );
    _messages.insert(0, userMessage);
    _showWelcomeMessage = false;
    notifyListeners();

    try {
      final aiResponse = await onAiResponse(message.text);
      _messages.insert(
        0,
        _createMessage(
          user: _aiUser,
          text: aiResponse,
        ),
      );
      notifyListeners();
    } on Exception {
      // Handle error
    }
  }

  Future<void> handleExampleQuestionTapWithResponse(
    final String question,
    final Future<String> Function(String) onAiResponse,
  ) async {
    final userMessage = _createMessage(
      user: _user,
      text: question,
    );
    _messages.insert(0, userMessage);
    _showWelcomeMessage = false;
    notifyListeners();

    try {
      final aiResponse = await onAiResponse(question);
      _messages.insert(
        0,
        _createMessage(
          user: _aiUser,
          text: aiResponse,
        ),
      );
      notifyListeners();
    } on Exception {
      // Handle error
    }
  }

  List<ChatMessage> getMessagesForSession(final String sessionId) => _messages
      .where((final msg) => msg.customProperties?['sessionId'] == sessionId)
      .toList();

  void startNewSession() {
    _createNewSession();
    notifyListeners();
  }
}
