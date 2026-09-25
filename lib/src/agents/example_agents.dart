import 'dart:async';
import 'dart:math';

import '../models/ai_agent.dart';

/// Text analysis specialist agent
class TextAnalysisAgent extends AIAgent {
  final StreamController<AgentState> _stateController =
      StreamController<AgentState>.broadcast();
  AgentStatus _status = AgentStatus.initializing;
  String? _currentTask;

  TextAnalysisAgent()
      : super(
          id: 'text_analysis_001',
          name: 'Text Analysis Specialist',
          specialization: 'Natural language processing and text analysis',
          capabilities: [
            'sentiment_analysis',
            'text_summarization',
            'language_detection',
            'readability_analysis',
            'grammar_check',
          ],
          priority: AgentPriority.high,
        );

  @override
  Future<void> initialize(Map<String, dynamic> config) async {
    _status = AgentStatus.idle;
    _emitState();
  }

  @override
  bool canHandle(AgentRequest request) {
    final queryLower = request.query.toLowerCase();
    return capabilities.any(
          (capability) => queryLower.contains(capability.replaceAll('_', ' ')),
        ) ||
        queryLower.contains('analyze') ||
        queryLower.contains('text') ||
        queryLower.contains('sentiment') ||
        queryLower.contains('summarize');
  }

  @override
  Future<AgentResponse> processRequest(AgentRequest request) async {
    _status = AgentStatus.processing;
    _currentTask = 'Processing: ${request.query}';
    _emitState();

    try {
      // Simulate processing time
      await Future<void>.delayed(const Duration(milliseconds: 800));

      final queryLower = request.query.toLowerCase();
      String content;
      final metadata = <String, dynamic>{};

      if (queryLower.contains('sentiment')) {
        content = _analyzeSentiment(request.query);
        metadata['analysis_type'] = 'sentiment';
      } else if (queryLower.contains('summarize')) {
        content = _summarizeText(request.query);
        metadata['analysis_type'] = 'summary';
      } else if (queryLower.contains('grammar')) {
        content = _checkGrammar(request.query);
        metadata['analysis_type'] = 'grammar';
      } else {
        content = _generalTextAnalysis(request.query);
        metadata['analysis_type'] = 'general';
      }

      final response = AgentResponse(
        id: 'text_analysis_${DateTime.now().millisecondsSinceEpoch}',
        requestId: request.id,
        agentId: id,
        content: content,
        type: AgentResponseType.finalAnswer,
        confidence: 0.85 + (Random().nextDouble() * 0.15),
        metadata: metadata,
        timestamp: DateTime.now(),
      );

      _status = AgentStatus.idle;
      _currentTask = null;
      _emitState();

      return response;
    } catch (e) {
      _status = AgentStatus.error;
      _emitState();
      rethrow;
    }
  }

  @override
  Stream<AgentState> streamState() => _stateController.stream;

  @override
  AgentStatus get status => _status;

  @override
  Future<void> dispose() async {
    await _stateController.close();
  }

  void _emitState() {
    _stateController.add(
      AgentState(
        agentId: id,
        status: _status,
        currentTask: _currentTask,
        workload: _status == AgentStatus.processing ? 0.7 : 0.0,
        lastUpdated: DateTime.now(),
      ),
    );
  }

  String _analyzeSentiment(String text) {
    // Simple sentiment analysis simulation
    final positiveWords = [
      'good',
      'great',
      'excellent',
      'amazing',
      'wonderful',
      'happy',
    ];
    final negativeWords = [
      'bad',
      'terrible',
      'awful',
      'sad',
      'angry',
      'disappointed',
    ];

    final textLower = text.toLowerCase();
    final positiveCount = positiveWords.where(textLower.contains).length;
    final negativeCount = negativeWords.where(textLower.contains).length;

    if (positiveCount > negativeCount) {
      return 'Sentiment Analysis: Positive sentiment detected (score: ${(0.6 + positiveCount * 0.1).toStringAsFixed(1)}/1.0)';
    } else if (negativeCount > positiveCount) {
      return 'Sentiment Analysis: Negative sentiment detected (score: ${(0.3 - negativeCount * 0.1).toStringAsFixed(1)}/1.0)';
    } else {
      return 'Sentiment Analysis: Neutral sentiment detected (score: 0.5/1.0)';
    }
  }

  String _summarizeText(String text) {
    final words = text.split(' ');
    if (words.length <= 10) {
      return 'Summary: Text is already concise (${words.length} words).';
    }

    return 'Summary: This text contains ${words.length} words discussing various topics. '
        'Key themes appear to be related to the main concepts mentioned in the content.';
  }

