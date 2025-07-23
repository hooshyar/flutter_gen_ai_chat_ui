import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';
import '../models/app_state.dart';

/// A bottom sheet with settings options for the chat UI
class SettingsSheet extends StatelessWidget {
  const SettingsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final theme = Theme.of(context);
    // Removed unused variable for lint compliance
    // final isDark = theme.brightness == Brightness.dark;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacityCompat(0.2),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withOpacityCompat(0.2),
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),

              // Title
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Settings',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              // Settings List
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    // Appearance Section
                    _buildSectionHeader(context, 'Appearance'),

                    // Theme Mode
                    _buildThemeModeSetting(context, appState),

                    // Animation Toggle
                    SwitchListTile(
                      title: const Text('Enable Animations'),
                      subtitle: const Text('Animate message transitions'),
                      value: appState.enableAnimation,
                      onChanged: (_) => appState.toggleAnimation(),
                      secondary: Icon(Icons.animation,
                          color: theme.colorScheme.primary),
                    ),

                    const Divider(),

                    // Chat Experience
                    _buildSectionHeader(context, 'Chat Experience'),

                    // Text Streaming
                    SwitchListTile(
                      title: const Text('Text Streaming'),
                      subtitle: const Text('Show responses word by word'),
                      value: appState.isStreaming,
                      onChanged: (_) => appState.toggleStreaming(),
                      secondary: Icon(Icons.text_fields,
                          color: theme.colorScheme.primary),
                    ),

                    // Welcome Message
                    SwitchListTile(
                      title: const Text('Welcome Message'),
                      subtitle: const Text('Show welcome screen at start'),
                      value: appState.showWelcomeMessage,
                      onChanged: (_) => appState.toggleWelcomeMessage(),
                      secondary: Icon(Icons.waving_hand,
                          color: theme.colorScheme.primary),
                    ),

                    // Code Blocks
                    SwitchListTile(
                      title: const Text('Code Blocks'),
                      subtitle: const Text(
                          'Show code examples with syntax highlighting'),
                      value: appState.showCodeBlocks,
                      onChanged: (_) => appState.toggleCodeBlocks(),
                      secondary:
                          Icon(Icons.code, color: theme.colorScheme.primary),
                    ),

                    // Persistent Example Questions
                    SwitchListTile(
                      title: const Text('Persistent Questions'),
                      subtitle:
                          const Text('Show example questions during chat'),
                      value: appState.persistentExampleQuestions,
                      onChanged: (_) =>
                          appState.togglePersistentExampleQuestions(),
                      secondary: Icon(Icons.help_outline,
                          color: theme.colorScheme.primary),
                    ),

                    const Divider(),

                    // UI Customization
                    _buildSectionHeader(context, 'UI Customization'),

                    // Chat Max Width
                    _buildSliderSetting(
                      context,
                      title: 'Chat Max Width',
                      value: appState.chatMaxWidth,
                      min: 400,
                      max: 1200,
                      divisions: 8,
                      onChanged: (value) => appState.setChatMaxWidth(value),
                      valueDisplay: '${appState.chatMaxWidth.toInt()} px',
                    ),

                    // Font Size
                    _buildSliderSetting(
                      context,
                      title: 'Message Font Size',
                      value: appState.fontSize,
                      min: 12,
                      max: 20,
                      divisions: 8,
                      onChanged: (value) => appState.setFontSize(value),
                      valueDisplay: '${appState.fontSize.toInt()} px',
                    ),

                    // Border Radius
                    _buildSliderSetting(
                      context,
                      title: 'Bubble Border Radius',
                      value: appState.messageBorderRadius,
                      min: 4,
                      max: 24,
                      divisions: 10,
                      onChanged: (value) =>
                          appState.setMessageBorderRadius(value),
                      valueDisplay:
                          '${appState.messageBorderRadius.toInt()} px',
                    ),

                    const SizedBox(height: 24),

                    // About section with app info
                    _buildAboutSection(context),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Build a section header
  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }

  /// Build the theme mode selection card
  Widget _buildThemeModeSetting(BuildContext context, AppState appState) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Theme Mode', style: theme.textTheme.titleMedium),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _themeOption(
                  context,
                  Icons.light_mode,
                  'Light',
                  appState.themeMode == ThemeMode.light,
                  () => appState.setThemeMode(ThemeMode.light),
                ),
                _themeOption(
                  context,
                  Icons.dark_mode,
                  'Dark',
                  appState.themeMode == ThemeMode.dark,
                  () => appState.setThemeMode(ThemeMode.dark),
                ),
                _themeOption(
                  context,
                  Icons.settings_suggest,
                  'System',
                  appState.themeMode == ThemeMode.system,
                  () => appState.setThemeMode(ThemeMode.system),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build a theme option button
  Widget _themeOption(BuildContext context, IconData icon, String label,
      bool isSelected, VoidCallback onTap) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.transparent : theme.dividerColor,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.onSurface,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build a slider setting
  Widget _buildSliderSetting(
    BuildContext context, {
    required String title,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
    required String valueDisplay,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleSmall),
              Text(valueDisplay, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  /// Build the about section
  Widget _buildAboutSection(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('About', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Professional AI Assistant v1.0.0\n'
              'Powered by Flutter Gen AI Chat UI',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacityCompat(0.7),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'This is a comprehensive demo of the Flutter Gen AI Chat UI package showcasing its capabilities for building professional chat interfaces.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacityCompat(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
