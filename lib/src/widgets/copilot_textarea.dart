import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/ai_action.dart';
import '../utils/color_extensions.dart';

/// A drop-in replacement for TextField that provides AI-powered assistance
/// Equivalent to CopilotKit's CopilotTextarea component
///
/// Features:
/// - AI-powered text completion and suggestions
/// - Context-aware assistance based on app state
/// - Smart text editing and enhancement
/// - Seamless integration with existing form fields
class CopilotTextarea extends StatefulWidget {
  /// The text controller for this field
  final TextEditingController? controller;

  /// Placeholder text when the field is empty
  final String? placeholder;

  /// Instructions for the AI about what kind of text to help with
  final String aiInstructions;

  /// Minimum number of lines to display
  final int minLines;

  /// Maximum number of lines to display (null for unlimited)
  final int? maxLines;

  /// Called when the text changes
  final ValueChanged<String>? onChanged;

  /// Called when the user submits the text (e.g., presses enter)
  final ValueChanged<String>? onSubmitted;

  /// Input decoration for styling the text field
  final InputDecoration? decoration;

  /// Text style for the input
  final TextStyle? style;

  /// Whether to show AI suggestions inline
  final bool showInlineSuggestions;

  /// Whether to enable AI-powered text completion
  final bool enableCompletion;

  /// Custom AI actions that can be triggered from this textarea
  final List<AiAction>? actions;

  /// Function to get AI completions/suggestions
  final Future<String> Function(String text, String instructions)? onAiComplete;

  /// Function to get AI suggestions for the current text
  final Future<List<String>> Function(String text, String instructions)?
      onAiSuggest;

  const CopilotTextarea({
    super.key,
    this.controller,
    this.placeholder,
    this.aiInstructions = 'Help improve and complete this text',
    this.minLines = 1,
    this.maxLines,
    this.onChanged,
    this.onSubmitted,
    this.decoration,
    this.style,
    this.showInlineSuggestions = true,
    this.enableCompletion = true,
    this.actions,
    this.onAiComplete,
    this.onAiSuggest,
  });

  @override
  State<CopilotTextarea> createState() => _CopilotTextareaState();
}

class _CopilotTextareaState extends State<CopilotTextarea> {
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();

  OverlayEntry? _suggestionOverlay;
  List<String> _suggestions = [];
  bool _showSuggestions = false;
  bool _isLoadingSuggestions = false;
  String _lastTextForSuggestions = '';