  String _checkGrammar(String text) {
    final issues = <String>[];

    if (text.contains('teh')) issues.add('"teh" should be "the"');
    if (text.contains('recieve')) issues.add('"recieve" should be "receive"');
    if (!text.trim().endsWith('.') &&
        !text.trim().endsWith('!') &&
        !text.trim().endsWith('?')) {
      issues.add('Consider adding punctuation at the end');
    }

    if (issues.isEmpty) {
      return 'Grammar Check: No obvious grammar issues detected.';
    } else {
      return 'Grammar Check: Found ${issues.length} potential issues:\n${issues.map((issue) => '• $issue').join('\n')}';
    }
  }

  String _generalTextAnalysis(String text) {
    final words = text.split(' ');
    final sentences = text.split(RegExp(r'[.!?]+'));
    final avgWordsPerSentence = sentences.isNotEmpty
        ? (words.length / sentences.length).toStringAsFixed(1)
        : '0';

    return 'Text Analysis Results:\n'
        '• Word count: ${words.length}\n'
        '• Sentence count: ${sentences.length}\n'
        '• Average words per sentence: $avgWordsPerSentence\n'
        '• Readability: ${words.length < 50 ? "Easy" : words.length < 100 ? "Moderate" : "Complex"}';
  }
}

/// Code analysis specialist agent
class CodeAnalysisAgent extends AIAgent {
  final StreamController<AgentState> _stateController =
      StreamController<AgentState>.broadcast();
  AgentStatus _status = AgentStatus.initializing;
  String? _currentTask;

  CodeAnalysisAgent()
      : super(
          id: 'code_analysis_001',
          name: 'Code Analysis Specialist',
          specialization: 'Code review, optimization, and debugging',
          capabilities: [
            'code_review',
            'bug_detection',
            'performance_optimization',
            'security_analysis',
            'code_formatting',
            'documentation_generation',
          ],
          priority: AgentPriority.high,
        );

  @override
  Future<void> initialize(Map<String, dynamic> config) async {
    _status = AgentStatus.idle;
    _emitState();
  }

  @override
  bool canHandle(AgentRequest request) {
    final queryLower = request.query.toLowerCase();
    return capabilities.any(
          (capability) => queryLower.contains(capability.replaceAll('_', ' ')),
        ) ||
        queryLower.contains('code') ||
        queryLower.contains('function') ||
        queryLower.contains('debug') ||
        queryLower.contains('optimize') ||
        queryLower.contains('review');
  }

  @override
  Future<AgentResponse> processRequest(AgentRequest request) async {
    _status = AgentStatus.processing;
    _currentTask = 'Analyzing code: ${request.query}';
    _emitState();

    try {
      await Future<void>.delayed(const Duration(milliseconds: 1200));

      final content = _analyzeCode(request.query);

      final response = AgentResponse(
        id: 'code_analysis_${DateTime.now().millisecondsSinceEpoch}',
        requestId: request.id,
        agentId: id,
        content: content,
        type: AgentResponseType.finalAnswer,
        confidence: 0.9,
        metadata: {'analysis_type': 'code_review', 'language': 'multiple'},
        timestamp: DateTime.now(),
      );

      _status = AgentStatus.idle;
      _currentTask = null;
      _emitState();

      return response;
    } catch (e) {
      _status = AgentStatus.error;
      _emitState();
      rethrow;
    }
  }

  @override
  Stream<AgentState> streamState() => _stateController.stream;

  @override
  AgentStatus get status => _status;

  @override
  Future<void> dispose() async {
    await _stateController.close();
  }

  void _emitState() {
    _stateController.add(
      AgentState(
        agentId: id,
        status: _status,
        currentTask: _currentTask,
        workload: _status == AgentStatus.processing ? 0.8 : 0.0,
        lastUpdated: DateTime.now(),
      ),
    );
  }

  String _analyzeCode(String query) {
    return 'Code Analysis Results:\n\n'
        '✅ **Code Structure**: Well organized with clear separation of concerns\n'
        '⚠️  **Potential Issues**:\n'
        '   • Consider adding error handling in async functions\n'
        '   • Some variables could be marked as final for better performance\n'
        '   • Consider extracting complex logic into separate methods\n\n'
        '🚀 **Performance Suggestions**:\n'
        '   • Use const constructors where possible\n'
        '   • Consider lazy loading for expensive operations\n'
        '   • Implement proper disposal patterns for streams\n\n'
        '📋 **Best Practices**:\n'
        '   • Add comprehensive documentation\n'
        '   • Implement unit tests for critical functions\n'
        '   • Follow consistent naming conventions\n\n'
        '**Overall Rating**: 8.5/10 - Good code quality with room for optimization';
  }
}

