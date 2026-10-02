// AI Actions - demonstrates function calling with calculator, weather, and color actions.
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';

import '../shell/app_theme.dart';
import '../shell/demo_scaffold.dart';

class ActionsChatExample extends StatefulWidget {
  const ActionsChatExample({super.key, required this.onToggleTheme});

  final VoidCallback onToggleTheme;

  @override
  State<ActionsChatExample> createState() => _ActionsChatExampleState();
}

class _ActionsChatExampleState extends State<ActionsChatExample> {
  final _controller = ChatMessagesController();
  final _actionController = ActionController();
  bool _isLoading = false;

  // Each tool invocation gets its own counter value so the tool-call text
  // message and its result card always carry distinct, explicit ids - two
  // id-less messages added back-to-back can otherwise collide on web, where
  // `DateTime.now()` only has millisecond resolution (see CHANGELOG "Known
  // limitation" and backlog/tasks/task-035).
  int _actionCallCounter = 0;

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
        // Deterministic per city - same question, same forecast.
        final seed = city.toLowerCase().codeUnits.fold<int>(0, (a, b) => a + b);
        final tempC = 8 + seed % 25; // 8-32 C
        final temp =
            units == 'fahrenheit' ? (tempC * 9 / 5 + 32).round() : tempC;
        // Tie conditions to temperature so 32C never reports rain.
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
  /// wire - as a highlighted ```json fence - so the demo reads like real
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
          if (mounted) {
            final callId = _actionCallCounter++;
            _controller.addMessage(ChatMessage(
              text: 'Calling the calculator tool:\n\n'
                  '${_toolCallBlock('calculate', {'expression': expr})}',
              user: _aiUser,
              createdAt: DateTime.now(),
              isMarkdown: true,
              customProperties: {'id': 'tool-call-$callId'},
            ));
            _controller.addMessage(ChatMessage.rich(
              user: _aiUser,
              resultKind: 'action_result',
              data: {
                'label': 'Result',
                'value': '${data['expression']} = ${data['result']}',
              },
              id: 'tool-result-$callId',
            ));
          }
          return;
        }
        response =
            'Could not calculate that. Try something like "calculate 5 + 3".';
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
          final unit = d['units'] == 'celsius' ? '°C' : '°F';
          if (mounted) {
            final callId = _actionCallCounter++;
            _controller.addMessage(ChatMessage(
              text: 'Calling the weather tool:\n\n'
                  '${_toolCallBlock('get_weather', {'city': city})}',
              user: _aiUser,
              createdAt: DateTime.now(),
              isMarkdown: true,
              customProperties: {'id': 'tool-call-$callId'},
            ));
            _controller.addMessage(ChatMessage.rich(
              user: _aiUser,
              resultKind: 'action_result',
              data: {
                'label': 'Result',
                'value': '${d['city']}: ${d['conditions']}, '
                    '${d['temperature']}$unit, humidity ${d['humidity']}%',
              },
              id: 'tool-result-$callId',
            ));
          }
          return;
        }
        response = 'Could not get weather. Try "/weather London".';
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
                  'Here is your swatch:',
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
            '- `/calculate 42 * 7` - evaluate a math expression\n'
            '- `/weather Paris` - weather for a city\n'
            '- `/color energetic` - turn a mood into a color swatch';
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

    return DemoScaffold(
      title: 'Actions',
      route: '/actions',
      isDark: isDark,
      onToggleTheme: widget.onToggleTheme,
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
          // Tool results render as a compact card after the ```json call
          // block, not another line of markdown - the full-width rich-result
          // path skips the normal bubble's sender-change top gap, so
          // `_cardTopSpacing` restores it (DESIGN.md §9 "Actions").
          resultRenderers: {
            'action_result': (context, data) =>
                _cardTopSpacing(_ResultCard(data: data)),
          },
          loadingConfig: LoadingConfig(
            isLoading: _isLoading,
            loadingIndicator: const LoadingWidget(
              texts: ['Executing action...', 'Processing...'],
            ),
          ),
          welcomeMessageConfig: const WelcomeMessageConfig(
            title: 'AI Actions Demo',
            questionsSectionTitle: 'Try these actions:',
          ),
          exampleQuestions: const [
            ExampleQuestion(question: '/calculate 42 * 7'),
            ExampleQuestion(question: '/weather Paris'),
            ExampleQuestion(question: '/color energetic'),
          ],
        ),
      ),
    );
  }
}

/// Full-width rich results (the tool-result card) render through
/// [AiChatWidget.resultRenderers], which bypasses the normal bubble path and
/// its sender-change top gap. Wrapping the card in this gives it the same
/// [ChatSpace.s24] gap a text reply gets after the preceding message
/// (DESIGN.md §9 "Rich results", mirrored here for tool results).
Widget _cardTopSpacing(Widget child) {
  return Padding(
      padding: const EdgeInsets.only(top: ChatSpace.s24), child: child);
}

/// Compact tool-result card shown after the `_toolCallBlock` JSON fence: a
/// "Result" label plus the value, tokens from [AppColors] (radius 12, 1px
/// outline, no shadow). DESIGN.md §9 "Actions": "Tool calls rendered as
/// code, then a result card."
class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.data});

  final Map<String, dynamic> data;

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
            data['label'] as String? ?? 'Result',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            data['value'] as String? ?? '',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Inline widget message for `/color` - shows the generated colour as an
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
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              // The swatch itself is the generated result data, not chat
              // chrome - it must render the actual returned colour.
              color: _color,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colors.border),
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
                  color: colors.textPrimary,
                ),
              ),
              Text(
                hex,
                style: TextStyle(
                  fontSize: 13,
                  fontFamily: 'monospace',
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
