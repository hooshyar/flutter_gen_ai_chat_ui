# Flutter Gen AI Chat UI Usage Guide

This document provides a comprehensive guide to using the Flutter Gen AI Chat UI package. We'll cover the key components, their properties, and how to implement common AI chat scenarios.

## Table of Contents
- [Basic Setup](#basic-setup)
- [Core Components](#core-components)
- [Styling & Customization](#styling--customization)
- [Advanced Features](#advanced-features)
- [Best Practices](#best-practices)
- [Proper Text Streaming Usage](#proper-text-streaming-usage)
- [Bottom Action Bar (ChatGPT‑Style)](#bottom-action-bar-chatgpt-style)

## Basic Setup

### Step 1: Add Dependency

```yaml
dependencies:
  flutter_gen_ai_chat_ui: ^2.0.4
```

### Step 2: Import the Package

```dart
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';
```

### Step 3: Create a Basic Implementation

```dart
class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _chatController = ChatMessagesController();
  final _currentUser = ChatUser(id: 'user1', firstName: 'User');
  final _aiUser = ChatUser(id: 'ai1', firstName: 'AI Assistant');
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('AI Chat')),
      body: AiChatWidget(
        // Required parameters
        currentUser: _currentUser,
        aiUser: _aiUser,
        controller: _chatController,
        onSendMessage: _handleSendMessage,
        
        // Optional parameters
        loadingConfig: LoadingConfig(
          isLoading: _isLoading,
        ),
      ),
    );
  }

  void _handleSendMessage(ChatMessage message) async {
    setState(() => _isLoading = true);
    
    // Process the message and generate AI response
    await Future.delayed(Duration(seconds: 1)); // Simulate API call
    
    // Add AI response
    _chatController.addMessage(
      ChatMessage(
        text: "This is a response to: ${message.text}",
        user: _aiUser,
        createdAt: DateTime.now(),
      ),
    );
    
    setState(() => _isLoading = false);
  }
}
```

## Core Components

### ChatUser

Represents a user in the conversation:

```dart
ChatUser(
  id: 'user123',            // Required unique identifier
  firstName: 'John',        // User's name (required)
  lastName: 'Doe',          // Optional last name
  avatarUrl: 'url/to/img',  // Optional avatar image URL
)
```

### ChatMessage

Represents a message in the conversation:

```dart
ChatMessage(
  user: ChatUser(...),         // User who sent the message
  text: 'Hello world',         // Message content
  createdAt: DateTime.now(),   // Creation timestamp
  isMarkdown: true,            // Whether to render markdown
  media: ChatMedia(...),       // Optional media attachment
  quickReplies: [],            // Optional quick reply options
  customProperties: {},        // Optional custom data
)
```

### ChatMessagesController

Manages the state of the chat messages:

```dart
// Initialize controller
final controller = ChatMessagesController();

// Add a message
controller.addMessage(ChatMessage(...));

// Add multiple messages
controller.addMessages([ChatMessage(...), ChatMessage(...)]);

// Update a message (useful for streaming)
controller.updateMessage(message.copyWith(text: newText));

// Clear all messages
controller.clearMessages();

// Hide the welcome message
controller.hideWelcomeMessage();

// Scroll to bottom
controller.scrollToBottom();

// Load more messages (for pagination)
controller.loadMore(() async {
  // Return older messages
  return await fetchOlderMessages();
});
```

## Styling & Customization

### Input Field Options

```dart
// Default configuration
InputOptions(
  sendOnEnter: true,
  textStyle: TextStyle(...),
  decoration: InputDecoration(...),
)

// Add keyboard "Send" button
InputOptions(
  // Show a "Send" button on the keyboard
  textInputAction: TextInputAction.send,
  
  // Handle message sending when keyboard send button is pressed
  onSubmitted: (text) {
    // Create and send your message here
    // You can also clear the input and hide the keyboard
  },
  
  // Control when the keyboard should hide
  unfocusOnTapOutside: false, // Prevent keyboard from hiding when tapping outside
)

// Completely remove all containers
InputOptions(
  // Remove the outer container
  useOuterContainer: false,
  
  // Also remove the Material widget
  useOuterMaterial: false,
  
  // Use decoration on the TextField itself for styling
  decoration: InputDecoration(
    filled: true,
    fillColor: Colors.white.withOpacity(0.7),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(28),
      borderSide: BorderSide.none,
    ),
    contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
  ),
)

// Minimal style
InputOptions.minimal(
  hintText: 'Ask a question...',
  textColor: Colors.black,
  hintColor: Colors.grey,
  backgroundColor: Colors.white,
  borderRadius: 24.0,
)

// Glassmorphic (frosted glass) style
InputOptions.glassmorphic(
  colors: [Colors.blue.withOpacity(0.2), Colors.purple.withOpacity(0.2)],
  borderRadius: 24.0,
  blurStrength: 10.0,
  hintText: 'Ask me anything...',
  textColor: Colors.white,
)

// Custom style
InputOptions.custom(
  decoration: yourCustomDecoration,
  textStyle: yourCustomTextStyle,
  sendButtonBuilder: (onSend) => YourCustomButton(onSend: onSend),
)
```

### Message Options

```dart
MessageOptions(
  // Basic options
  showTime: true,
  showUserName: true,
  
  // Bubble style
  bubbleStyle: BubbleStyle(
    userBubbleColor: Colors.blue.withOpacity(0.1),
    aiBubbleColor: Colors.white,
    userNameColor: Colors.blue.shade700,
    aiNameColor: Colors.purple.shade700,
    bottomLeftRadius: 22,
    bottomRightRadius: 22,
    enableShadow: true,
  ),
)
```

### Loading Configuration

```dart
LoadingConfig(
  isLoading: true,              // Whether AI is generating a response
  loadingIndicator: YourCustomLoadingWidget(),   // Custom loading indicator
  typingIndicatorColor: Colors.blue,             // Color for typing animation
  showCenteredIndicator: false,                  // Center or show as typing
)
```

### Loading Indicators

The chat UI provides two types of loading indicators to let users know when the AI is generating a response:

#### 1. Typing Indicator (Default)

When `showCenteredIndicator: false` (default), the loading indicator appears as a typing bubble at the bottom of the chat, above the input field:

```dart
AiChatWidget(
  // Required parameters...
  loadingConfig: LoadingConfig(
    isLoading: _isLoading,
    showCenteredIndicator: false,  // Default behavior
    loadingIndicator: const LoadingWidget(
      texts: [
        'AI is thinking...',
        'Generating response...',
        'Almost there...'
      ],
    ),
  ),
)
```

This creates a natural conversational flow where the AI appears to be typing at the bottom of the chat, exactly where its message will appear.

#### 2. Centered Indicator

When `showCenteredIndicator: true`, the loading indicator appears centered in the chat area:

```dart
AiChatWidget(
  // Required parameters...
  loadingConfig: LoadingConfig(
    isLoading: _isLoading,
    showCenteredIndicator: true,  // Centered overlay
    loadingIndicator: CircularProgressIndicator(),
  ),
)
```

#### Using the Built-in LoadingWidget

The package includes a built-in `LoadingWidget` with extensive customization options. By default, it displays just text with a shimmer effect for a clean, minimal appearance:

```dart
// Default appearance - just text with shimmer effect
AiChatWidget(
  // Required parameters...
  loadingConfig: LoadingConfig(
    isLoading: _isLoading,
    loadingIndicator: LoadingWidget(
      texts: ['AI is thinking...', 'Generating response...', 'Almost there...'],
    ),
  ),
)
```

The widget automatically respects the current locale's text direction (RTL or LTR), aligning text appropriately without any additional configuration.

You can customize the basic text appearance:

```dart
// Basic text customization
AiChatWidget(
  // Required parameters...
  loadingConfig: LoadingConfig(
    isLoading: _isLoading,
    loadingIndicator: LoadingWidget(
      // Text messages to cycle through
      texts: ['Processing...', 'Analyzing data...'],
      
      // How often to rotate text
      interval: Duration(seconds: 1.5),
      
      // Customize text style
      textStyle: TextStyle(
        fontSize: 15, 
        fontWeight: FontWeight.w500,
        letterSpacing: 0.2,
      ),
      
      // Customize shimmer colors
      shimmerBaseColor: Colors.grey.shade300,
      shimmerHighlightColor: Colors.white,
    ),
  ),
)
```

##### Advanced LoadingWidget Styling

When you need more sophisticated designs, the `LoadingWidget` supports advanced styling options:

```dart
// Styling with background and borders
LoadingWidget(
  texts: ['Processing...', 'Analyzing data...'],
  backgroundColor: Colors.indigo.shade50,
  borderRadius: BorderRadius.circular(12),
  border: Border.all(color: Colors.indigo.shade200, width: 1.5),
  boxShadow: [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ],
  margin: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
  width: 280,
  minHeight: 60,
),

// Gradient background
LoadingWidget(
  texts: ['Thinking...', 'Almost ready...'],
  gradientColors: [Colors.blue.shade100, Colors.purple.shade100],
  gradientType: GradientType.linear, // linear, radial, or sweep
  gradientAngle: 45, // degrees (0-360)
  textStyle: TextStyle(
    fontSize: 16,
    color: Colors.indigo.shade800,
    fontWeight: FontWeight.w600,
  ),
),

// Glassmorphic effect
LoadingWidget(
  texts: ['AI is generating...', 'Creating response...'],
  isGlassmorphic: true,
  blurStrength: 8,
  glassmorphicOpacity: 0.12,
  borderRadius: BorderRadius.circular(24),
  textStyle: TextStyle(
    fontSize: 16,
    color: Colors.white,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.3,
  ),
),

// Material elevation
LoadingWidget(
  texts: ['Working on it...'],
  elevation: 3, // Add shadow using Material elevation
  backgroundColor: Colors.white,
  borderRadius: BorderRadius.circular(30),
  padding: EdgeInsets.symmetric(vertical: 16, horizontal: 32),
),

// Direct BoxDecoration for complete control
LoadingWidget(
  texts: ['Searching...'],
  containerDecoration: BoxDecoration(
    gradient: LinearGradient(
      colors: [Colors.teal.shade300, Colors.blue.shade400],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.circular(24),
    boxShadow: [
      BoxShadow(
        color: Colors.blue.shade100.withOpacity(0.4),
        blurRadius: 12,
        spreadRadius: 2,
        offset: Offset(0, 4),
      ),
    ],
  ),
  textStyle: TextStyle(
    fontSize: 16,
    color: Colors.white,
    fontWeight: FontWeight.bold,
  ),
),

// Override automatic text direction alignment
LoadingWidget(
  texts: ['Processing...'],
  alignment: Alignment.center, // Force centered text regardless of locale
),
```

##### Dark Mode Support

The `LoadingWidget` automatically adapts to light and dark themes, but you can provide custom styling for different themes:

```dart
final isDarkMode = Theme.of(context).brightness == Brightness.dark;

LoadingWidget(
  texts: ['Processing...'],
  backgroundColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
  border: Border.all(
    color: isDarkMode 
      ? Colors.grey.shade700 
      : Colors.grey.shade300,
  ),
  textStyle: TextStyle(
    color: isDarkMode ? Colors.white : Colors.black87,
  ),
),
```

#### Best Practices for Loading Indicators

1. **Positioning**: Use the typing indicator (default) for a more conversational feel. It shows where the AI's response will appear.

2. **State Management**: Set `isLoading = true` before starting API calls and `isLoading = false` when complete:

   ```dart
   // Example implementation in message handler
   Future<void> _handleSendMessage(ChatMessage message) async {
     setState(() => _isLoading = true);  // Show loading indicator
     
     try {
       // Process message and get AI response
       final response = await yourAiService.getResponse(message.text);
       
       // Add AI response to chat
       _chatController.addMessage(ChatMessage(
         text: response,
         user: _aiUser,
         createdAt: DateTime.now(),
       ));
     } finally {
       setState(() => _isLoading = false);  // Hide loading indicator
     }
   }
   ```

3. **Progressive Loading**: For streaming responses, you can use an empty message first to maintain context:

   ```dart
   // First add an empty message
   final aiMessage = ChatMessage(
     text: "",
     user: _aiUser,
     createdAt: DateTime.now(),
   );
   _chatController.addMessage(aiMessage);
   
   // Then update it as words arrive
   await for (final responseChunk in aiStreamResponse) {
     _chatController.updateMessage(aiMessage.copyWith(
       text: responseChunk,
     ));
   }
   ```

4. **Custom Styling**: To make your loading indicators stand out, customize their appearance based on your app's theme.

### Welcome Message Configuration

The welcome message is disabled by default and only appears when you provide a configuration:

```dart
WelcomeMessageConfig(
  title: "Welcome to My AI Assistant",
  containerPadding: EdgeInsets.all(24),
  questionsSectionTitle: "Try asking me:",
)
```

To use the welcome message:

```dart
// The welcome message will appear when either config or example questions are provided:
AiChatWidget(
  // ... other required parameters
  welcomeMessageConfig: welcomeConfig,  // Providing this enables the welcome message
  exampleQuestions: [                   // Adding questions also enables the welcome message
    ExampleQuestion(question: "What can you help me with?"),
  ],
)

// To explicitly disable the welcome message (even with config or questions):
controller.showWelcomeMessage = false;
```

## Advanced Features

### Streaming Text Response

Enable word-by-word streaming of AI responses:

```dart
AiChatWidget(
  // Required parameters...
  enableMarkdownStreaming: true,
  streamingDuration: Duration(milliseconds: 30),
)

// In your onSendMessage handler:
void _handleSendMessage(ChatMessage message) async {
  // Create an empty message
  final aiMessage = ChatMessage(
    text: "",
    user: _aiUser,
    createdAt: DateTime.now(),
    isMarkdown: true,
  );
  
  // Add to chat
  _chatController.addMessage(aiMessage);
  
  // Stream response word by word
  String fullResponse = "This is a **markdown** response with `code blocks` and more...";
  String accumulating = "";
  
  for (final word in fullResponse.split(" ")) {
    await Future.delayed(Duration(milliseconds: 100));
    accumulating += (accumulating.isEmpty ? "" : " ") + word;
    
    // Update the message text
    _chatController.updateMessage(
      aiMessage.copyWith(text: accumulating),
    );
  }
}
```

### Markdown Support

The package provides rich markdown support with code highlighting:

```dart
// Create a message with markdown
ChatMessage(
  text: """
# Heading
**Bold text** and *italic text*
- List item 1
- List item 2

```dart
void main() {
  print('Hello World!');
}
```
  """,
  user: _aiUser,
  createdAt: DateTime.now(),
  isMarkdown: true,
)
```

### Pagination for Large Message Histories

```dart
AiChatWidget(
  // Required parameters...
  paginationConfig: PaginationConfig(
    enabled: true,
    loadingIndicatorOffset: 100,
    reverseOrder: true,  // Newest messages at bottom
  ),
)

// In your chat controller initialization:
_chatController = ChatMessagesController(
  onLoadMoreMessages: (firstMessageId) async {
    // Fetch older messages from your data source
    final olderMessages = await yourDataSource.fetchMessagesBefore(firstMessageId);
    return olderMessages;
  },
);
```

### Example Questions

Show suggested questions for users to ask:

```dart
AiChatWidget(
  // Required parameters...
  exampleQuestions: [
    ExampleQuestion(question: "What can you help me with?"),
    ExampleQuestion(question: "Tell me about your features"),
    ExampleQuestion(question: "Show me a code example"),
  ],
  persistentExampleQuestions: true,  // Keep showing after welcome disappears
)
```

## Best Practices

### 1. Properly Handle Loading States

Always update loading state to provide user feedback:

```dart
AiChatWidget(
  // Required parameters...
  loadingConfig: LoadingConfig(
    isLoading: _isLoading,  // Update this via setState
    typingIndicatorColor: Theme.of(context).colorScheme.primary,
  ),
)
```

### 2. Support Light and Dark Themes

Adapt your UI for both light and dark themes:

```dart
final isDarkMode = Theme.of(context).brightness == Brightness.dark;

AiChatWidget(
  // Required parameters...
  messageOptions: MessageOptions(
    bubbleStyle: BubbleStyle(
      userBubbleColor: isDarkMode 
        ? Colors.blueGrey.shade800
        : Colors.blue.shade50,
      aiBubbleColor: isDarkMode 
        ? Colors.grey.shade800 
        : Colors.white,
    ),
  ),
)
```

### 3. Optimize for Performance

For large chat histories, use pagination:

```dart
AiChatWidget(
  // Required parameters...
  paginationConfig: PaginationConfig(
    enabled: true,
    reverseOrder: true,
  ),
)
```

### 4. Use Responsive Design

Make your chat UI adapt to different screen sizes:

```dart
AiChatWidget(
  // Required parameters...
  maxWidth: 800,  // Maximum width on large screens
  padding: EdgeInsets.symmetric(
    horizontal: MediaQuery.of(context).size.width > 600 ? 24 : 8,
    vertical: 16,
  ),
)
```

### 5. Customize the User Experience

Tailor the experience to match your app's style and functionality:

```dart
AiChatWidget(
  // Required parameters...
  
  // Personalize welcome message
  welcomeMessageConfig: WelcomeMessageConfig(
    title: "Welcome to ${yourApp.name}",
    questionsSectionTitle: "Try asking about:",
  ),
  
  // Add suggested questions specific to your domain
  exampleQuestions: yourDomainSpecificQuestions,
  
  // Use your app's theme colors
  messageOptions: MessageOptions(
    bubbleStyle: BubbleStyle(
      userBubbleColor: yourAppTheme.primaryColor.withOpacity(0.1),
      aiBubbleColor: yourAppTheme.backgroundColor,
    ),
  ),
)
```

## Proper Text Streaming Usage

To ensure your streaming text works correctly and avoid the "invalid stream" issue, follow these best practices:

### 1. Use Stable Message IDs

Always use a stable, unique ID for streaming messages to ensure proper updates:

```dart
// Generate a stable message ID
final messageId = 'ai_msg_${DateTime.now().millisecondsSinceEpoch}';

// Create initial empty message with the ID
final aiMessage = ChatMessage(
  text: "",
  user: aiUser,
  createdAt: DateTime.now(),
  isMarkdown: true, // Set to true if you want markdown support
  customProperties: {'isStreaming': true, 'id': messageId},
);

// Add the empty message to chat
controller.addMessage(aiMessage);
```

### 2. Update the Message with the Same ID

When updating streaming messages, always preserve the original message ID:

```dart
// Update the message with new content
controller.updateMessage(
  ChatMessage(
    text: updatedText,
    user: aiUser,
    createdAt: aiMessage.createdAt, // Keep the same timestamp
    isMarkdown: true,
    customProperties: {'isStreaming': true, 'id': messageId}, // Keep the same ID
  ),
);
```

### 3. Mark the Stream as Complete

When streaming is complete, update the message one last time to remove the streaming flag:

```dart
// Mark message as complete
controller.updateMessage(
  ChatMessage(
    text: finalText,
    user: aiUser,
    createdAt: aiMessage.createdAt,
    isMarkdown: true,
    customProperties: {'isStreaming': false, 'id': messageId}, // Set streaming to false
  ),
);
```

### 4. Complete Example

Here's a complete example of streaming text properly:

```dart
Future<void> streamAIResponse(String userPrompt, ChatUser aiUser) async {
  // Generate a stable message ID
  final messageId = 'ai_msg_${DateTime.now().millisecondsSinceEpoch}';
  
  // Create initial empty message
  final aiMessage = ChatMessage(
    text: "",
    user: aiUser,
    createdAt: DateTime.now(),
    isMarkdown: true,
    customProperties: {'isStreaming': true, 'id': messageId},
  );
  
  // Add the empty message to chat
  controller.addMessage(aiMessage);
  
  try {
    // Stream the response word by word (example with an API)
    final stream = yourAIService.streamResponse(userPrompt);
    
    String textSoFar = "";
    await for (final word in stream) {
      textSoFar += word;
      
      // Update the message with each new word
      controller.updateMessage(
        ChatMessage(
          text: textSoFar,
          user: aiUser,
          createdAt: aiMessage.createdAt,
          isMarkdown: true,
          customProperties: {'isStreaming': true, 'id': messageId},
        ),
      );
      
      // Optional: add small delay between words for visual effect
      await Future.delayed(const Duration(milliseconds: 50));
    }
    
    // Mark message as complete when streaming is done
    controller.updateMessage(
      ChatMessage(
        text: textSoFar,
        user: aiUser,
        createdAt: aiMessage.createdAt,
        isMarkdown: true,
        customProperties: {'isStreaming': false, 'id': messageId},
      ),
    );
  } catch (e) {
    // Handle errors gracefully
    controller.updateMessage(
      ChatMessage(
        text: "Sorry, there was an error generating the response.",
        user: aiUser,
        createdAt: aiMessage.createdAt,
        isMarkdown: true,
        customProperties: {'isStreaming': false, 'id': messageId},
      ),
    );
  }
}
```

### 5. Common Issues to Avoid

- **Changing the message ID**: Never change the 'id' value in customProperties during updates
- **Forgetting error handling**: Always wrap streaming code in try/catch blocks
- **Not marking completion**: Always set `isStreaming: false` when streaming is done
- **Using different timestamps**: Keep the same createdAt value for all updates to the same message

## Bottom Action Bar (ChatGPT‑Style)

As of the *extended* version, you can add a customizable bottom action bar (similar to ChatGPT mobile) above the input field.

### Step 1: Define Actions
Create a list of `BottomAction` items:
```dart
final actions = [
  BottomAction(icon: Icon(Icons.add),              onTap: _onAddAttachment),
  BottomAction(icon: Icon(Icons.search),           label: 'Search',         onTap: _onSearch),
  BottomAction(icon: Icon(Icons.auto_graph),       label: 'Deep research',  onTap: _onDeepResearch),
  BottomAction(icon: Icon(Icons.mic),              onTap: _onVoiceInput),
  BottomAction(icon: Icon(Icons.wifi_tethering),   label: 'Live',           onTap: _onLiveSession),
];
```

### Step 2: Supply to `AiChatWidget`
Pass your `actions` via the new `bottomActions` parameter:
```dart
AiChatWidget(
  currentUser: user,
  aiUser: ai,
  controller: controller,
  onSendMessage: _send,
  bottomActions: actions,
  // … existing parameters
)
```

### Behavior & Styling
- Renders immediately above the text input.
- Honors `MediaQuery.viewInsets` to slide with the keyboard.
- Each button has a minimum tap area of 44×44 dp.
- Icons and labels follow the current theme's `cardColor` and `caption` text style.

### Theming Tips
- Override `ThemeData.cardColor` or wrap the bar in a custom `Container` to adjust background.
- For custom icon colors or sizes, supply your own `Widget` into the `icon` field of `BottomAction`.