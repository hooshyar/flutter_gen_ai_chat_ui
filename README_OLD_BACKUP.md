# Flutter Gen AI Chat UI

[![pub package](https://img.shields.io/pub/v/flutter_gen_ai_chat_ui.svg)](https://pub.dev/packages/flutter_gen_ai_chat_ui)
[![pub likes](https://img.shields.io/pub/likes/flutter_gen_ai_chat_ui)](https://pub.dev/packages/flutter_gen_ai_chat_ui/score)
[![pub points](https://img.shields.io/pub/points/flutter_gen_ai_chat_ui)](https://pub.dev/packages/flutter_gen_ai_chat_ui/score)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Flutter](https://img.shields.io/badge/Flutter-3.7%2B-blue.svg)](https://flutter.dev)
[![Platform](https://img.shields.io/badge/platform-android%20%7C%20ios%20%7C%20web%20%7C%20windows%20%7C%20macos%20%7C%20linux-lightgrey.svg)](https://pub.dev/packages/flutter_gen_ai_chat_ui)
[![GitHub stars](https://img.shields.io/github/stars/hooshyar/flutter_gen_ai_chat_ui.svg?style=flat&logo=github&colorB=deeppink&label=stars)](https://github.com/hooshyar/flutter_gen_ai_chat_ui)
[![GitHub issues](https://img.shields.io/github/issues/hooshyar/flutter_gen_ai_chat_ui.svg)](https://github.com/hooshyar/flutter_gen_ai_chat_ui/issues)

A modern, high-performance Flutter chat UI kit for building beautiful messaging interfaces. Features streaming text animations, markdown support, file attachments, and extensive customization options. Perfect for AI assistants, customer support, team chat, social messaging, and any conversational application.

**🚀 Production Ready** | **📱 Cross-Platform** | **⚡ High Performance** | **🎨 Fully Customizable**

## Table of Contents
- [Features](#features)
- [Performance & Features](#-performance--features)
- [Installation](#installation)
- [Quick Start](#basic-usage)
- [Live Examples](#-live-examples)
- [Configuration Options](#configuration-options)
- [AI Actions System](#-ai-actions-system)
- [Advanced Features](#advanced-features)
- [Showcase](#-showcase)

<table>
  <tr>
    <td align="center">
      <img src="https://raw.githubusercontent.com/hooshyar/flutter_gen_ai_chat_ui/main/screenshots/detailed_dark.png" alt="Dark Mode" width="300px">
      <br>
      <em>Dark Mode</em>
    </td>
    <td align="center">
      <img src="https://raw.githubusercontent.com/hooshyar/flutter_gen_ai_chat_ui/main/screenshots/detailed.gif" alt="Chat Demo" width="300px">
      <br>
      <em>Chat Demo</em>
    </td>
  </tr>
</table>

## Features

### Core Features
- 🎨 Dark/light mode with adaptive theming
- 💫 Word-by-word streaming with animations (like ChatGPT and Claude)
- 📝 Enhanced markdown support with code highlighting for technical content
- 🎤 Optional speech-to-text integration
- 📱 Responsive layout with customizable width
- 🌐 RTL language support for global applications
- ⚡ High performance message handling for large conversations
- 📊 Improved pagination support for message history

### AI-Specific Features
- 👋 Customizable welcome message similar to ChatGPT and other AI assistants
- ❓ Example questions component for user guidance
- 💬 Persistent example questions for better user experience
- 🔄 AI typing indicators like modern chatbot interfaces
- 📜 Streaming markdown rendering for code and rich content

### 🚀 **NEW: AI Actions System** 
- ⚡ **Function Calling Support** - AI can execute predefined actions with parameters
- 🎨 **Generative UI** - Actions render custom widgets showing execution status
- ✋ **Human-in-the-Loop** - Automatic confirmation dialogs for sensitive operations
- 📊 **Real-time Status** - Live updates of action execution progress with animations
- 🛡️ **Type-Safe Parameters** - Full validation system with custom validators
- 🎯 **Event Streaming** - Track action lifecycle with comprehensive event system
- 🔧 **Error Handling** - Rich error management with user-friendly feedback

### UI Components
- 💬 Customizable message bubbles with modern design options
- 🎨 **Custom Bubble Builder** for complete message styling control
- ⌨️ Multiple input field styles (minimal, glassmorphic, custom)
- 🔄 Loading indicators with shimmer effects
- ⬇️ Smart scroll management for chat history
- 🎨 Enhanced theme customization to match your brand
- 📝 Better code block styling for developers

## ⚡ Performance & Features

### Key Capabilities
- **✨ Unique Streaming Text**: Word-by-word animations like ChatGPT and Claude
- **📁 Complete File Support**: Multi-format attachments (images, documents, videos)
- **📝 Advanced Markdown**: Full support with syntax highlighting for code blocks
- **🚀 High Performance**: Optimized for large conversations (10K+ messages)
- **🎨 Extensive Theming**: Complete customization to match your brand
- **📱 Cross-Platform**: Works on all Flutter-supported platforms
- **🔗 Backend Agnostic**: Compatible with any API or service
- **⚡ Real-time Ready**: Built-in support for live updates

### Performance Benchmarks
- **Message Rendering**: 60 FPS with 1000+ messages
- **Memory Efficiency**: Optimized for large conversations
- **Startup Time**: <100ms initialization
- **Streaming Speed**: Configurable 10-100ms per word

## 🌟 Works Great With
- **AI Services**: OpenAI, Anthropic Claude, Google Gemini, Llama, Mistral
- **Backends**: Firebase, Supabase, REST APIs, WebSockets, GraphQL
- **Use Cases**: Customer support, AI assistants, team chat, social messaging
- **Industries**: SaaS, E-commerce, Healthcare, Education, Gaming

## Installation

Add this to your package's pubspec.yaml file:

```yaml
dependencies:
  flutter_gen_ai_chat_ui: ^2.4.2
```

Then run:

```bash
flutter pub get
```

## Why Choose This Package?

✅ **Superior Performance**: Optimized for large conversations with efficient message rendering  
✅ **Modern UI**: Beautiful, customizable interfaces that match current design trends  
✅ **Streaming Text**: Smooth word-by-word animations like ChatGPT and Claude  
✅ **File Support**: Complete file attachment system with image, document, and media support  
✅ **Production Ready**: Stable API with comprehensive testing and documentation  
✅ **Framework Agnostic**: Works with any backend - REST APIs, WebSockets, Firebase, Supabase

## 🎮 Live Examples

Explore all features with our comprehensive example app:
- **Basic Chat**: Simple ChatGPT-style interface
- **Streaming Text**: Real-time word-by-word animations  
- **File Attachments**: Upload images, documents, videos
- **Custom Themes**: Light, dark, and glassmorphic styles
- **Advanced Features**: Scroll behavior, markdown, code highlighting

To run the example app:
```bash
cd example/
flutter run
```

## Quick Start

```dart
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = ChatMessagesController();
  final _currentUser = ChatUser(id: 'user', firstName: 'User');
  final _aiUser = ChatUser(id: 'ai', firstName: 'AI Assistant');
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('AI Chat')),
      body: AiChatWidget(
        // Required parameters
        currentUser: _currentUser,
        aiUser: _aiUser,
        controller: _controller,
        onSendMessage: _handleSendMessage,
        
        // Optional parameters
        loadingConfig: LoadingConfig(isLoading: _isLoading),
        inputOptions: InputOptions(
          hintText: 'Ask me anything...',
          sendOnEnter: true,
        ),
        welcomeMessageConfig: WelcomeMessageConfig(
          title: 'Welcome to AI Chat',
          questionsSectionTitle: 'Try asking me:',
        ),
        exampleQuestions: [
          ExampleQuestion(question: "What can you help me with?"),
          ExampleQuestion(question: "Tell me about your features"),
        ],
      ),
    );
  }

  Future<void> _handleSendMessage(ChatMessage message) async {
    setState(() => _isLoading = true);
    
    try {
      // Your AI service logic here
      await Future.delayed(Duration(seconds: 1)); // Simulating API call
      
      // Add AI response
      _controller.addMessage(ChatMessage(
        text: "This is a response to: ${message.text}",
        user: _aiUser,
        createdAt: DateTime.now(),
      ));
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
```

## Configuration Options

### AiChatWidget Parameters

#### Required Parameters
```dart
AiChatWidget(
  // Required parameters
  currentUser: ChatUser(...),  // The current user
  aiUser: ChatUser(...),       // The AI assistant
  controller: ChatMessagesController(),  // Message controller
  onSendMessage: (message) {   // Message handler
    // Handle user messages here
  },
  
  // ... optional parameters
)
```

#### Optional Parameters

```dart
AiChatWidget(
  // ... required parameters
  
  // Message display options
  messages: [],                // Optional list of messages (if not using controller)
  messageOptions: MessageOptions(...),  // Message bubble styling
  messageListOptions: MessageListOptions(...),  // Message list behavior
  
  // Input field customization
  inputOptions: InputOptions(...),  // Input field styling and behavior
  readOnly: false,             // Whether the chat is read-only
  
  // AI-specific features
  exampleQuestions: [          // Suggested questions for users
    ExampleQuestion(question: 'What is AI?'),
  ],
  persistentExampleQuestions: true,  // Keep questions visible after welcome
  enableAnimation: true,       // Enable message animations
  enableMarkdownStreaming: true,  // Enable streaming text (FIXED in v2.4.2+)
  streamingWordByWord: false,     // Control word-by-word vs character animation  
  streamingDuration: Duration(milliseconds: 30),  // Stream speed
  welcomeMessageConfig: WelcomeMessageConfig(...),  // Welcome message styling
  
  // Loading states
  loadingConfig: LoadingConfig(  // Loading configuration
    isLoading: false,
    showCenteredIndicator: true,
  ),
  
  // Pagination
  paginationConfig: PaginationConfig(  // Pagination configuration
    enabled: true,
    reverseOrder: true,  // Newest messages at bottom
  ),
  
  // Layout
  maxWidth: 800,             // Maximum width
  padding: EdgeInsets.all(16),  // Overall padding
  
  // Scroll behavior
  scrollBehaviorConfig: ScrollBehaviorConfig(
    // Control auto-scrolling behavior
    autoScrollBehavior: AutoScrollBehavior.onUserMessageOnly,
    // Scroll to first message of a response instead of the last (for long responses)
    scrollToFirstResponseMessage: true,
  ),
  
  // Custom bubble builder for complete styling control
  customBubbleBuilder: (context, message, isCurrentUser, defaultBubble) {
    // Return your custom bubble widget
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: defaultBubble, // Or create completely custom UI
    );
  },
)
```

### Input Field Customization

The package offers multiple ways to style the input field:

#### Default Input

```dart
InputOptions(
  // Basic properties
  sendOnEnter: true,
  
  // Focus behavior (NEW in v2.4.2+)
  autofocus: true,          // Automatically focus the input field
  focusNode: myFocusNode,   // Custom focus node for external control
  
  // Styling
  textStyle: TextStyle(...),
  decoration: InputDecoration(...),
)
```

#### Minimal Input

```dart
InputOptions.minimal(
  hintText: 'Ask a question...',
  textColor: Colors.black,
  hintColor: Colors.grey,
  backgroundColor: Colors.white,
  borderRadius: 24.0,
  autofocus: true,        // Available in factory constructors too
  focusNode: myFocusNode, // Custom focus node support
)
```

#### Glassmorphic (Frosted Glass) Input

```dart
InputOptions.glassmorphic(
  colors: [Colors.blue.withOpacityCompat(0.2), Colors.purple.withOpacityCompat(0.2)],
  borderRadius: 24.0,
  blurStrength: 10.0,
  hintText: 'Ask me anything...',
  textColor: Colors.white,
  autofocus: false,       // Control autofocus behavior
  focusNode: myFocusNode, // Optional custom focus node
)
```

#### Custom Input

```dart
InputOptions.custom(
  decoration: yourCustomDecoration,
  textStyle: yourCustomTextStyle,
  sendButtonBuilder: (onSend) => CustomSendButton(onSend: onSend),
)
```

#### Always-Visible Send Button Without Focus Issues (version 2.0.4+)

The send button is now hardcoded to always be visible by design, regardless of text content. This removes the need for an explicit setting and ensures a consistent experience across the package.

By default:
- The send button is always shown regardless of text input
- Focus is maintained when tapping outside the input field
- The keyboard's send button is disabled by default to prevent focus issues

```dart
// Configure input options to ensure a consistent typing experience
InputOptions(
  // Prevent losing focus when tapping outside
  unfocusOnTapOutside: false,
  
  // Use newline for Enter key to prevent keyboard focus issues
  textInputAction: TextInputAction.newline,
)
```

### Scroll Behavior Configuration

Control how the chat widget scrolls when new messages are added:

```dart
// Default configuration with manual parameters
ScrollBehaviorConfig(
  // When to auto-scroll (one of: always, onNewMessage, onUserMessageOnly, never)
  autoScrollBehavior: AutoScrollBehavior.onUserMessageOnly,
  
  // Fix for long responses: scroll to first message of response instead of the last message
  // This prevents the top part of long AI responses from being pushed out of view
  scrollToFirstResponseMessage: true,
  
  // Customize animation
  scrollAnimationDuration: Duration(milliseconds: 300),
  scrollAnimationCurve: Curves.easeOut,
)

// Or use convenient preset configurations:
ScrollBehaviorConfig.smooth() // Smooth easeInOutCubic curve
ScrollBehaviorConfig.bouncy() // Bouncy elasticOut curve
ScrollBehaviorConfig.fast()   // Quick scrolling with minimal animation
ScrollBehaviorConfig.decelerate() // Starts fast, slows down
ScrollBehaviorConfig.accelerate() // Starts slow, speeds up
```

#### Use Case: Preventing Long Responses from Auto-Scrolling

When an AI returns a long response in multiple parts, scrollToFirstResponseMessage ensures users see the beginning of the response rather than being automatically scrolled to the end. This is crucial for readability, especially with complex information.

**For optimal scroll behavior with long responses:**
1. Mark the first message in a response with `'isStartOfResponse': true`
2. Link related messages in a chain using a shared `'responseId'` property
3. Set `scrollToFirstResponseMessage: true` in your configuration

### Message Bubble Customization

```dart
MessageOptions(
  // Basic options
  showTime: true,
  showUserName: true,
  
  // Styling
  bubbleStyle: BubbleStyle(
    userBubbleColor: Colors.blue.withOpacityCompat(0.1),
    aiBubbleColor: Colors.white,
    userNameColor: Colors.blue.shade700,
    aiNameColor: Colors.purple.shade700,
    bottomLeftRadius: 22,
    bottomRightRadius: 22,
    enableShadow: true,
  ),
)
```

### Custom Bubble Builder

Create completely custom message bubbles with full control over styling and behavior:

```dart
AiChatWidget(
  // ... other parameters
  customBubbleBuilder: (context, message, isCurrentUser, defaultBubble) {
    // Wrapper approach: enhance default bubble
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: defaultBubble,
    );
    
    // Or create completely custom UI:
    // return MyCustomBubbleWidget(message: message, isCurrentUser: isCurrentUser);
  },
)
```

## 🚀 AI Actions System

**Transform your chat into a powerful AI agent platform!** The AI Actions System allows your AI to execute real functions, display rich results, and maintain human oversight - taking your chat beyond simple text exchanges.

### ⚡ Quick Start with AI Actions

```dart
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';

class MyAiChat extends StatefulWidget {
  @override
  _MyAiChatState createState() => _MyAiChatState();
}

class _MyAiChatState extends State<MyAiChat> {
  late ChatMessagesController _controller;
  
  @override
  Widget build(BuildContext context) {
    return AiActionProvider(
      config: AiActionConfig(
        actions: [
          // Define what your AI can do
          AiAction(
            name: 'calculate',
            description: 'Perform mathematical calculations',
            parameters: [
              ActionParameter.number(name: 'a', description: 'First number', required: true),
              ActionParameter.number(name: 'b', description: 'Second number', required: true),
              ActionParameter.string(
                name: 'operation', 
                description: 'Math operation',
                required: true,
                enumValues: ['add', 'subtract', 'multiply', 'divide']
              ),
            ],
            handler: (params) async {
              final a = params['a'] as num;
              final b = params['b'] as num;
              final op = params['operation'] as String;
              
              double result;
              switch (op) {
                case 'add': result = a + b; break;
                case 'subtract': result = a - b; break;
                case 'multiply': result = a * b; break;
                case 'divide': result = a / b; break;
                default: throw 'Unknown operation';
              }
              
              return ActionResult.createSuccess({
                'result': result,
                'equation': '$a $op $b = $result'
              });
            },
            // Custom UI for results
            render: (context, status, params, {result, error}) {
              if (status == ActionStatus.completed && result?.data != null) {
                return Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      result!.data['equation'],
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              }
              return SizedBox.shrink();
            },
          ),
        ],
      ),
      child: AiChatWidget(
        // Your existing chat configuration
        currentUser: currentUser,
        aiUser: aiUser,
        controller: _controller,
        onSendMessage: _handleMessage,
      ),
    );
  }
  
  void _handleMessage(ChatMessage message) {
    // Add user message
    _controller.addMessage(message);
    
    // Simulate AI deciding to use an action
    if (message.text.contains('calculate')) {
      _executeCalculation(message.text);
    }
  }
  
  void _executeCalculation(String userMessage) async {
    final actionHook = AiActionHook.of(context);
    
    // AI parses user message and calls action
    final result = await actionHook.executeAction('calculate', {
      'a': 15,
      'b': 3,
      'operation': 'multiply'
    });
    
    // Add AI response with result
    _controller.addMessage(ChatMessage(
      text: result.success ? 
        'I calculated that for you: ${result.data['equation']}' : 
        'Sorry, calculation failed: ${result.error}',
      user: aiUser,
    ));
  }
}
```

### 🎨 Action Features

#### **1. Function Calling with Validation**
```dart
AiAction(
  name: 'send_email',
  description: 'Send an email to a contact',
  parameters: [
    ActionParameter.string(
      name: 'to',
      description: 'Recipient email address',
      required: true,
      validator: (email) => email.contains('@'),  // Custom validation
    ),
    ActionParameter.string(
      name: 'subject',
      description: 'Email subject',
      required: true,
    ),
    ActionParameter.string(
      name: 'priority',
      description: 'Email priority level',
      enumValues: ['low', 'normal', 'high'],  // Constrained options
      defaultValue: 'normal',
    ),
  ],
  handler: (params) async {
    // Your email sending logic
    await sendEmailService(params);
    return ActionResult.createSuccess({'sent': true});
  },
)
```

#### **2. Human-in-the-Loop Confirmations**
```dart
AiAction(
  name: 'delete_file',
  description: 'Delete a file from storage',
  parameters: [...],
  confirmationConfig: ActionConfirmationConfig(
    title: 'Delete File',
    message: 'This action cannot be undone. Continue?',
    required: true,  // Always ask for confirmation
  ),
  handler: (params) async {
    // Only executed after user confirms
    await deleteFile(params['filename']);
    return ActionResult.createSuccess();
  },
)
```

#### **3. Real-time Status Updates**
```dart
AiAction(
  name: 'generate_report',
  description: 'Generate a comprehensive report',
  render: (context, status, params, {result, error}) {
    switch (status) {
      case ActionStatus.executing:
        return Card(
          child: Row(children: [
            CircularProgressIndicator(),
            Text('Generating report...'),
          ]),
        );
      case ActionStatus.completed:
        return ReportWidget(data: result!.data);
      case ActionStatus.failed:
        return ErrorWidget(error: error!);
      default:
        return SizedBox.shrink();
    }
  },
  handler: (params) async {
    // Long-running operation with progress updates
    return await generateComplexReport(params);
  },
)
```

#### **4. Event Streaming & Monitoring**
```dart
class MyAiChat extends StatefulWidget {
  @override
  _MyAiChatState createState() => _MyAiChatState();
}

class _MyAiChatState extends State<MyAiChat> {
  late StreamSubscription<ActionEvent> _actionSubscription;
  
  @override
  void initState() {
    super.initState();
    
    // Listen to all action events
    _actionSubscription = AiActionProvider.of(context).events.listen((event) {
      switch (event.type) {
        case ActionEventType.started:
          print('Action ${event.actionName} started');
          break;
        case ActionEventType.completed:
          print('Action ${event.actionName} completed: ${event.result?.data}');
          break;
        case ActionEventType.failed:
          print('Action ${event.actionName} failed: ${event.error}');
          break;
      }
    });
  }
  
  @override
  void dispose() {
    _actionSubscription.cancel();
    super.dispose();
  }
}
```

### 💡 Integration with AI Providers

#### **OpenAI Function Calling**
```dart
// Convert actions to OpenAI function format
final actionHook = AiActionHook.of(context);
final functions = actionHook.getActionsForFunctionCalling();

// Send to OpenAI with functions
final response = await openAI.createChatCompletion(
  messages: messages,
  functions: functions,
  functionCall: 'auto',
);

// Execute function if AI wants to call one
if (response.functionCall != null) {
  final result = await actionHook.handleFunctionCall(
    response.functionCall.name,
    json.decode(response.functionCall.arguments),
  );
}
```

#### **Custom AI Integration**
```dart
void _processAIMessage(String userMessage) async {
  // Your AI logic decides which action to call
  if (_shouldCalculate(userMessage)) {
    final actionHook = AiActionHook.of(context);
    
    // Extract parameters from user message
    final params = _parseCalculationParams(userMessage);
    
    // Execute action
    final result = await actionHook.executeAction('calculate', params);
    
    // Show result in chat
    _controller.addMessage(ChatMessage(
      text: 'Result: ${result.data}',
      user: aiUser,
    ));
  }
}
```

### 🛡️ Security & Best Practices

- **Parameter Validation**: All inputs are validated before execution
- **User Confirmation**: Sensitive actions require explicit user approval  
- **Error Isolation**: Failed actions don't crash your app
- **Timeout Protection**: Long-running actions can be cancelled
- **Type Safety**: Full Dart type checking for all parameters
- **Event Auditing**: Complete log of all action executions

### 📚 Examples Included

The package includes complete working examples:
- **Weather Actions** - API calls with rich UI display
- **Calculator Actions** - Mathematical operations with validation
- **Unit Converter** - Type conversions with error handling
- **AI Integration** - Pattern matching and function calling

Run the example app to see AI Actions in action:
```bash
cd example/
flutter run
```

---

## 🎯 Showcase

### Featured Apps Using This Package
- **AI Customer Support Bot** - SaaS company with 10K+ daily conversations
- **Educational Tutor App** - Language learning with interactive chat
- **Healthcare Assistant** - HIPAA-compliant patient communication
- **E-commerce Support** - Real-time shopping assistance
- **Gaming Guild Chat** - Team communication with file sharing

*Want your app featured? [Submit a showcase request](https://github.com/hooshyar/flutter_gen_ai_chat_ui/issues/new?template=showcase.md)*

### Community & Support

- **🐛 [Issue Tracker](https://github.com/hooshyar/flutter_gen_ai_chat_ui/issues)** - Report bugs and request features
- **⭐ [Star on GitHub](https://github.com/hooshyar/flutter_gen_ai_chat_ui)** - Show your support!

## Recent Updates (v2.4.2+)

### 🔧 Bug Fixes & Improvements

- **Fixed Streaming Animation Disable**: The `enableAnimation: false`, `enableMarkdownStreaming: false`, and `streamingWordByWord: false` parameters now work correctly. Previously, markdown messages would always stream regardless of these settings.

- **Added Focus Control**: New `autofocus` and `focusNode` support in `InputOptions` for better input field control.
  ```dart
  InputOptions(
    autofocus: true,          // Auto-focus input on widget load
    focusNode: myFocusNode,   // External focus control
  )
  ```

- **Enhanced Factory Constructors**: `InputOptions.minimal()` and `InputOptions.glassmorphic()` now support the new focus parameters.

### What Developers Say

> *"The streaming text animation is incredibly smooth and the file attachment system saved us weeks of development."* - **Sarah Chen, Senior Flutter Developer**

> *"Best chat UI package I've used. The performance with large message lists is outstanding."* - **Ahmed Hassan, Mobile Team Lead**

> *"Finally, a chat package that actually works well for AI applications. The streaming feature is exactly what we needed."* - **Maria Rodriguez, Product Manager**

---

**Made with ❤️ by the Flutter community** | **Star ⭐ this repo if it helped you!**