/// AI integrations for flutter_gen_ai_chat_ui.
///
/// This library provides built-in integrations with popular AI providers.
///
/// ## OpenAI Integration
///
/// ```dart
/// import 'package:flutter_gen_ai_chat_ui/integrations.dart';
///
/// OpenAIChatWidget(
///   apiKey: const String.fromEnvironment('OPENAI_API_KEY'),
///   currentUser: ChatUser(id: 'user', firstName: 'You'),
/// )
/// ```
///
/// ## Security Warning
///
/// ⚠️ **NEVER hardcode API keys in your source code!**
///
/// ✅ Use environment variables:
/// ```dart
/// apiKey: const String.fromEnvironment('OPENAI_API_KEY')
/// ```
///
/// ✅ Or fetch from secure backend:
/// ```dart
/// final apiKey = await yourBackend.getSecureToken();
/// ```
///
/// See documentation for security best practices.
library flutter_gen_ai_chat_ui_integrations;

// Base interfaces
export 'src/integrations/base/ai_provider.dart';
export 'src/integrations/base/ai_config.dart';

// OpenAI integration
export 'src/integrations/openai/openai_provider.dart';
export 'src/integrations/openai/openai_config.dart';
export 'src/integrations/openai/openai_chat_widget.dart';

// Re-export core chat models for convenience
export 'src/models/chat/models.dart';
export 'src/models/example_question.dart';
export 'src/controllers/chat_messages_controller.dart';
