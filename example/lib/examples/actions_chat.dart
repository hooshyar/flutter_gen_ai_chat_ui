// AI Actions — demonstrates function calling with calculator, weather, and color actions.
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';

class ActionsChatExample extends StatefulWidget {
  const ActionsChatExample({super.key});

  @override
  State<ActionsChatExample> createState() => _ActionsChatExampleState();
}

class _ActionsChatExampleState extends State<ActionsChatExample> {
  final _controller = ChatMessagesController();
  final _actionController = ActionController();
  bool _isLoading = false;

  static const _currentUser = ChatUser(id: 'user', name: 'You');
  static const _aiUser = ChatUser(id: 'ai', name: 'Agent');

  @override
  void initState() {
    super.initState();
    _registerActions();
  }

  void _registerActions() {
    _actionController.registerAction(AiAction(
      name: 'calculate',
      description: 'Perform a math calculation',
      parameters: [
        ActionParameter.string(
          name: 'expression',
          description: 'Math expression like "5 + 3" or "12 * 4"',
          required: true,
        ),
      ],
      handler: (params) async {
        await Future.delayed(const Duration(milliseconds: 500));
        final expr = params['expression'] as String;
        final result = _evaluateExpression(expr);
        if (result != null) {
          return ActionResult.createSuccess(
              {'expression': expr, 'result': result});
        }
        return ActionResult.createFailure('Could not evaluate "$expr"');
      },
    ));

    _actionController.registerAction(AiAction(
      name: 'get_weather',
      description: 'Get weather for a city',
      parameters: [
        ActionParameter.string(
          name: 'city',
          description: 'City name',
          required: true,
        ),
        ActionParameter.string(
          name: 'units',
          description: 'Temperature units',
          enumValues: ['celsius', 'fahrenheit'],
          defaultValue: 'celsius',
        ),
      ],
      handler: (params) async {
        await Future.delayed(const Duration(milliseconds: 800));
        final city = params['city'] as String;
        final units = params['units'] as String? ?? 'celsius';
        // Deterministic per city — same question, same forecast.
        final seed = city.toLowerCase().codeUnits.fold<int>(0, (a, b) => a + b);
        final tempC = 8 + seed % 25; // 8–32°C
        final temp =
            units == 'fahrenheit' ? (tempC * 9 / 5 + 32).round() : tempC;
        // Tie conditions to temperature so 32°C never reports rain.
        final conditions = tempC >= 26
            ? 'Sunny'
            : tempC >= 18
                ? 'Partly Cloudy'
                : tempC >= 10
                    ? 'Overcast'
                    : 'Light Rain';
        return ActionResult.createSuccess({
          'city': city,
          'temperature': temp,
          'units': units,
          'conditions': conditions,
          'humidity': 35 + seed % 45,
        });
      },
    ));

    _actionController.registerAction(AiAction(
      name: 'generate_color',
      description: 'Generate a color from a mood',
      parameters: [
        ActionParameter.string(
          name: 'mood',
          description: 'A mood or feeling (e.g. calm, energetic, warm)',
          required: true,
        ),
      ],
      handler: (params) async {
        await Future.delayed(const Duration(milliseconds: 400));
        final mood = (params['mood'] as String).toLowerCase();
        final colors = {
          'calm': '#4FC3F7',
          'energetic': '#FF5722',
          'warm': '#FFA726',
          'cool': '#26C6DA',
          'happy': '#FFEE58',
          'sad': '#5C6BC0',
          'nature': '#66BB6A',
          'love': '#EC407A',
        };
        final hex = colors[mood] ??
            '#${Random().nextInt(0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
        return ActionResult.createSuccess({'mood': mood, 'color': hex});
      },
    ));
  }

