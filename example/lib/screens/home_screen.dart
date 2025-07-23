import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';

import '../models/app_state.dart';
import '../widgets/settings_drawer.dart';
import 'chat_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final _pageController = PageController();
  int _currentPage = 0;
  final List<String> _pageLabels = ['Dila Chat', 'Features', 'Examples'];
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutQuint,
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Scaffold(
            key: _scaffoldKey,
            appBar: AppBar(
              title: Text(_pageLabels[_currentPage]),
              titleTextStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
              leading: _currentPage == 0
                  ? IconButton(
                      icon: const Icon(Icons.refresh_rounded),
                      tooltip: 'Reset Chat',
                      onPressed: () {
                        ChatScreen.clearMessages(context);
                      },
                    )
                  : null,
              actions: [
                // Welcome message toggle button (only on chat page)
                if (_currentPage == 0)
                  IconButton(
                    icon: const Icon(Icons.message_outlined),
                    tooltip: 'Toggle Welcome Message',
                    onPressed: () {
                      ChatScreen.toggleWelcomeMessage(context);
                    },
                  ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder:
                      (Widget child, Animation<double> animation) {
                    return ScaleTransition(scale: animation, child: child);
                  },
                  child: IconButton(
                    key: ValueKey<bool>(isDarkMode),
                    icon: Icon(
                      isDarkMode
                          ? Icons.light_mode_rounded
                          : Icons.dark_mode_rounded,
                      color: isDarkMode ? Colors.amber : Colors.blueGrey,
                    ),
                    onPressed: () {
                      Provider.of<AppState>(context, listen: false)
                          .toggleTheme();
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.settings_rounded),
                  onPressed: () {
                    _scaffoldKey.currentState?.openEndDrawer();
                  },
                ),
              ],
              elevation: 0,
              scrolledUnderElevation: 0,
            ),
            endDrawer: const SettingsDrawer(),
            body: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              children: [
                // Main chat demonstration
                const ChatScreen(),

                // Features showcase page
                _buildFeaturesPage(colorScheme, isDarkMode),

                // Examples page
                _buildExamplesPage(colorScheme, isDarkMode),
              ],
            ),
            bottomNavigationBar: NavigationBar(
              selectedIndex: _currentPage,
              onDestinationSelected: (index) {
                _pageController.animateToPage(
                  index,
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOutQuint,
                );
              },
              elevation: 0,
              backgroundColor: isDarkMode
                  ? colorScheme.surface.withOpacityCompat(0.9)
                  : colorScheme.surface,
              destinations: [
                NavigationDestination(
                  icon: const Icon(Icons.chat_bubble_outline_rounded),
                  selectedIcon: Icon(
                    Icons.chat_bubble_rounded,
                    color: colorScheme.primary,
                  ),
                  label: 'Chat',
                ),
                NavigationDestination(
                  icon: const Icon(Icons.star_outline_rounded),
                  selectedIcon: Icon(
                    Icons.star_rounded,
                    color: colorScheme.primary,
                  ),
                  label: 'Features',
                ),
                NavigationDestination(
                  icon: const Icon(Icons.code_outlined),
                  selectedIcon: Icon(
                    Icons.code_rounded,
                    color: colorScheme.primary,
                  ),
                  label: 'Examples',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Features showcase page
  Widget _buildFeaturesPage(ColorScheme colorScheme, bool isDarkMode) {
    final features = [
      {
        'icon': Icons.bolt_rounded,
        'title': 'Streaming Text',
        'description': 'Word-by-word animation for natural conversations',
      },
      {
        'icon': Icons.draw_rounded,
        'title': 'Rich Markdown',
        'description': 'Format content with headers, lists, and emphasis',
      },
      {
        'icon': Icons.code_rounded,
        'title': 'Code Highlighting',
        'description': 'Beautiful syntax highlighting for code blocks',
      },
      {
        'icon': Icons.dark_mode_rounded,
        'title': 'Dark Mode',
        'description': 'Full support for light and dark themes',
      },
      {
        'icon': Icons.question_answer_rounded,
        'title': 'Example Questions',
        'description': 'Guided conversation starters',
      },
      {
        'icon': Icons.question_mark_rounded,
        'title': 'Context Memory',
        'description': 'Maintains conversation context',
      },
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dila Assistant Features',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'A showcase of Flutter Gen AI Chat UI capabilities',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.5,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: features.length,
              itemBuilder: (context, index) {
                final feature = features[index];
                return Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          feature['icon'] as IconData,
                          size: 36,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          feature['title'] as String,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          feature['description'] as String,
                          style: Theme.of(context).textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Examples page
  Widget _buildExamplesPage(ColorScheme colorScheme, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Example Use Cases',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ways to integrate Flutter Gen AI Chat UI in your apps',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView(
              children: [
                _buildExampleCard(
                  title: 'Customer Support',
                  description:
                      'Integrate Dila as a first-line customer support assistant in your app, handling common queries and escalating complex issues to human agents.',
                  icon: Icons.support_agent_rounded,
                  color: colorScheme,
                ),
                _buildExampleCard(
                  title: 'Learning Platform',
                  description:
                      'Use Dila as an interactive tutor in educational apps, providing explanations, examples, and practice exercises with rich formatting.',
                  icon: Icons.school_rounded,
                  color: colorScheme,
                ),
                _buildExampleCard(
                  title: 'Documentation Browser',
                  description:
                      'Create an interactive documentation browser with code examples and markdown formatting for developers and technical users.',
                  icon: Icons.menu_book_rounded,
                  color: colorScheme,
                ),
                _buildExampleCard(
                  title: 'Content Creation',
                  description:
                      'Assist users in drafting articles, emails, or social media posts with formatting suggestions and templates.',
                  icon: Icons.edit_note_rounded,
                  color: colorScheme,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExampleCard({
    required String title,
    required String description,
    required IconData icon,
    required ColorScheme color,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.primary.withOpacityCompat(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 32,
                color: color.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
