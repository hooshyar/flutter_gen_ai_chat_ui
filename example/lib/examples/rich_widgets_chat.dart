// Rich Widget Messages - demonstrates ChatMessage.rich() and ChatMessage.widget()
import 'package:flutter/material.dart';
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';

import '../shell/app_theme.dart';
import '../shell/demo_scaffold.dart';

class RichWidgetsChatExample extends StatefulWidget {
  const RichWidgetsChatExample({super.key, required this.onToggleTheme});

  final VoidCallback onToggleTheme;

  @override
  State<RichWidgetsChatExample> createState() => _RichWidgetsChatExampleState();
}

class _RichWidgetsChatExampleState extends State<RichWidgetsChatExample> {
  final _controller = ChatMessagesController();
  bool _isLoading = false;

  static const _currentUser = ChatUser(id: 'user', name: 'You');
  static const _aiUser = ChatUser(id: 'ai', name: 'Assistant');

  void _onSendMessage(ChatMessage message) async {
    _controller.addMessage(message);
    setState(() => _isLoading = true);

    // Simulate AI thinking
    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

    final text = message.text.toLowerCase();

    if (text.contains('weather')) {
      // Rich widget: weather card
      _controller.addMessage(ChatMessage.rich(
        user: _aiUser,
        resultKind: 'weather',
        data: {
          'city': 'Baghdad',
          'temp': 42,
          'condition': 'Sunny',
          'humidity': 15,
          'wind': '12 km/h',
        },
        text: 'Here is the current weather for Baghdad.',
      ));
    } else if (text.contains('product') || text.contains('laptop')) {
      // Rich widget: product card
      _controller.addMessage(ChatMessage.rich(
        user: _aiUser,
        resultKind: 'product',
        data: {
          'name': 'MacBook Pro 16"',
          'price': '\$2,499',
          'rating': 4.8,
          'image': 'laptop',
          'features': ['M4 Pro chip', '48GB RAM', '1TB SSD'],
        },
      ));
    } else if (text.contains('chart') || text.contains('stats')) {
      // Inline widget (no registry needed)
      _controller.addMessage(ChatMessage.widget(
        user: _aiUser,
        builder: (context) => const _StatsWidget(),
      ));
    } else if (text.contains('order') || text.contains('status')) {
      // Rich widget: order status
      _controller.addMessage(ChatMessage.rich(
        user: _aiUser,
        resultKind: 'order_status',
        data: {
          'orderId': 'ORD-2026-4892',
          'status': 'In Transit',
          'eta': _formatEta(DateTime.now().add(const Duration(days: 3))),
          'items': 3,
        },
      ));
    } else if (text.contains('loading') || text.contains('morph')) {
      // Loading -> morph demo
      const loadId = 'demo-loading';
      _controller.addMessage(ChatMessage.loading(
        user: _aiUser,
        id: loadId,
        loadingKind: 'weather',
      ));
      // After 2 seconds, replace with the actual widget
      Future<void>.delayed(const Duration(seconds: 2), () {
        if (!mounted) return;
        _controller.updateMessage(ChatMessage.rich(
          user: _aiUser,
          id: loadId,
          resultKind: 'weather',
          data: {
            'city': 'Erbil',
            'temp': 38,
            'condition': 'Clear',
            'humidity': 20,
            'wind': '8 km/h',
          },
        ));
      });
    } else {
      // Regular text response
      _controller.addMessage(ChatMessage(
        text: 'Try asking about:\n'
            '- "weather" for a weather card\n'
            '- "product" for a product card\n'
            '- "stats" for an inline chart widget\n'
            '- "order status" for an order tracker\n'
            '- "loading" to see shimmer to widget morph',
        user: _aiUser,
        createdAt: DateTime.now(),
        isMarkdown: true,
      ));
    }

    setState(() => _isLoading = false);
  }

