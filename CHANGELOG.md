## 2.6.2 - [2026-02-16] Streaming Dependency Upgrade

### Changed
- Bumped `flutter_streaming_text_markdown` from `^1.3.2` to `^1.4.0`
  - Fixes setState race conditions (prevents navigation crashes)
  - Fixes timer memory leaks in long-running chats
  - Fixes AnimationController disposal errors
  - 500x faster RTL/Arabic text processing

## 2.6.1 - [2026-02-16] Formatting Fix

### Fixed
- Applied `dart format` to 6 library files to restore full 160/160 pub.dev score

## 2.6.0 - [2026-02-16] Citations, Text Selection & Example Overhaul

### Added
- **Citation Support**: New `Citation` model and `CitationChip` widget for displaying source references on AI messages
  - `citations` field on `ChatMessage` for attaching source URLs/titles
  - `showCitations` and `citationStyle` on `MessageOptions` for display control
- **Interactive Text Selection**: New `enableInteractiveSelection` parameter on `InputOptions` to control text selection in the input field
  - Fixed `copyWith` bugs in `InputOptions` and related models

### Changed
- **Example App Overhaul**: Replaced 35+ scattered example files with 3 focused, professional examples
  - **Basic Chat** — minimal setup, plain text, no extras
  - **Streaming + Markdown** — code assistant with rich markdown, custom bubble styles
  - **Custom Themes** — Ocean/Sunset/Default theme switcher with per-theme colors and input decoration
  - Each example has distinct AI personality, response style, and shimmer loading text
  - `ExampleAiService` with `ResponseStyle` enum (plain/markdown/conversational)
- **Dependency Updates**: Bumped dependencies to latest compatible versions

### Fixed
- Name collision between package's `MockAiService` and example's mock service (renamed to `ExampleAiService`)
- `copyWith` bugs in `InputOptions`, `MessageOptions`, and related config classes

## 2.5.0 - [2025-11-08] Community Contributions - Spacing Control & UX Enhancements

