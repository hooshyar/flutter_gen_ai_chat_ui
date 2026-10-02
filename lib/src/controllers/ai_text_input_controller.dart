import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/ai_suggestion.dart';

/// Controller for AI-enhanced text input similar to CopilotKit's useCopilotTextarea
/// Provides autocompletion, smart edits, and draft generation capabilities
class AiTextInputController extends ChangeNotifier {
  final AiTextInputConfig config;
  AiTextInputState _state = const AiTextInputState();
  Timer? _suggestionTimer;
  final StreamController<AiSuggestion> _suggestionStreamController =
      StreamController<AiSuggestion>.broadcast();

  AiTextInputController({this.config = const AiTextInputConfig()});

  // Getters
  AiTextInputState get state => _state;
  String get text => _state.text;
  List<AiSuggestion> get suggestions => _state.suggestions;
  AiSuggestion? get activeSuggestion => _state.activeSuggestion;
  bool get isLoading => _state.isLoading;
  String? get error => _state.error;
  Stream<AiSuggestion> get suggestionStream =>
      _suggestionStreamController.stream;

  /// Update text and trigger AI suggestions
  void updateText(String newText) {
    _updateState(_state.copyWith(text: newText, error: null));

    // Cancel existing timer
    _suggestionTimer?.cancel();

    // Start new suggestion timer if text is long enough
    if (newText.length >= config.minCharactersForSuggestion) {
      _suggestionTimer = Timer(config.suggestionDelay, () {
        _generateSuggestions(newText);
      });
    } else {
      _updateState(_state.copyWith(suggestions: []));
    }
  }

  /// Generate AI suggestions for the current text
  Future<void> _generateSuggestions(String text) async {
    if (!_shouldGenerateSuggestions(text)) return;

    _updateState(_state.copyWith(isLoading: true));

    try {
      final suggestions = await _fetchAiSuggestions(text);
      _updateState(_state.copyWith(suggestions: suggestions, isLoading: false));

      // Notify about new suggestions
      if (suggestions.isNotEmpty) {
        _suggestionStreamController.add(suggestions.first);
      }
    } catch (e) {
      _updateState(
        _state.copyWith(
          error: 'Failed to generate suggestions: $e',
          isLoading: false,
        ),
      );
    }
  }

  /// Apply a suggestion to the text
  void applySuggestion(AiSuggestion suggestion) {
    final currentText = _state.text;
    final newText = currentText.replaceRange(
      suggestion.startIndex,
      suggestion.endIndex,
      suggestion.replacementText,
    );

    _updateState(
      _state.copyWith(text: newText, suggestions: [], activeSuggestion: null),
    );
  }

  /// Accept the currently active suggestion
  void acceptSuggestion() {
    if (_state.activeSuggestion != null) {
      applySuggestion(_state.activeSuggestion!);
    }
  }

  /// Reject the currently active suggestion
  void rejectSuggestion() {
    _updateState(
      _state.copyWith(
        activeSuggestion: null,
        suggestions: _state.suggestions
            .where((s) => s != _state.activeSuggestion)
            .toList(),
      ),
    );
  }

  /// Set active suggestion for preview
  void setActiveSuggestion(AiSuggestion? suggestion) {
    _updateState(_state.copyWith(activeSuggestion: suggestion));
  }

  /// Generate an auto-first-draft for the given prompt
  Future<String> generateFirstDraft(String prompt) async {
    if (!config.enableAutoDrafts) {
      throw UnsupportedError('Auto drafts are disabled');
    }

    _updateState(_state.copyWith(isLoading: true));

    try {
      final draft = await _fetchFirstDraft(prompt);
      _updateState(_state.copyWith(text: draft, isLoading: false));
      return draft;
    } catch (e) {
      _updateState(
        _state.copyWith(
          error: 'Failed to generate draft: $e',
          isLoading: false,
        ),
      );
      rethrow;
    }
  }

  /// Stream enhanced text with real-time improvements
  Stream<String> streamEnhancedText(String originalText) async* {
    if (!config.enableSmartEdits) {
      yield originalText;
      return;
    }

    _updateState(_state.copyWith(isLoading: true));

    try {
      yield* _streamTextEnhancements(originalText);
    } finally {
      _updateState(_state.copyWith(isLoading: false));
    }
  }

  /// Clear all suggestions and reset state
  void clearSuggestions() {
    _updateState(
      _state.copyWith(suggestions: [], activeSuggestion: null, error: null),
    );
  }