/// General assistant agent that can delegate to specialists
class GeneralAssistantAgent extends AIAgent {
  final StreamController<AgentState> _stateController =
      StreamController<AgentState>.broadcast();
  AgentStatus _status = AgentStatus.initializing;
  String? _currentTask;

  GeneralAssistantAgent()
      : super(
          id: 'general_assistant_001',
          name: 'General Assistant',
          specialization: 'General queries and task coordination',
          capabilities: [
            'general_questions',
            'task_coordination',
            'delegation',
            'conversation',
          ],
          priority: AgentPriority.normal,
        );

  @override
  Future<void> initialize(Map<String, dynamic> config) async {
    _status = AgentStatus.idle;
    _emitState();
  }

  @override
  bool canHandle(AgentRequest request) {
    // General assistant can handle any request as fallback
    return true;
  }

  @override
  Future<AgentResponse> processRequest(AgentRequest request) async {
    _status = AgentStatus.processing;
    _currentTask = 'Processing general query';
    _emitState();

    try {
      await Future<void>.delayed(const Duration(milliseconds: 500));

      final queryLower = request.query.toLowerCase();

      // Check if this should be delegated to a specialist
      if (_shouldDelegateToTextAnalyst(queryLower)) {
        return _createDelegationResponse(
          request,
          'text_analysis_001',
          'Delegating text analysis request to specialist',
        );
      } else if (_shouldDelegateToCodeAnalyst(queryLower)) {
        return _createDelegationResponse(
          request,
          'code_analysis_001',
          'Delegating code analysis request to specialist',
        );
      }

      // Handle general queries
      final content = _handleGeneralQuery(request.query);

      final response = AgentResponse(
        id: 'general_${DateTime.now().millisecondsSinceEpoch}',
        requestId: request.id,
        agentId: id,
        content: content,
        type: AgentResponseType.finalAnswer,
        confidence: 0.75,
        timestamp: DateTime.now(),
      );

      _status = AgentStatus.idle;
      _currentTask = null;
      _emitState();

      return response;
    } catch (e) {
      _status = AgentStatus.error;
      _emitState();
      rethrow;
    }
  }

  @override
  Stream<AgentState> streamState() => _stateController.stream;

  @override
  AgentStatus get status => _status;

  @override
  Future<void> dispose() async {
    await _stateController.close();
  }

  void _emitState() {
    _stateController.add(
      AgentState(
        agentId: id,
        status: _status,
        currentTask: _currentTask,
        workload: _status == AgentStatus.processing ? 0.3 : 0.0,
        lastUpdated: DateTime.now(),
      ),
    );
  }

  bool _shouldDelegateToTextAnalyst(String query) {
    return query.contains('analyze') && query.contains('text') ||
        query.contains('sentiment') ||
        query.contains('summarize') ||
        query.contains('grammar');
  }

  bool _shouldDelegateToCodeAnalyst(String query) {
    return query.contains('code') ||
        query.contains('function') ||
        query.contains('debug') ||
        query.contains('optimize');
  }

  AgentResponse _createDelegationResponse(
    AgentRequest request,
    String targetAgentId,
    String message,
  ) {
    return AgentResponse(
      id: 'delegation_${DateTime.now().millisecondsSinceEpoch}',
      requestId: request.id,
      agentId: id,
      content: message,
      type: AgentResponseType.delegation,
      metadata: {
        'delegate_to': targetAgentId,
        'delegated_query': request.query,
      },
      timestamp: DateTime.now(),
    );
  }

  String _handleGeneralQuery(String query) {
    return 'Hello! I\'m your general assistant. I can help you with various tasks including:\n\n'
        '🔍 **Text Analysis**: Ask me to analyze sentiment, summarize text, or check grammar\n'
        '💻 **Code Review**: Request code analysis, debugging help, or optimization suggestions\n'
        '🤝 **General Questions**: Ask me anything and I\'ll do my best to help\n\n'
        'For your query: "$query"\n\n'
        'I\'m here to assist you with whatever you need. Feel free to ask specific questions '
        'about text analysis, code review, or any general topics!';
  }
}