  /// Tracked debounce timer for AI suggestion fetches (iter 3). Cancelled on
  /// dispose so widget tests don't leave a pending timer after teardown.
  Timer? _suggestionDebounceTimer;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _suggestionDebounceTimer?.cancel();
    _suggestionDebounceTimer = null;
    // Inline overlay cleanup — calling _hideSuggestions() here would invoke
    // setState() during dispose, which trips the `defunct` assertion in
    // Element.markNeedsBuild (pre-existing bug; iter 3).
    _suggestionOverlay?.remove();
    _suggestionOverlay = null;
    _showSuggestions = false;
    _focusNode
      ..removeListener(_onFocusChanged)
      ..dispose();
    if (widget.controller == null) {
      _controller.dispose();
    } else {
      _controller.removeListener(_onTextChanged);
    }
    super.dispose();
  }

  void _onTextChanged() {
    widget.onChanged?.call(_controller.text);

    if (widget.showInlineSuggestions &&
        _controller.text != _lastTextForSuggestions &&
        _controller.text.length > 3) {
      _debounceGetSuggestions();
    } else if (_controller.text.length <= 3) {
      _hideSuggestions();
    }
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus) {
      _hideSuggestions();
    }
  }

  void _debounceGetSuggestions() {
    // Tracked debounce timer (iter 3) — replaces an untracked Future.delayed
    // so dispose can cancel the pending fetch.
    _suggestionDebounceTimer?.cancel();
    _suggestionDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      _suggestionDebounceTimer = null;
      if (!mounted) return;
      if (_controller.text == _lastTextForSuggestions) return;
      _getSuggestions();
    });
  }

  Future<void> _getSuggestions() async {
    if (_isLoadingSuggestions || !mounted) return;

    setState(() {
      _isLoadingSuggestions = true;
    });

    try {
      final text = _controller.text;
      _lastTextForSuggestions = text;

      List<String> suggestions;

      if (widget.onAiSuggest != null) {
        // Use custom suggestion function
        suggestions = await widget.onAiSuggest!(text, widget.aiInstructions);
      } else {
        // Use default suggestions logic
        suggestions = await _getDefaultSuggestions(text);
      }

      if (mounted && text == _controller.text) {
        setState(() {
          _suggestions = suggestions;
          _showSuggestions = suggestions.isNotEmpty;
          _isLoadingSuggestions = false;
        });

        if (_showSuggestions) {
          _showSuggestionOverlay();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingSuggestions = false;
          _showSuggestions = false;
        });
      }
    }
  }

  Future<List<String>> _getDefaultSuggestions(String text) async {
    // Default suggestions logic - could be replaced with actual AI calls
    final words = text.split(' ');
    final lastWord = words.isNotEmpty ? words.last.toLowerCase() : '';

    // Simple suggestion logic based on common patterns
    final suggestions = <String>[];

    if (lastWord.contains('hello')) {
      suggestions
          .addAll(['Hello there!', 'Hello, how can I help?', 'Hello world!']);
    } else if (lastWord.contains('thank')) {
      suggestions.addAll([
        'Thank you very much',
        'Thank you for your time',
        'Thanks for the help'
      ]);
    } else if (lastWord.contains('please')) {
      suggestions.addAll([
        'Please let me know',
        'Please consider this',
        'Please help me with'
      ]);
    } else if (text.endsWith('?')) {
      suggestions.addAll([
        'I would appreciate your response.',
        'Looking forward to hearing from you.'
      ]);
    } else {
      // Generic completion suggestions
      suggestions.addAll([
        '$text and provide more details.',
        '$text with additional context.',
        '$text for better understanding.',
      ]);
    }

    return suggestions.take(3).toList();
  }

  void _showSuggestionOverlay() {
    _hideSuggestions();

    _suggestionOverlay = OverlayEntry(
      builder: (context) => Positioned(
        width: 300,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 40),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .outline
                      .withOpacityCompat(0.2),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'AI Suggestions',
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  ..._suggestions.map(_buildSuggestionItem),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_suggestionOverlay!);
  }

  Widget _buildSuggestionItem(String suggestion) {
    return InkWell(
      onTap: () => _applySuggestion(suggestion),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                suggestion,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              Icons.keyboard_tab,
              size: 16,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  void _applySuggestion(String suggestion) {
    _controller.text = suggestion;
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: suggestion.length),
    );
    _hideSuggestions();
    widget.onChanged?.call(suggestion);
  }

  void _hideSuggestions() {
    _suggestionOverlay?.remove();
    _suggestionOverlay = null;
    setState(() {
      _showSuggestions = false;
    });
  }

  Future<void> _triggerCompletion() async {
    if (!widget.enableCompletion || widget.onAiComplete == null) return;

    try {
      final currentText = _controller.text;
      final completion =
          await widget.onAiComplete!(currentText, widget.aiInstructions);

      if (mounted && completion.isNotEmpty) {
        _controller.text = completion;
        _controller.selection = TextSelection.fromPosition(
          TextPosition(offset: completion.length),
        );
        widget.onChanged?.call(completion);
      }
    } catch (e) {
      // Handle completion error silently or show a brief message
      debugPrint('AI completion failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CallbackShortcuts(
            bindings: {
              // Ctrl+Space or Cmd+Space to trigger AI completion
              LogicalKeySet(
                LogicalKeyboardKey.space,
                defaultTargetPlatform == TargetPlatform.macOS
                    ? LogicalKeyboardKey.meta
                    : LogicalKeyboardKey.control,
              ): _triggerCompletion,
              // Tab to accept first suggestion
              const SingleActivator(LogicalKeyboardKey.tab): () {
                if (_showSuggestions && _suggestions.isNotEmpty) {
                  _applySuggestion(_suggestions.first);
                }
              },
              // Escape to hide suggestions
              const SingleActivator(LogicalKeyboardKey.escape):
                  _hideSuggestions,
            },
            child: Focus(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                minLines: widget.minLines,
                maxLines: widget.maxLines,
                style: widget.style,
                onSubmitted: widget.onSubmitted,
                decoration:
                    (widget.decoration ?? const InputDecoration()).copyWith(
                  hintText: widget.placeholder,
                  suffixIcon: _buildSuffixIcon(),
                ),
              ),
            ),
          ),
          if (_isLoadingSuggestions)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 1.5),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Getting AI suggestions...',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget? _buildSuffixIcon() {
    if (!widget.enableCompletion) return null;

    return IconButton(
      icon: const Icon(Icons.auto_awesome),
      onPressed: _triggerCompletion,
      tooltip:
          'AI Complete (${defaultTargetPlatform == TargetPlatform.macOS ? 'Cmd' : 'Ctrl'}+Space)',
      iconSize: 20,
    );
  }
}
