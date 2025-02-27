# Changelog

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
- Reverted dash_chat_2 dependency to ^0.0.21 for compatibility.

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
