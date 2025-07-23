# Changelog

## 2.3.1 - 2025-01-23

### Added
- Added `onTapLink` callback support for markdown links
- Enhanced markdown link interaction capabilities for better user experience

### Technical Improvements
- **Fixed flutter_markdown API deprecation warning** - Migrated from deprecated `imageBuilder` to modern `sizedImageBuilder`
- **Improved image handling** - Enhanced with proper sizing support via `MarkdownImageConfig`
- **Maintained backward compatibility** - All existing functionality preserved
- **Achieved perfect static analysis score** - 0 dart analyze issues
- **100% test coverage maintained** - All 118 tests passing

### Quality Assurance
- Zero lint warnings with flutter_lints strict rules
- Full type safety compliance
- Production-ready API standards

## 2.3.0 - [2024-03-21] Major Feature Release

### Added
- Comprehensive file upload system with ChatMedia model
- Advanced scroll behavior configuration
- Enhanced streaming text support
- Improved pagination functionality
- Dark mode theme enhancements

### Changed
- Upgraded to native chat implementation (removed dash_chat_2 dependency)
- Enhanced message state management
- Improved performance with message caching
- Better error handling and validation

### Breaking Changes
- Replaced dash_chat_2 with native implementation
- Updated model structure for ChatUser and ChatMessage
- Modified configuration classes for better organization

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

## 1.3.0 - [2023-02-15] Enhanced Customization

### Added
- Added comprehensive size control to InputOptions
- Added material customization properties to InputOptions
- Introduced comprehensive documentation for input customization

### Migration Notes
- v2.3.0 introduced breaking changes with native chat implementation
- v2.0.0 streamlined API with Dila alignment
- See migration guides in doc/MIGRATION.md for detailed upgrade instructions

### Current Roadmap
- Enhanced accessibility features
- Advanced customization options
- Performance optimizations
- Extended platform support

For details on older releases, please see the root CHANGELOG.md file. 