  double? _evaluateExpression(String expr) {
    final cleaned = expr.replaceAll(' ', '');
    final match =
        RegExp(r'^(-?\d+\.?\d*)([\+\-\*\/])(-?\d+\.?\d*)$').firstMatch(cleaned);
    if (match == null) return null;
    final a = double.tryParse(match.group(1)!);
    final op = match.group(2)!;
    final b = double.tryParse(match.group(3)!);
    if (a == null || b == null) return null;
    switch (op) {
      case '+':
        return a + b;
      case '-':
        return a - b;
      case '*':
        return a * b;
      case '/':
        return b != 0 ? a / b : null;
      default:
        return null;
    }
  }

  /// Renders a tool call the way an LLM function call would appear on the
  /// wire — as a highlighted ```json fence — so the demo reads like real
  /// function calling instead of a summary.
  String _toolCallBlock(String name, Map<String, dynamic> arguments) {
    final payload = {'name': name, 'arguments': arguments};
    return '```json\n'
        '${const JsonEncoder.withIndent('  ').convert(payload)}'
        '\n```';
  }

  void _onSendMessage(ChatMessage message) async {
    _controller.addMessage(message);
    setState(() => _isLoading = true);

    try {
      // Parse the ORIGINAL input (not a lowercased copy) so "/weather Paris"
      // displays "Paris", not "paris". `lower` is only used for matching.
      final raw = message.text.trim();
      final lower = raw.toLowerCase();
      String response;

      if (lower.startsWith('/calculate') || lower.contains('calculate')) {
        final expr = raw
            .replaceFirst(RegExp(r'.*?calculate\s*', caseSensitive: false), '')
            .trim();
        final result = await _actionController
            .executeAction('calculate', {'expression': expr});
        if (result.success) {
          final data = result.data as Map<String, dynamic>;
          response = 'Calling the calculator tool:\n\n'
              '${_toolCallBlock('calculate', {'expression': expr})}\n\n'
              '**Result:** `${data['expression']}` = **${data['result']}**';
        } else {
          response =
              'Could not calculate that. Try something like "calculate 5 + 3".';
        }
      } else if (lower.startsWith('/weather') || lower.contains('weather')) {
        var city = raw
            .replaceFirst(
                RegExp(r'.*?weather\s*(in\s+)?', caseSensitive: false), '')
            .trim();
        if (city.isEmpty) city = 'London';
        final result = await _actionController.executeAction('get_weather', {
          'city': city,
        });
        if (result.success) {
          final d = result.data as Map<String, dynamic>;
          response = 'Calling the weather tool:\n\n'
              '${_toolCallBlock('get_weather', {'city': city})}\n\n'
              '**Weather in ${d['city']}**\n\n'
              '- ${d['conditions']}\n'
              '- Temperature: ${d['temperature']}${d['units'] == 'celsius' ? '\u00b0C' : '\u00b0F'}\n'
              '- Humidity: ${d['humidity']}%';
        } else {
          response = 'Could not get weather. Try "/weather London".';
        }
      } else if (lower.startsWith('/color') || lower.contains('color')) {
        var mood = raw
            .replaceFirst(
                RegExp(r'.*?colou?r\s*(for\s+)?', caseSensitive: false), '')
            .trim();
        if (mood.isEmpty) mood = 'calm';
        final result = await _actionController.executeAction('generate_color', {
          'mood': mood,
        });
        if (result.success) {
          final d = result.data as Map<String, dynamic>;
          // A swatch reads better than a bare hex string.
          if (mounted) {
            _controller.addMessage(ChatMessage(
              text: 'Calling the color tool:\n\n'
                  '${_toolCallBlock('generate_color', {'mood': mood})}\n\n'
                  'Here\'s your swatch:',
              user: _aiUser,
              createdAt: DateTime.now(),
              isMarkdown: true,
            ));
            _controller.addMessage(ChatMessage.widget(
              user: _aiUser,
              builder: (context) => _ColorSwatch(
                mood: d['mood'] as String,
                hex: d['color'] as String,
              ),
            ));
          }
          return;
        }
        response = 'Could not generate color. Try "/color calm".';
      } else {
        response = 'I can run a few demo actions. Try:\n\n'
            '- `/calculate 42 * 7` — evaluate a math expression\n'
            '- `/weather Paris` — weather for a city\n'
            '- `/color energetic` — turn a mood into a color swatch';
      }

      if (!mounted) return;
      _controller.addMessage(ChatMessage(
        text: response,
        user: _aiUser,
        createdAt: DateTime.now(),
        isMarkdown: true,
      ));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _actionController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('AI Actions')),
      body: AiActionProvider(
        config: AiActionConfig(
          actions: _actionController.registeredActions,
        ),
        controller: _actionController,
        child: AiChatWidget(
          maxWidth: 720,
          currentUser: _currentUser,
          aiUser: _aiUser,
          controller: _controller,
          onSendMessage: _onSendMessage,
          enableMarkdownStreaming: true,
          loadingConfig: LoadingConfig(
            isLoading: _isLoading,
            loadingIndicator: const LoadingWidget(
              texts: ['Executing action...', 'Processing...'],
            ),
          ),
          welcomeMessageConfig: WelcomeMessageConfig(
            centerVertically: true,
            title: 'AI Actions Demo',
            titleStyle: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black87,
            ),
            containerDecoration: BoxDecoration(
              color: isDark ? const Color(0xFF2A2A3A) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color:
                    isDark ? const Color(0xFF2A2A3A) : const Color(0xFFE5E7EB),
              ),
            ),
            questionsSectionTitle: 'Try these actions:',
            questionsSectionTitleStyle: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white54 : Colors.black45,
            ),
          ),
          exampleQuestions: const [
            ExampleQuestion(question: '/calculate 42 * 7'),
            ExampleQuestion(question: '/weather Paris'),
            ExampleQuestion(question: '/color energetic'),
          ],
          inputOptions: InputOptions(
            decoration: InputDecoration(
              hintText: 'Try /calculate, /weather, /color...',
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
            sendButtonColor: const Color(0xFF8B5CF6),
            sendButtonIconSize: 20,
            sendButtonPadding: const EdgeInsets.all(6),
            textStyle: TextStyle(
              fontSize: 15,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          messageOptions: MessageOptions(
            showCopyButton: true,
            showTime: true,
            bubbleStyle: BubbleStyle(
              userBubbleColor:
                  isDark ? const Color(0xFF6D28D9) : const Color(0xFF8B5CF6),
              aiBubbleColor:
                  isDark ? const Color(0xFF2A2A3A) : const Color(0xFFF5F0FF),
              // White on the coloured user bubble; a light tone keeps the
              // AI name legible on dark AI bubbles.
              userNameColor: Colors.white70,
              aiNameColor: isDark ? Colors.white70 : const Color(0xFF8B5CF6),
              userBubbleTopLeftRadius: 18,
              userBubbleTopRightRadius: 18,
              aiBubbleTopLeftRadius: 18,
              aiBubbleTopRightRadius: 18,
              bottomLeftRadius: 18,
              bottomRightRadius: 4,
            ),
            userTextColor: Colors.white,
            aiTextColor:
                isDark ? Colors.white.withValues(alpha: 0.95) : Colors.black87,
            userTimeTextStyle: const TextStyle(
              fontSize: 11,
              letterSpacing: 0.1,
              color: Colors.white70,
            ),
          ),
        ),
      ),
    );
  }
}

/// Inline widget message for `/color` — shows the generated colour as an
/// actual swatch next to its hex value instead of text alone.
class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch({required this.mood, required this.hex});

  final String mood;
  final String hex;

  Color get _color {
    final value = int.tryParse(hex.replaceFirst('#', ''), radix: 16) ?? 0;
    return Color(0xFF000000 | value);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _color,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.black12),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Color for "$mood"',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              Text(
                hex,
                style: TextStyle(
                  fontSize: 13,
                  fontFamily: 'monospace',
                  color: isDark ? Colors.white54 : Colors.black45,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