  static const _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  static String _formatEta(DateTime d) =>
      '${_monthNames[d.month - 1]} ${d.day}, ${d.year}';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DemoScaffold(
      title: 'Rich results',
      route: '/rich-widgets',
      isDark: isDark,
      onToggleTheme: widget.onToggleTheme,
      body: AiChatWidget(
        currentUser: _currentUser,
        aiUser: _aiUser,
        controller: _controller,
        onSendMessage: _onSendMessage,
        // Register rich widget renderers by kind. Full-width rich results
        // render outside the normal bubble path, which skips the 24px
        // sender-change top gap ordinary text replies get — `_cardTopSpacing`
        // restores it here so a card doesn't sit flush under the preceding
        // bubble (DESIGN.md §9 "Rich results").
        resultRenderers: {
          'weather': (context, data) =>
              _cardTopSpacing(_buildWeatherCard(context, data)),
          'product': (context, data) =>
              _cardTopSpacing(_buildProductCard(context, data)),
          'order_status': (context, data) =>
              _cardTopSpacing(_buildOrderStatusCard(context, data)),
        },
        resultLoadingRenderers: {
          'weather': (context, data) => _cardTopSpacing(
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 12),
                      Text('Fetching weather data...'),
                    ],
                  ),
                ),
              ),
        },
        loadingConfig: LoadingConfig(
          isLoading: _isLoading,
          loadingIndicator: const LoadingWidget(
            texts: ['Thinking...'],
          ),
        ),
        enableMarkdownStreaming: false,
        welcomeMessageConfig: const WelcomeMessageConfig(
          title: 'Rich Widget Messages',
          questionsSectionTitle:
              'AI responses can include interactive widgets. Try these:',
        ),
        exampleQuestions: const [
          ExampleQuestion(question: "What's the weather?"),
          ExampleQuestion(question: 'Show me a product'),
          ExampleQuestion(question: 'Show stats chart'),
          ExampleQuestion(question: 'Check order status'),
          ExampleQuestion(question: 'Show loading morph'),
        ],
      ),
    );
  }

  // Result Renderers - cards use tokens: radius 12, 1px outline, no
  // elevation. DESIGN.md 9 "Rich results".

  static Widget _buildWeatherCard(
    BuildContext context,
    Map<String, dynamic> data,
  ) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['city'] as String? ?? '',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    data['condition'] as String? ?? '',
                    style: TextStyle(color: colors.textSecondary, fontSize: 14),
                  ),
                ],
              ),
              Text(
                '${data['temp']} deg',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 40,
                  fontWeight: FontWeight.w200,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _WeatherDetail(
                  icon: Icons.water_drop,
                  label: '${data['humidity']}%',
                  colors: colors),
              const SizedBox(width: 24),
              _WeatherDetail(
                  icon: Icons.air,
                  label: data['wind'] as String? ?? '',
                  colors: colors),
            ],
          ),
        ],
      ),
    );
  }

  static Widget _buildProductCard(
    BuildContext context,
    Map<String, dynamic> data,
  ) {
    final colors = context.appColors;
    final features = (data['features'] as List?)?.cast<String>() ?? [];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product image placeholder: a neutral surfaceSunken tile.
          Container(
            width: double.infinity,
            height: 120,
            decoration: BoxDecoration(
              color: colors.surfaceSunken,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.laptop_mac,
              size: 40,
              color: colors.textTertiary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            data['name'] as String? ?? '',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                data['price'] as String? ?? '',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: colors.accent,
                ),
              ),
              const Spacer(),
              Icon(Icons.star, color: colors.accent, size: 18),
              const SizedBox(width: 4),
              Text(
                '${data['rating']}',
                style: TextStyle(color: colors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: features
                .map((f) => Chip(
                      label: Text(f, style: const TextStyle(fontSize: 12)),
                      backgroundColor: colors.surfaceSunken,
                      side: BorderSide.none,
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ))
                .toList(),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${data['name'] ?? 'Item'} added to cart'),
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              child: const Text('Add to Cart'),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildOrderStatusCard(
    BuildContext context,
    Map<String, dynamic> data,
  ) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colors.surfaceSunken,
                  borderRadius: BorderRadius.circular(8),
                ),
                child:
                    Icon(Icons.local_shipping, color: colors.accent, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['orderId'] as String? ?? '',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                    Text(
                      '${data['items']} items',
                      style: TextStyle(
                        fontSize: 13,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.surfaceSunken,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  data['status'] as String? ?? '',
                  style: TextStyle(
                    color: colors.accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: 0.7,
              backgroundColor: colors.surfaceSunken,
              color: colors.accent,
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Estimated delivery',
                style: TextStyle(fontSize: 12, color: colors.textSecondary),
              ),
              Text(
                data['eta'] as String? ?? '',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Helper widgets

/// Full-width rich results (weather/product/order cards) render through
/// [AiChatWidget.resultRenderers], which bypasses the normal bubble path and
/// its sender-change top gap. Wrapping every card in this gives it the same
/// [ChatSpace.s24] gap a text reply gets after a user message.
Widget _cardTopSpacing(Widget child) {
  return Padding(
      padding: const EdgeInsets.only(top: ChatSpace.s24), child: child);
}

class _WeatherDetail extends StatelessWidget {
  const _WeatherDetail(
      {required this.icon, required this.label, required this.colors});
  final IconData icon;
  final String label;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: colors.textSecondary, size: 16),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(color: colors.textSecondary, fontSize: 13)),
      ],
    );
  }
}

class _StatsWidget extends StatelessWidget {
  const _StatsWidget();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Weekly activity',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _Bar(height: 40, label: 'Mon', colors: colors),
              _Bar(height: 65, label: 'Tue', colors: colors),
              _Bar(height: 35, label: 'Wed', colors: colors),
              _Bar(height: 80, label: 'Thu', colors: colors, highlight: true),
              _Bar(height: 55, label: 'Fri', colors: colors),
              _Bar(height: 25, label: 'Sat', colors: colors, muted: true),
              _Bar(height: 20, label: 'Sun', colors: colors, muted: true),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _StatItem(label: 'Total', value: '1,284', colors: colors),
              _StatItem(label: 'Avg', value: '183/day', colors: colors),
              _StatItem(label: 'Peak', value: 'Thu', colors: colors),
            ],
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.height,
    required this.label,
    required this.colors,
    this.highlight = false,
    this.muted = false,
  });
  final double height;
  final String label;
  final AppColors colors;
  final bool highlight;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final barColor = muted
        ? colors.textTertiary.withValues(alpha: 0.4)
        : highlight
            ? colors.accent
            : colors.accent.withValues(alpha: 0.5);
    return Column(
      children: [
        Container(
          width: 24,
          height: height,
          decoration: BoxDecoration(
            color: barColor,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: colors.textSecondary),
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.label,
    required this.value,
    required this.colors,
  });
  final String label;
  final String value;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: colors.textPrimary,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: colors.textSecondary),
        ),
      ],
    );
  }
}
