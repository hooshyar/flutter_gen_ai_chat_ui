import 'package:flutter/material.dart';
import 'package:flutter_gen_ai_chat_ui/integrations.dart';

/// Simple ChatGPT clone example using OpenAI integration.
///
/// This example demonstrates:
/// - How to use OpenAIChatWidget
/// - Proper API key handling with environment variables
/// - Configuring the AI model and behavior
/// - Adding welcome message and example questions
///
/// ## Running this example:
///
/// 1. Get your OpenAI API key from https://platform.openai.com/api-keys
///
/// 2. Run with environment variable:
///    ```
///    flutter run --dart-define=OPENAI_API_KEY=your_key_here
///    ```
///
/// 3. Or set in your IDE:
///    - VS Code: Add to launch.json
///    - Android Studio: Edit Configurations > Additional Run Args
///
/// ⚠️ **NEVER** hardcode your API key in the source code!
class ChatGPTCloneScreen extends StatelessWidget {
  const ChatGPTCloneScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // ✅ CORRECT: Get API key from environment variable
    const apiKey = String.fromEnvironment('OPENAI_API_KEY');

    // Check if API key is provided
    if (apiKey.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('ChatGPT Clone'),
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 64,
                  color: Colors.orange,
                ),
                SizedBox(height: 24),
                Text(
                  'OpenAI API Key Required',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Please run the app with your OpenAI API key:',
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                SelectableText(
                  'flutter run --dart-define=OPENAI_API_KEY=your_key_here',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
                SizedBox(height: 24),
                Text(
                  'Get your API key from:',
                  textAlign: TextAlign.center,
                ),
                SelectableText(
                  'https://platform.openai.com/api-keys',
                  style: TextStyle(
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('ChatGPT Clone'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'About',
            onPressed: () => _showAboutDialog(context),
          ),
        ],
      ),
      body: OpenAIChatWidget(
        // ✅ Securely pass API key from environment
        apiKey: apiKey,

        // Configure OpenAI model
        model: 'gpt-3.5-turbo', // or 'gpt-4-turbo' for better responses

        // Current user
        currentUser: const ChatUser(
          id: 'user',
          firstName: 'You',
        ),

        // Optional: Customize AI behavior with system prompt
        systemPrompt: 'You are a helpful assistant. '
            'You provide clear, concise, and friendly responses.',

        // Optional: Control randomness (0.0 = focused, 2.0 = creative)
        temperature: 0.7,

        // Optional: Track token usage
        showTokenUsage: true, // Prints to console
        onTokensUsed: (tokens, cost) {
          debugPrint('💰 Used $tokens tokens (≈\$${cost.toStringAsFixed(4)})');
        },

        // Optional: Add welcome message
        welcomeMessage: 'Hello! I\'m your AI assistant. How can I help you today?',

        // Optional: Add example questions
        exampleQuestions: const [
          ExampleQuestion(
            question: 'What is Flutter?',
          ),
          ExampleQuestion(
            question: 'Explain state management in Flutter',
          ),
          ExampleQuestion(
            question: 'How do I create a custom widget?',
          ),
          ExampleQuestion(
            question: 'What are the best practices for Flutter development?',
          ),
        ],

        // Optional: Handle errors
        onError: (error) {
          debugPrint('❌ Error: $error');
          // You could also show a SnackBar or error dialog here
        },
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About ChatGPT Clone'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This is a simple example of using OpenAIChatWidget '
              'from flutter_gen_ai_chat_ui package.',
            ),
            SizedBox(height: 16),
            Text(
              'Features:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('✅ Streaming responses'),
            Text('✅ Markdown support'),
            Text('✅ Token usage tracking'),
            Text('✅ Secure API key handling'),
            Text('✅ Conversation history'),
            SizedBox(height: 16),
            Text(
              '⚠️ Remember: Never hardcode your API key!',
              style: TextStyle(color: Colors.orange),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

/// Example with advanced configuration
class AdvancedChatGPTClone extends StatelessWidget {
  const AdvancedChatGPTClone({super.key});

  @override
  Widget build(BuildContext context) {
    const apiKey = String.fromEnvironment('OPENAI_API_KEY');

    if (apiKey.isEmpty) {
      return const Scaffold(
        body: Center(
          child: Text('API key required'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Advanced ChatGPT')),
      body: OpenAIChatWidget(
        apiKey: apiKey,
        model: 'gpt-4-turbo', // Using GPT-4 for better responses

        currentUser: const ChatUser(
          id: 'user',
          firstName: 'Developer',
        ),

        // Custom AI user
        aiUser: const ChatUser(
          id: 'gpt4',
          firstName: 'GPT-4',
          avatar: 'https://ui-avatars.com/api/?name=GPT-4&background=10a37f&color=fff',
        ),

        // Detailed system prompt
        systemPrompt: '''You are an expert Flutter developer assistant.
Your responses should be:
- Technical and accurate
- Include code examples when relevant
- Reference official Flutter documentation
- Explain concepts clearly for both beginners and advanced users
- Use markdown formatting for better readability''',

        // More focused responses (less random)
        temperature: 0.3,

        // Limit response length
        maxTokens: 1000,

        // Track costs
        showTokenUsage: true,
        onTokensUsed: (tokens, cost) {
          // In a real app, you might save this to analytics
          debugPrint('Session cost: \$${cost.toStringAsFixed(4)}');
        },

        welcomeMessage: '''# Welcome to Flutter AI Assistant! 🚀

I'm powered by GPT-4 and specialize in Flutter development.

**I can help you with:**
- Widget composition and best practices
- State management solutions
- Performance optimization
- Platform-specific features
- Debugging and troubleshooting

**Just ask me anything!**''',

        exampleQuestions: const [
          ExampleQuestion(
            question: 'Show me how to create a custom animated button',
          ),
          ExampleQuestion(
            question: 'What\'s the difference between StatefulWidget and StatelessWidget?',
          ),
          ExampleQuestion(
            question: 'How do I optimize my Flutter app performance?',
          ),
          ExampleQuestion(
            question: 'Explain BLoC pattern with a simple example',
          ),
        ],
      ),
    );
  }
}
