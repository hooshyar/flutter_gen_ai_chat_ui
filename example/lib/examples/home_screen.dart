import 'package:flutter/material.dart';
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';

/// The main navigation page for all Flutter Gen AI Chat UI examples
class ExamplesHomeScreen extends StatelessWidget {
  const ExamplesHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Gen AI Chat UI'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        elevation: 0,
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _buildHeader(context),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16.0),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16.0,
                  crossAxisSpacing: 16.0,
                  childAspectRatio: 0.75,
                ),
                delegate: SliverChildListDelegate([
                  _buildExampleCard(
                    context,
                    title: 'Basic',
                    description: 'Simple chat UI with essential features',
                    icon: Icons.chat_bubble_outline,
                    color: Colors.blue,
                    routeName: '/basic',
                  ),
                  _buildExampleCard(
                    context,
                    title: 'Intermediate',
                    description: 'Chat UI with markdown and streaming',
                    icon: Icons.mark_chat_read_outlined,
                    color: Colors.green,
                    routeName: '/intermediate',
                  ),
                  _buildExampleCard(
                    context,
                    title: 'Advanced',
                    description: 'Full-featured chat with custom themes',
                    icon: Icons.smart_toy_outlined,
                    color: Colors.purple,
                    routeName: '/advanced',
                  ),
                  _buildExampleCard(
                    context,
                    title: 'File Attachments',
                    description: 'Chat with various file attachment types',
                    icon: Icons.attach_file,
                    color: Colors.teal,
                    routeName: '/file-attachments',
                  ),
                  _buildExampleCard(
                    context,
                    title: 'Real File Upload',
                    description: 'Upload actual files and images from device',
                    icon: Icons.file_upload,
                    color: Colors.red,
                    routeName: '/real-file-upload',
                  ),
                  _buildExampleCard(
                    context,
                    title: 'Scroll Behavior',
                    description: 'Control auto-scrolling for long responses',
                    icon: Icons.swipe_vertical,
                    color: Colors.orange,
                    routeName: '/scroll-behavior',
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Example Gallery',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Explore different implementations of the Flutter Gen AI Chat UI package',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onPrimaryContainer
                      .withOpacityCompat(0.8),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildExampleCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required String routeName,
  }) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(context, routeName);
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 100,
              decoration: BoxDecoration(
                color: color.withOpacityCompat(0.2),
              ),
              child: Center(
                child: Icon(
                  icon,
                  size: 48,
                  color: color,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: Text(
                        description,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color:
                                  Theme.of(context).textTheme.bodySmall?.color,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'Explore',
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward,
                          size: 16,
                          color: color,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Unused method removed to fix lint warning
}
