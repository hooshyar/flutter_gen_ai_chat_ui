# Package Structure

This document outlines the organization of the Flutter Gen AI Chat UI package (v2.3.0+).

## Directory Structure

```
flutter_gen_ai_chat_ui/
│
├── lib/                    # Main package code
│   ├── flutter_gen_ai_chat_ui.dart  # Main entry point / exports
│   │
│   └── src/                # Source code
│       ├── controllers/    # State management
│       │   └── chat_messages_controller.dart
│       ├── models/         # Data models
│       │   ├── chat/       # Chat-specific models
│       │   │   ├── chat_message.dart
│       │   │   ├── chat_user.dart
│       │   │   ├── chat_media.dart
│       │   │   └── models.dart
│       │   ├── ai_chat_config.dart
│       │   ├── input_options.dart
│       │   ├── message_options.dart
│       │   └── welcome_message_config.dart
│       ├── theme/          # Theme extensions
│       │   └── custom_theme_extension.dart
│       ├── utils/          # Utility functions
│       │   ├── color_extensions.dart
│       │   ├── glassmorphic_container.dart
│       │   ├── font_helper.dart
│       │   └── locale_helper.dart
│       └── widgets/        # UI components
│           ├── ai_chat_widget.dart
│           ├── custom_chat_widget.dart
│           ├── chat_input.dart
│           └── animated_text_message.dart
│
├── example/                # Example applications
│   ├── lib/
│   │   ├── screens/        # Different example screens
│   │   ├── providers/      # State management examples
│   │   └── main.dart       # Example app entry point
│   └── integration_test/   # Integration tests
│
├── doc/                    # Documentation
│   ├── CHANGELOG.md        # Version history
│   ├── USAGE.md            # Usage guide
│   ├── MIGRATION.md        # Migration guide
│   ├── COMPATIBILITY.md    # Platform compatibility
│   ├── files_structure.md  # This file
│   ├── input_customization.md # Input styling guide
│   ├── release_checklist.md   # Release process
│   └── ui/                 # UI screenshots
│
├── test/                   # Comprehensive test suite
│   ├── controllers/        # Controller tests
│   ├── models/            # Model tests
│   ├── widgets/           # Widget tests
│   ├── examples_test.dart # Example app tests
│   └── performance/       # Performance benchmarks
│
└── integration_test/       # Integration tests
    └── utils/             # Test utilities
```

## Core Components

### Controllers

| File | Description |
|------|-------------|
| `chat_messages_controller.dart` | Enhanced message state management with pagination, streaming, and scroll control |

### Models

#### Chat Models (`models/chat/`)
| File | Description |
|------|-------------|
| `chat_message.dart` | Enhanced message data structure with media support |
| `chat_user.dart` | User data structure with roles and avatars |
| `chat_media.dart` | Media attachment model (images, documents, videos) |
| `models.dart` | Unified exports for chat models |

#### Configuration Models
| File | Description |
|------|-------------|
| `input_options.dart` | Comprehensive input field configuration |
| `message_options.dart` | Message bubble styling and behavior |
| `welcome_message_config.dart` | Welcome screen configuration |
| `example_question_config.dart` | Example questions configuration |
| `ai_chat_config.dart` | Legacy unified configuration (deprecated) |

### Widgets

| File | Description |
|------|-------------|
| `ai_chat_widget.dart` | Main chat widget with comprehensive configuration |
| `custom_chat_widget.dart` | Core chat implementation with message rendering |
| `chat_input.dart` | Advanced input field with multiple styling options |
| `animated_text_message.dart` | Streaming text animation with markdown support |

### Theme

| File | Description |
|------|-------------|
| `custom_theme_extension.dart` | Comprehensive theme extensions for dark/light modes |

### Utils

| File | Description |
|------|-------------|
| `color_extensions.dart` | Color manipulation utilities with opacity compatibility |
| `glassmorphic_container.dart` | Advanced glassmorphism effects |
| `font_helper.dart` | Typography and RTL text utilities |
| `locale_helper.dart` | Internationalization support |

## Entry Points

The main entry point for the package is `flutter_gen_ai_chat_ui.dart`, which exports all public APIs.

## Key APIs

### Main Widget

`AiChatWidget` - The primary widget with comprehensive configuration options:
- Direct parameter configuration (v2.0+)
- Extensive customization capabilities
- Built-in themes and styling options
- Advanced features like pagination and streaming

### Controller

`ChatMessagesController` - Powerful state management:
- Message addition, updating, and deletion
- Pagination and infinite scroll support
- Streaming text updates
- Scroll behavior control
- Welcome message management

### Configuration Objects

#### Core Configuration
- `InputOptions` - Comprehensive input field styling and behavior
- `MessageOptions` - Message bubble styling, colors, and interactions
- `WelcomeMessageConfig` - Welcome screen customization
- `ExampleQuestionConfig` - Example questions configuration

#### Advanced Configuration
- `LoadingConfig` - Loading state indicators and animations
- `PaginationConfig` - Message history pagination with batch loading
- `ScrollBehaviorConfig` - Scroll animation and auto-scroll settings
- `CallbackConfig` - Event handling and user interaction callbacks

### Models

#### Chat Models
- `ChatUser` - Enhanced user representation with roles and avatars
- `ChatMessage` - Rich message model with media, reactions, and metadata
- `ChatMedia` - Media attachment support (images, documents, videos)

#### Interaction Models
- `MessageReaction` - Message reaction system
- `QuickReply` - Quick reply options for enhanced UX

## Example App

The comprehensive example app demonstrates:

### Core Features
1. **Basic Chat** (`simple_chat_screen.dart`) - Essential chat functionality
2. **Streaming Text** (`streaming_example.dart`) - Real-time text animation
3. **Markdown Support** (`markdown_example.dart`) - Rich text formatting
4. **Pagination** (`pagination_example.dart`) - Message history loading
5. **Custom Styling** (`custom_styling_example.dart`) - Theme customization

### Advanced Features
6. **File Upload Support** - Media attachment handling
7. **Dark/Light Themes** - Dynamic theme switching
8. **Speech-to-Text Integration** - Voice input examples
9. **Performance Optimization** - Large message list handling
10. **Accessibility Support** - Screen reader and keyboard navigation

### Integration Tests
- Widget interaction testing
- Cross-platform compatibility
- Performance benchmarking
- Visual regression testing

## Version History & Breaking Changes

### v2.3.0 Breaking Changes
- **Native Implementation**: Removed `dash_chat_2` dependency
- **Enhanced Models**: Updated `ChatUser` and `ChatMessage` structure
- **Improved Configuration**: Reorganized configuration classes

### v2.0.0 Breaking Changes
- **API Streamlining**: Moved from centralized config to direct parameters
- **Dila Alignment**: Updated API patterns for better usability

### Deprecations
The following are maintained for backward compatibility:
- `AiChatConfig` - Use direct parameters on `AiChatWidget` instead
- Legacy model imports - Use `models/chat/models.dart` exports

### Migration Support
See `doc/MIGRATION.md` for detailed upgrade instructions between major versions.