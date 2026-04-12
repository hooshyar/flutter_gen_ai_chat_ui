// Rich Widget Messages — demonstrates ChatMessage.rich() and ChatMessage.widget()
import 'package:flutter/material.dart';
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';

class RichWidgetsChatExample extends StatefulWidget {
  const RichWidgetsChatExample({super.key});

  @override
  State<RichWidgetsChatExample> createState() => _RichWidgetsChatExampleState();
}

class _RichWidgetsChatExampleState extends State<RichWidgetsChatExample> {
  final _controller = ChatMessagesController();
  bool _isLoading = false;

  static const _currentUser = ChatUser(id: 'user', name: 'You');
  static const _aiUser = ChatUser(id: 'ai', name: 'Parezar AI');

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
        builder: (context) => _StatsWidget(),
      ));
    } else if (text.contains('order') || text.contains('status')) {
      // Rich widget: order status
      _controller.addMessage(ChatMessage.rich(
        user: _aiUser,
        resultKind: 'order_status',
        data: {
          'orderId': 'ORD-2026-4892',
          'status': 'In Transit',
          'eta': 'April 13, 2026',
          'items': 3,
        },
      ));
    } else if (text.contains('loading') || text.contains('morph')) {
      // Loading → morph demo
      const loadId = 'demo-loading';
      _controller.addMessage(ChatMessage.loading(
        user: _aiUser,
        id: loadId,
        loadingKind: 'weather',
      ));
      // After 2 seconds, replace with the actual widget
      Future<void>.delayed(const Duration(seconds: 2), () {
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
            '- "loading" to see shimmer → widget morph',
        user: _aiUser,
        createdAt: DateTime.now(),
        isMarkdown: true,
      ));
    }

    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rich Widget Messages'),
        centerTitle: true,
      ),
      body: AiChatWidget(
        currentUser: _currentUser,
        aiUser: _aiUser,
        controller: _controller,
        onSendMessage: _onSendMessage,
        // Register rich widget renderers by kind
        resultRenderers: {
          'weather': _buildWeatherCard,
          'product': _buildProductCard,
          'order_status': _buildOrderStatusCard,
        },
        resultLoadingRenderers: {
          'weather': (context, data) => const Padding(
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
        },
        loadingConfig: LoadingConfig(
          isLoading: _isLoading,
          loadingIndicator: const LoadingWidget(
            texts: ['Thinking...'],
          ),
        ),
        enableMarkdownStreaming: false,
        welcomeMessageConfig: WelcomeMessageConfig(
          title: 'Rich Widget Messages',
          titleStyle: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
          questionsSectionTitle:
              'AI responses can include interactive widgets. Try these:',
        ),
        exampleQuestions: const [
          ExampleQuestion(question: "What's the weather?"),
          ExampleQuestion(question: 'Show me a product'),
          ExampleQuestion(question: 'Show stats chart'),
          ExampleQuestion(question: 'Check order status'),
        ],
        inputOptions: InputOptions(
          decoration: InputDecoration(
            hintText: 'Try "weather", "product", "stats", or "order"...',
            hintStyle: TextStyle(
              color: isDark ? Colors.white38 : Colors.black38,
              fontSize: 15,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor:
                isDark ? const Color(0xFF2A2A3A) : const Color(0xFFF2F2F7),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          sendButtonIcon: Icons.arrow_upward_rounded,
          sendButtonColor: const Color(0xFF6366F1),
        ),
      ),
    );
  }

  // ─── Result Renderers ───────────────────────────────────────────────

  static Widget _buildWeatherCard(
    BuildContext context,
    Map<String, dynamic> data,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1a237e), const Color(0xFF0d47a1)]
              : [const Color(0xFF42a5f5), const Color(0xFF1976d2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
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
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    data['condition'] as String? ?? '',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
              Text(
                '${data['temp']}°',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.w200,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _WeatherDetail(
                  icon: Icons.water_drop, label: '${data['humidity']}%'),
              const SizedBox(width: 24),
              _WeatherDetail(
                  icon: Icons.air, label: data['wind'] as String? ?? ''),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final features = (data['features'] as List?)?.cast<String>() ?? [];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product icon placeholder
          Container(
            width: double.infinity,
            height: 120,
            decoration: BoxDecoration(
              color: isDark ? Colors.white10 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.laptop_mac,
              size: 48,
              color: isDark ? Colors.white30 : Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            data['name'] as String? ?? '',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                data['price'] as String? ?? '',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6366F1),
                ),
              ),
              const Spacer(),
              const Icon(Icons.star, color: Colors.amber, size: 18),
              const SizedBox(width: 4),
              Text(
                '${data['rating']}',
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
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
                      backgroundColor:
                          isDark ? Colors.white10 : Colors.grey.shade100,
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
              onPressed: () {},
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.local_shipping,
                    color: Colors.green, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['orderId'] as String? ?? '',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    Text(
                      '${data['items']} items',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white54 : Colors.black45,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  data['status'] as String? ?? '',
                  style: const TextStyle(
                    color: Colors.green,
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
              backgroundColor: isDark ? Colors.white12 : Colors.grey.shade200,
              color: Colors.green,
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Estimated delivery',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white54 : Colors.black45,
                ),
              ),
              Text(
                data['eta'] as String? ?? '',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Helper widgets ─────────────────────────────────────────────────────────

class _WeatherDetail extends StatelessWidget {
  const _WeatherDetail({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 16),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
      ],
    );
  }
}

class _StatsWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Monthly Activity',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _Bar(height: 40, label: 'Mon', color: const Color(0xFF6366F1)),
              _Bar(height: 65, label: 'Tue', color: const Color(0xFF6366F1)),
              _Bar(height: 35, label: 'Wed', color: const Color(0xFF6366F1)),
              _Bar(
                  height: 80,
                  label: 'Thu',
                  color: const Color(0xFF6366F1),
                  highlight: true),
              _Bar(height: 55, label: 'Fri', color: const Color(0xFF6366F1)),
              _Bar(height: 25, label: 'Sat', color: Colors.grey.shade400),
              _Bar(height: 20, label: 'Sun', color: Colors.grey.shade400),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _StatItem(label: 'Total', value: '1,284', isDark: isDark),
              _StatItem(label: 'Avg', value: '183/day', isDark: isDark),
              _StatItem(label: 'Peak', value: 'Thu', isDark: isDark),
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
    required this.color,
    this.highlight = false,
  });
  final double height;
  final String label;
  final Color color;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 28,
          height: height,
          decoration: BoxDecoration(
            color: highlight ? color : color.withOpacity(0.5),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white54
                : Colors.black45,
          ),
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.label,
    required this.value,
    required this.isDark,
  });
  final String label;
  final String value;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.white54 : Colors.black45,
          ),
        ),
      ],
    );
  }
}