### Added
- **ChatSpacingConfig**: New centralized configuration for all spacing and padding throughout the chat UI (#27 by @ducnguyenenterprise)
  - Consistent control over message bubble padding and margins
  - Customizable message list padding
  - Configurable quick replies spacing
  - Loading widget spacing control
  - Typing indicator spacing configuration
  - Includes `.compact()` and `.comfortable()` factory methods for common layouts
- **Custom Icon Support**: Added `iconData` parameter to example questions for full icon customization (#27)
- **Keyboard Dismiss Behavior**: New `keyboardDismissBehavior` parameter in `MessageOptions` for scroll-based keyboard dismissal (#27)

### Changed
- **Improved Animation Performance**: Loading animation speed improved from 800ms to 300ms for snappier UX (#27)
- **Optimized Cursor Animations**: Reduced unnecessary cursor animations when not needed (#27)

### Improved
- **Developer Experience**: Centralized spacing configuration makes it much easier to create consistent custom themes
- **Code Organization**: Refactored hardcoded spacing values into configurable system
- **Backward Compatibility**: All changes are optional with defaults matching previous behavior

### Technical
- Refactored spacing from hardcoded `EdgeInsets` to configurable `ChatSpacingConfig`
- All defaults preserve exact previous behavior (verified for backward compatibility)
- Zero breaking changes - completely backward compatible

### Contributors
- @ducnguyenenterprise (Dean Nguyen) - Thank you for this excellent contribution! 🙏

*This release demonstrates our commitment to community-driven development. Special thanks to our contributors for helping make this package better!*

---

## 2.4.2 - [2025-09-10] Critical Bug Fixes & Focus Control Enhancement

### Fixed
- **Streaming Animation Disable**: Fixed critical issue where `enableAnimation: false`, `enableMarkdownStreaming: false`, and `streamingWordByWord: false` parameters were ignored for markdown messages. Markdown messages would always stream regardless of these settings.
  - Updated streaming logic in `CustomChatWidget` to properly respect disable flags
  - Fixed hardcoded streaming parameters that bypassed user configuration  
  - Added proper conditional rendering for static vs streaming markdown
- **Test Coverage**: Added comprehensive tests for streaming disable functionality

### Added
- **Focus Control**: New `autofocus` and `focusNode` parameters in `InputOptions` for enhanced input field control
  - `autofocus: bool` - Automatically focus the input field when widget loads
  - `focusNode: FocusNode?` - Custom focus node for external focus management
  - Available in all factory constructors: `minimal()`, `glassmorphic()`, and default constructor
- **Enhanced API**: Updated `ChatInput` widget to support autofocus functionality
- **Test Coverage**: Added comprehensive tests for focus control features

### Improved  
- **Developer Experience**: Better focus management reduces need for external focus handling
- **API Consistency**: Focus parameters available across all `InputOptions` constructors
- **Documentation**: Updated README with new focus control examples and streaming fix notes

### Technical
- **Breaking Changes**: None - all changes are backward compatible
- **Memory Management**: Proper focus node disposal to prevent memory leaks
- **Test Coverage**: Added 11 new test cases covering focus and streaming scenarios

## 2.4.1 - [2025-09-04] Perfect 160/160 Pub.dev Score Achievement

### Fixed
- **Static Analysis**: Resolved all 33 lint issues for perfect static analysis score
  - Fixed cascade invocation warnings across multiple controller files
  - Removed unnecessary type annotations (int → var, bool → var, etc.)
  - Converted string concatenation to interpolation syntax
  - Escaped HTML angle brackets in documentation comments
  - Removed unnecessary Container wrapper
  - Fixed curly braces in flow control structures
- **Code Formatting**: Resolved all formatting issues identified by pana analysis
- **Directive Ordering**: Sorted import sections alphabetically per Dart conventions

### Improved
- **Pub.dev Score**: Achieved perfect 160/160 points via comprehensive pana analysis
  - Convention: 30/30 points
  - Documentation: 20/20 points (including dartdoc generation)
  - Platform Support: 20/20 points (all 6 platforms + WASM compatibility)
  - Static Analysis: 50/50 points (zero errors, warnings, lints, or formatting issues)
  - Dependencies: 40/40 points (up-to-date dependencies and SDK support)
- **Code Quality**: Significantly improved code maintainability and consistency
- **Documentation**: Complete API documentation with zero dartdoc warnings/errors

### Technical
- **Analysis Score**: Improved from 150/160 to perfect 160/160 pub.dev score
- **Lint Issues**: Reduced from 33 issues to zero blocking issues
- **Package Health**: Achieved excellent validation status with minimal non-scoring warnings
- **Performance**: Optimized code patterns for better runtime performance

## 2.3.6 - [2025-01-31] Package Optimization & Pub.dev Preparation

### Removed
- **Package Cleanup**: Removed unnecessary documentation files and examples to reduce package size
- **Simplified Structure**: Cleaned up doc/ directory, removed duplicate examples and internal documentation
- **File Optimization**: Removed development artifacts and test files not needed in published package

### Improved  
- **Package Metadata**: Optimized pubspec.yaml for better pub.dev scoring with proper topics and metadata
- **Documentation**: Streamlined package structure for better maintainability
- **Performance**: Reduced package footprint by removing non-essential files

### Technical
- **Pub.dev Optimization**: Package prepared for 160/160 pub.dev score achievement
- **Clean Architecture**: Maintained only essential files for production use
- **Better Discovery**: Improved package discoverability with optimized topics and keywords

*This release focuses on package optimization and pub.dev preparation, removing unnecessary files while maintaining full functionality.*

---

## 2.3.6 - [2025-01-31] Issue #18 Fix - CustomBubbleBuilder Implementation

### Fixed
- **CustomBubbleBuilder Functionality**: Fixed Issue #18 where `MessageOptions.customBubbleBuilder` was defined but not implemented
- **Import Resolution**: Fixed ChatMessage import conflict between `models/chat_message.dart` and `models/chat/chat_message.dart`

### Added
- **Custom Bubble Builder Support**: Fully functional customBubbleBuilder allows complete customization of message bubble appearance
- **Comprehensive Test Coverage**: Added extensive test suite for customBubbleBuilder functionality
- **Example Implementation**: Added CustomBubbleBuilderExample demonstrating various customization patterns

### Improved
- **Developer Experience**: CustomBubbleBuilder now works as documented with proper parameter passing
- **Backward Compatibility**: Existing behavior preserved when customBubbleBuilder is null
- **Code Quality**: Enhanced type safety and removed duplicate ChatMessage imports

### Technical
- Enhanced `_buildMessageBubble()` method in custom_chat_widget.dart to use customBubbleBuilder when provided
- Fixed import paths in message_options.dart to use correct ChatMessage type
- Added `_buildDefaultMessageBubble()` helper method for better code organization
- Comprehensive test coverage ensuring reliability and proper parameter handling

*This fix resolves Issue #18 and enhances the package's customization capabilities significantly.*

---

## 2.3.5 - [2025-01-27] PR #16 Integration - Enhanced Link Handling

### Added
- **Automatic URL Launching**: Markdown links now automatically open in external browser when tapped
- **Enhanced onTapLink**: Intelligent link handling with fallback to custom handlers
- **url_launcher Integration**: Added url_launcher dependency for seamless external link support

### Improved  
- **Developer Experience**: Links work out-of-the-box without requiring custom onTapLink implementation
- **Backward Compatibility**: Custom onTapLink handlers still take precedence when provided
- **User Experience**: Smooth link navigation enhances chat interaction flow

### Technical
- Added `url_launcher: ^6.3.1` dependency for external link launching
- Enhanced custom_chat_widget.dart with intelligent URL handling
- Maintained full compatibility with existing MessageOptions.onTapLink customizations

*Special thanks to @AmanuelYosief for PR #16 - these improvements are now integrated!*

---

## 2.3.4 - [2025-01-27] Package Visibility & Marketing Enhancement Release

### Enhanced
- **Package Discoverability**: Improved description, keywords, and metadata for better pub.dev search rankings
- **Marketing Optimization**: Added funding information, enhanced README with performance benchmarks and showcases
- **Developer Experience**: Removed adoption barriers and enhanced documentation clarity
- **Pub.dev Score**: Optimized dependencies and package configuration for maximum scoring

### Fixed
- **Documentation**: Updated version references throughout documentation to v2.3.4
- **Dependencies**: Updated to latest compatible versions for better security and performance
- **Linting**: Fixed unnecessary library naming issues for cleaner code

### Improved
- **SEO Optimization**: Enhanced keywords and descriptions for better package discovery
- **Community Features**: Added showcase section, testimonials, and contribution guidelines
- **Professional Presentation**: Streamlined messaging and removed technical barriers to adoption

---

## 2.3.3 - [2025-01-26] Critical Dependency Update - Professional Quality Release

### Fixed
- **Breaking Dependency Issue**: Replaced discontinued `flutter_markdown` package with `flutter_markdown_plus` for continued support and updates
- **API Compatibility**: Updated all markdown-related code to work seamlessly with `flutter_markdown_plus` API
- **Pub.dev Score Optimization**: Eliminated discontinued dependency warnings that negatively impact package scoring

### Improved
- **Future-Proof Dependencies**: All dependencies are now actively maintained and supported
- **Enhanced Package Reliability**: No more dependency deprecation warnings or security concerns
- **Better Developer Experience**: Smoother installation and usage without discontinued package warnings

### Technical Improvements
- Migrated from `flutter_markdown ^0.7.7` to `flutter_markdown_plus ^1.0.3`
- Updated `flutter_streaming_text_markdown` to latest v1.2.0 with new LLM animation presets
- Updated all import statements across library and example code
- Fixed `imageBuilder` API changes for custom image handling
- Maintained full backward compatibility for existing implementations

## 2.3.2 - [2025-01-26] Professional Quality Release - Comprehensive Package Improvements

### Fixed
- **Critical Memory Leak**: Fixed timer memory leak in ChatMessagesController that was causing test failures and potential production issues
- **Enhanced UI Layouts**: Improved example app interfaces with better responsive design and accessibility
- **Code Quality**: Resolved multiple code quality issues and improved package stability
- **Testing Reliability**: Fixed all failing tests and improved test coverage for streaming functionality

### Improved
- **Example App Design**: Enhanced all example screens with better layouts, improved accessibility, and professional styling
- **Scroll Behavior**: Optimized scroll behavior in intermediate example with better streaming message positioning
- **AppBar Layout**: Fixed responsive design issues in advanced example AppBar with proper title and button sizing
- **Home Screen**: Improved example discovery with better text visibility and optimized information density
- **Documentation**: Updated internal documentation and improved code comments for better maintainability

### Technical Improvements
- Enhanced timer management in ChatMessagesController with proper disposal patterns
- Improved widget lifecycle handling in scroll behavior examples
- Better error handling and state management in streaming examples
- Optimized example app performance with reduced unnecessary rebuilds

## 2.3.0 - [2024-07-12] File Upload & Media Attachments

### Added
- **File Upload Support**: Comprehensive file upload capabilities for images, documents, videos, and more
- **Flexible Media Attachments**: ChatMedia model to represent various media types in messages
- **Customizable Upload Options**: FileUploadOptions to control upload behavior, buttons, and limits
- **Image Caption Support**: Added the ability to include captions with uploaded images
- **Multiple File Support**: Ability to upload and display multiple files in a single message
- **Full Platform Permissions**: Documentation for required permissions on iOS, Android, and macOS
- **Full Example Implementation**: Complete real-world file upload example in the example app

### Fixed
- Fixed several code quality issues to improve the package's pub score
- Resolved deprecated method usage throughout the codebase
- Fixed type inference issues for better static analysis compatibility

## 2.2.1 - [2024-05-16] Better Image Control & Developer Experience

### Added
- **Image Interaction Control**: Added `enableImageTaps` parameter to `MessageOptions` to control whether images in markdown content respond to tap events
- **Enhanced Documentation**: Added comprehensive usage examples for controlling image interactions

### Fixed
- Prevented unintended navigation when tapping images in markdown content by default

## 2.2.0 - [2024-05-05] Scroll Behavior Controls & UX Improvements

### Added
- **New Scroll Behavior Controls**: Fix for Issue #13 - Prevent auto-scrolling that hides the top of long responses
- **ScrollBehaviorConfig**: Configure when and how the chat should auto-scroll
  - Control auto-scroll behavior with options: always, onNewMessage, onUserMessageOnly, or never
  - Optional feature to scroll to the first message of a response rather than the last
  - Customizable animation duration and curve for scrolling
- **Enhanced User Experience**: Better control over scrolling behavior for long AI responses
- **Comprehensive Example**: Added a dedicated example demonstrating all scrolling options

### Fixed
- **Fixed Issue #13**: Resolved the problem where long AI responses would auto-scroll, pushing the beginning of the response out of view
- **Improved Accessibility**: Users can now read the beginning of long responses without manual scrolling

## 2.1.2 - [2024-04-22] Dependency Cleanup & Broader Compatibility

### Changed
- **Removed permission_handler**: Removed as a core dependency since it's only needed for optional speech-to-text functionality
- **Enhanced SDK Compatibility**: Further improved compatibility by eliminating unnecessary dependencies
- **Updated Documentation**: Clarified speech-to-text implementation needs to be handled by the app developer
- **Dependency Optimization**: Removed several unused dependencies (intl, flutter_animate, provider, scrollable_positioned_list, url_launcher) to reduce package footprint

### Benefits
- No more SDK version conflicts with permission_handler dependency
- Significantly smaller package footprint (~60% reduction in external dependencies)
- Faster installation and build times
- More flexibility for implementing speech recognition with your preferred tools
- Reduced risk of version conflicts with other packages in your app

## 2.1.1 - [2024-04-22] Critical SDK Compatibility Fixes

### Fixed
- **SDK Compatibility**: Lowered minimum Dart SDK to `>=2.19.0` to ensure broader compatibility
- **Color Extensions**: Fixed `withOpacityCompat` to avoid using `withValues` internally, resolving errors on older Dart SDKs
- **Dependency Compatibility**: Downgraded `permission_handler` to version 10.2.0 for compatibility with Dart SDK 2.19+

### Changed
- Improved implementation of color opacity handling to work across all supported SDK versions
- Enhanced documentation around SDK compatibility requirements
- Extensive testing across multiple Flutter and Dart SDK versions

## 2.1.0 - Major Update: Dart 3.5+ & ChatGPT‑Style UI Enhancements

### Added
- Bumped Dart SDK lower bound to `>=3.5.0` for `permission_handler` compatibility
- Introduced ChatGPT‑style input capsule: full capsule radius, exact fill colors, and border
- Quick‑prompt chips above the text field with horizontal scroll support
- Inline action icons row merged into the same capsule material as input
- Animated send‑button opacity and scale based on content presence

### Changed
- Updated `ChatGPTTokens` to use official ChatGPT dark mode hex values
- Revised `InputOptions.chatGPTDefaults` for full capsule styling and padding
- Bumped package version to **2.1.0**
- Updated installation instructions in README & USAGE docs

### Fixed
- Formatted codebase and resolved all static analysis warnings
- Aligned `pubspec.yaml` environment SDK constraint with dependencies

## 2.0.8 - [2024-06-22] Pub Points & Static Analysis Fixes

### Changed
- Bumped package version to 2.0.8
- Shortened pubspec description for pub.dev guidelines
- Added valid issue_tracker URL

### Fixed
- Removed duplicate import in custom_chat_widget.dart
- Simplified withOpacityCompat implementation
- Resolved all static analysis warnings

## 2.0.7 - [2024-06-21] Pub Points & Static Analysis Fixes

### Changed
- Shortened pubspec description for pub.dev guidelines

### Fixed
- Removed duplicate import in custom_chat_widget.dart
- Removed deprecated withOpacity fallback in color_extensions.dart
- All static analysis warnings resolved

# Changelog

## 2.0.4 - [2024-07-05] Code Quality & Publication Improvements

### Changed
- Fixed all static analysis warnings to achieve top pub.dev score
- Made property types more consistent with proper nullability
- Improved type safety throughout the codebase
- Fixed import paths to avoid deprecated references
- Updated example question config to handle nullable properties correctly
- Enhanced review analysis widget with proper type annotations

## 2.0.3 - [2024-06-30] SEO & Static Analysis Improvements

### Changed
- Enhanced package description with more AI-specific keywords for better discoverability
- Added comprehensive keywords section to pubspec.yaml for improved searchability
- Updated permission_handler dependency to v12.0.0+1
- Fixed static analysis warnings and errors in ai_chat_widget.dart
- Improved example app descriptions with AI model-specific terms
- Added detailed AI model integration section to README
- Enhanced feature descriptions for better discoverability

## 2.0.2 - [2023-03-15] Input Behavior Improvements

### Changed
- Made send button always visible by default at the package level
- Completely removed the `alwaysShowSend` property as it's now redundant
- Modified default input behavior to prevent focus issues when typing
- Updated documentation to reflect the new send button behavior

## 2.0.0 - [2023-06-10] API Streamlining & Dila Alignment

### Breaking Changes
- Overhauled API to align more closely with Dila patterns
- Moved from centralized `AiChatConfig` to direct parameters in `AiChatWidget`
- Streamlined redundant and deprecated properties
- Reorganized configuration classes for better usability

### Improvements
- Enhanced documentation with comprehensive usage guide
- Added detailed migration guide from 1.x to 2.0
- Better IDE autocompletion support
- More intuitive parameter naming
- Cleaner code organization
- Simplified configuration objects

### Backward Compatibility
- Added `@Deprecated` markers to guide migration
- Maintained core functionality while improving API
- Preserved configuration objects but made them more focused
- See `docs/MIGRATION.md` for detailed migration guidance

## 1.3.0 - [2023-03-12] Feature Enhancements & Refinements

### New Features
- Enhanced markdown support with better code block styling
- Improved dark theme contrast and readability
- Better message bubble animations
- Fixed layout overflow issues
- Enhanced error handling

### Configuration Updates
1. All widget-level configurations now flow through `AiChatConfig`
2. Improved input handling with standalone `InputOptions`
3. Enhanced pagination with `PaginationConfig`
4. Better loading states with `LoadingConfig`
5. Centralized callbacks in `CallbackConfig`

## 1.2.0 - [2023-01-25] Improved UI & Performance

### New Features
- Improved message bubble design
- Added glassmorphic input option
- Enhanced streaming text animation
- Better error recovery
- Optimized performance for long chats

## 1.1.0 - [2022-12-08] Core Feature Updates

### Added
- RTL language support
- Improved markdown rendering
- Message pagination
- Better loading indicators
- Customizable welcome message

## 1.0.0 - [2022-11-15] Initial Release

### Initial Features
- Basic chat UI with AI-specific features
- Dark/light mode support
- Streaming text animation
- Markdown support
- Customizable styling
- Message management
- Simple welcome message

## [1.3.0] - 2024-03-21
### Breaking Changes
- Consolidated all widget configurations into `AiChatConfig`
- Deprecated widget-level properties in favor of config-based approach
- Improved input handling with standalone `InputOptions`
- Enhanced configuration structure for better developer experience

### Added
- Full markdown support with proper styling and dark mode compatibility
- Enhanced input customization with comprehensive options
- Improved pagination with better error handling
- Added markdown syntax help dialog
- Added proper blockquote and code block styling
- Added comprehensive error handling for markdown parsing

### Fixed
- Fixed overflow issues in welcome message layout
- Improved dark theme contrast and readability
- Enhanced message bubble animations
- Fixed input field spacing and margins
- Resolved all open GitHub issues (#1-#4)

## [1.2.0] - 2024-02-11
### Changed
- Made speech-to-text an optional dependency
- Updated documentation for optional STT integration
- Improved example implementation for speech-to-text
- Streamlined package dependencies
- Enhanced README structure and clarity

## [1.1.9] - 2024-02-07
### Added
- Updated streaming text performance with flutter_streaming_text_markdown
- Enhanced markdown rendering capabilities
- Improved dark theme with consistent colors
- Fixed various bugs and improved performance
- Added proper null checks and error handling
- Updated dependencies to latest stable versions

## [0.1.0] - 2024-10-19
### Added
- Initial release of flutter_gen_ai_chat_ui package.
- Customizable chat UI with theming, animations, and markdown streaming support using flutter_streaming_text_markdown.
- Streaming example updated to use flutter_streaming_text_markdown package.

### Changed
- Reverted Dila dependency to ^0.0.21 for compatibility.

### Fixed
- Minor UI and linter issues.

## 1.1.7

* Made speech-to-text an optional dependency
* Improved error handling for missing STT dependency
* Updated documentation for optional STT setup
* Fixed platform-specific STT implementation
* Added clear error messages for STT requirements
* Fixed speech-to-text button function return type inference
* Added proper type annotations for callback functions
* Fixed missing await warnings
* Code quality improvements

## 1.1.6

* Enhanced speech-to-text functionality with visual feedback
* Added sound level visualization with animated bars
* Added pulsing animation for active recording state
* Improved error handling for iOS speech recognition
* Added automatic language detection
* Added theme-aware styling for speech button
* Updated documentation with new speech-to-text features

## 1.1.5

* Enhanced loading indicator text size and visibility
* Improved shimmer effect contrast in both light and dark themes
* Optimized color values for better accessibility

## 1.1.4

* Improved loading indicator visibility in both light and dark themes
* Enhanced shimmer effect contrast and animation
* Increased loading text size and readability
* Optimized loading animation timing

## 1.1.3

* Added comprehensive test coverage
* Fixed dependency conflicts
* Updated platform support information
* Improved documentation
* Fixed unused variables in example files
* Updated dependencies to latest compatible versions
* Added const constructors for better performance
* Improved code organization and structure

## 1.1.2

* Added platform support information
* Updated package description
* Fixed linting issues
* Removed unused variables
* Updated dependencies

## 1.1.1

* Initial release with basic features
* Added customizable chat UI
* Added support for streaming responses
* Added code highlighting
* Added markdown support
* Added dark mode support
* Added RTL support
* Added example applications

## 1.1.8

* Improved dark theme contrast and visibility
* Enhanced AI message animations in streaming example
* Fixed package dependencies and imports
* Improved message bubble animations and transitions
* Updated theme toggle button styling
* Fixed various linter issues
* Removed redundant dependencies
* Added CustomThemeExtension to package exports

## 1.1.9

* Updated flutter_streaming_text_markdown to version 1.1.0
* Improved streaming text performance and reliability
* Enhanced markdown rendering capabilities

## [1.3.0] - Unreleased
### Breaking Changes
- Moved all widget-level configurations into `AiChatConfig`
- Added deprecation warnings for widget-level properties
- Improved configuration structure for better developer experience
- Enhanced documentation and property descriptions

### Added
- New loading state configurations in `AiChatConfig`
- Improved error messages and assertions
- Better documentation for input options and animations

## 0.0.x - Unreleased

### Added
- Enhanced loading indicator functionality with two display modes:
  - Bottom-aligned typing indicator (default) - shows loading near the input box like ChatGPT/Claude
  - Centered overlay indicator (optional) - shows loading in the center of the chat area
- Added `showCenteredIndicator` property to `LoadingConfig` to control loading indicator position
- New loading example demonstrating both loading styles

### Changed
- Default message order now shows newest messages at the bottom (like ChatGPT/Claude)
  - Changed default for `PaginationConfig.reverseOrder` from `true` to `false`
  - Updated documentation and comments to reflect the change
- Improved scroll-to-bottom behavior to work correctly in both chronological and reverse order modes
- Enhanced loading indicator handling for better UX

### Fixed
- Scroll position detection for the scroll-to-bottom button
- Message ordering when adding new messages

## [2.0.x] - YYYY-MM-DD
### Fixed
- Added `withOpacityCompat` extension for full compatibility with all Flutter/Dart SDKs.
- Migrated all usages of `.withOpacity(x)` and `.withValues(alpha: x)` to `.withOpacityCompat(x)`.
- No more build errors for users on Flutter <3.27.0.

## [2.0.5] - 2024-06-09
### Fixed
- Added `withOpacityCompat` extension for full compatibility with all Flutter/Dart SDKs.
- Migrated all usages of `.withOpacity(x)` and `.withValues(alpha: x)` to `.withOpacityCompat(x)`.
- No more build errors for users on Flutter <3.27.0.

## [2.0.6] - 2024-06-20
### Changed
- Prepare for next release by bumping version to 2.0.6

<!-- Next version changes go here -->
