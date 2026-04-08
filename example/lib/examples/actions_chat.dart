// AI Actions — demonstrates function calling with calculator, weather, and color actions.
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';

import '../services/mock_ai_service.dart';

class ActionsChatExample extends StatefulWidget {
  const ActionsChatExample({super.key});

  @override
  State<ActionsChatExample> createState() => _ActionsChatExampleState();
}

class _ActionsChatExampleState extends State<ActionsChatExample> {
  final _controller = ChatMessagesController();
  final _actionController = ActionController();
  final _aiService = ExampleAiService(style: ResponseStyle.plain);
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
          return ActionResult.createSuccess({'expression': expr, 'result': result});
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
        final random = Random();
        final tempC = 15 + random.nextInt(20);
        final temp = units == 'fahrenheit' ? (tempC * 9 / 5 + 32).round() : tempC;
        final conditions = ['Sunny', 'Partly Cloudy', 'Overcast', 'Light Rain'][random.nextInt(4)];
        return ActionResult.createSuccess({
          'city': city,
          'temperature': temp,
          'units': units,
          'conditions': conditions,
          'humidity': 40 + random.nextInt(40),
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
        final hex = colors[mood] ?? '#${Random().nextInt(0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
        return ActionResult.createSuccess({'mood': mood, 'color': hex});
      },
    ));
  }

  double? _evaluateExpression(String expr) {
    final cleaned = expr.replaceAll(' ', '');
    final match = RegExp(r'^(-?\d+\.?\d*)([\+\-\*\/])(-?\d+\.?\d*)$').firstMatch(cleaned);
    if (match == null) return null;
    final a = double.tryParse(match.group(1)!);
    final op = match.group(2)!;
    final b = double.tryParse(match.group(3)!);
    if (a == null || b == null) return null;
    switch (op) {
      case '+': return a + b;
      case '-': return a - b;
      case '*': return a * b;
      case '/': return b != 0 ? a / b : null;
      default: return null;
    }
  }

  void _onSendMessage(ChatMessage message) async {
    _controller.addMessage(message);
    setState(() => _isLoading = true);

    try {
      final text = message.text.trim().toLowerCase();
      String response;

      if (text.startsWith('/calculate ') || text.contains('calculate')) {
        final expr = text.replaceFirst('/calculate ', '').replaceFirst(RegExp(r'.*calculate\s*'), '');
        final result = await _actionController.executeAction('calculate', {'expression': expr});
        if (result.success) {
          final data = result.data as Map<String, dynamic>;
          response = '**Calculator**\n\n`${data['expression']}` = **${data['result']}**';
        } else {
          response = 'Could not calculate that. Try something like "calculate 5 + 3".';
        }
      } else if (text.startsWith('/weather ') || text.contains('weather')) {
        final city = text.replaceFirst('/weather ', '').replaceFirst(RegExp(r'.*weather\s*(in\s*)?'), '').trim();
        final result = await _actionController.executeAction('get_weather', {
          'city': city.isNotEmpty ? city : 'London',
        });
        if (result.success) {
          final d = result.data as Map<String, dynamic>;
          response = '**Weather in ${d['city']}**\n\n'
              '- ${d['conditions']}\n'
              '- Temperature: ${d['temperature']}${d['units'] == 'celsius' ? '\u00b0C' : '\u00b0F'}\n'
              '- Humidity: ${d['humidity']}%';
        } else {
          response = 'Could not get weather. Try "/weather London".';
        }
      } else if (text.startsWith('/color ') || text.contains('color')) {
        final mood = text.replaceFirst('/color ', '').replaceFirst(RegExp(r'.*color\s*(for\s*)?'), '').trim();
        final result = await _actionController.executeAction('generate_color', {
          'mood': mood.isNotEmpty ? mood : 'calm',
        });
        if (result.success) {
          final d = result.data as Map<String, dynamic>;
          response = '**Color for "${d['mood']}"**\n\n`${d['color']}`';
        } else {
          response = 'Could not generate color. Try "/color calm".';
        }
      } else {
        response = await _aiService.generateResponse(message.text);
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
                color: isDark
                    ? const Color(0xFF2A2A3A)
                    : const Color(0xFFE5E7EB),
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
              fillColor: isDark ? const Color(0xFF2A2A3A) : const Color(0xFFF2F2F7),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
              userBubbleColor: isDark ? const Color(0xFF6D28D9) : const Color(0xFF8B5CF6),
              aiBubbleColor: isDark ? const Color(0xFF2A2A3A) : const Color(0xFFF5F0FF),
              userBubbleTopLeftRadius: 18,
              userBubbleTopRightRadius: 18,
              aiBubbleTopLeftRadius: 18,
              aiBubbleTopRightRadius: 18,
              bottomLeftRadius: 18,
              bottomRightRadius: 4,
            ),
            userTextColor: Colors.white,
            aiTextColor: isDark ? Colors.white.withValues(alpha: 0.95) : Colors.black87,
          ),
        ),
      ),
    );
  }
}