  /// Reset the entire input state
  void reset() {
    _suggestionTimer?.cancel();
    _updateState(const AiTextInputState());
  }

  // Private methods

  bool _shouldGenerateSuggestions(String text) {
    return text.length >= config.minCharactersForSuggestion &&
        (config.enableAutoComplete ||
            config.enableGrammarCheck ||
            config.enableSmartEdits);
  }

  Future<List<AiSuggestion>> _fetchAiSuggestions(String text) async {
    // Simulate AI suggestion generation
    await Future<void>.delayed(const Duration(milliseconds: 300));

    final suggestions = <AiSuggestion>[];
    final words = text.split(' ');
    final lastWord = words.isNotEmpty ? words.last : '';

    // Generate completion suggestions
    if (config.enabledSuggestionTypes.contains(AiSuggestionType.completion) &&
        config.enableAutoComplete &&
        lastWord.isNotEmpty) {
      suggestions.addAll(_generateCompletionSuggestions(text, lastWord));
    }

    // Generate grammar suggestions
    if (config.enabledSuggestionTypes.contains(AiSuggestionType.grammar) &&
        config.enableGrammarCheck) {
      suggestions.addAll(_generateGrammarSuggestions(text));
    }

    // Generate enhancement suggestions
    if (config.enabledSuggestionTypes.contains(AiSuggestionType.enhancement) &&
        config.enableSmartEdits) {
      suggestions.addAll(_generateEnhancementSuggestions(text));
    }

    return suggestions.take(config.maxSuggestions).toList();
  }

  List<AiSuggestion> _generateCompletionSuggestions(
    String text,
    String lastWord,
  ) {
    final completions = [
      'intelligence',
      'interactive',
      'innovative',
      'implementation',
      'integration',
    ].where((word) => word.startsWith(lastWord.toLowerCase())).take(2);

    return completions
        .map(
          (completion) => AiSuggestion(
            id: 'completion_${completion}_${DateTime.now().millisecondsSinceEpoch}',
            text: lastWord,
            replacementText: completion,
            startIndex: text.length - lastWord.length,
            endIndex: text.length,
            type: AiSuggestionType.completion,
            confidence: 0.8,
          ),
        )
        .toList();
  }

  List<AiSuggestion> _generateGrammarSuggestions(String text) {
    final suggestions = <AiSuggestion>[];

    // Simple grammar check for common mistakes
    if (text.contains('teh')) {
      final index = text.indexOf('teh');
      suggestions.add(
        AiSuggestion(
          id: 'grammar_the_${DateTime.now().millisecondsSinceEpoch}',
          text: 'teh',
          replacementText: 'the',
          startIndex: index,
          endIndex: index + 3,
          type: AiSuggestionType.grammar,
          confidence: 0.95,
        ),
      );
    }

    return suggestions;
  }

  List<AiSuggestion> _generateEnhancementSuggestions(String text) {
    final suggestions = <AiSuggestion>[];

    // Simple enhancement: replace "good" with "excellent"
    if (text.contains('good')) {
      final index = text.indexOf('good');
      suggestions.add(
        AiSuggestion(
          id: 'enhance_good_${DateTime.now().millisecondsSinceEpoch}',
          text: 'good',
          replacementText: 'excellent',
          startIndex: index,
          endIndex: index + 4,
          type: AiSuggestionType.enhancement,
          confidence: 0.7,
        ),
      );
    }

    return suggestions;
  }

  Future<String> _fetchFirstDraft(String prompt) async {
    // Simulate AI draft generation
    await Future<void>.delayed(const Duration(milliseconds: 800));

    return 'This is an AI-generated first draft based on your prompt: "$prompt". '
        'The AI has analyzed your request and provided this initial content. '
        'You can edit and refine this draft as needed.';
  }

  Stream<String> _streamTextEnhancements(String originalText) async* {
    // Simulate streaming text enhancements
    final enhancements = [
      originalText,
      originalText.replaceAll('good', 'excellent'),
      originalText
          .replaceAll('good', 'excellent')
          .replaceAll('nice', 'wonderful'),
    ];

    for (final enhancement in enhancements) {
      await Future<void>.delayed(const Duration(milliseconds: 200));
      yield enhancement;
    }
  }

  void _updateState(AiTextInputState newState) {
    _state = newState;
    notifyListeners();
  }

  @override
  void dispose() {
    _suggestionTimer?.cancel();
    _suggestionStreamController.close();
    super.dispose();
  }
}
