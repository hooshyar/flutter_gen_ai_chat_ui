import 'example_question_config.dart';

/// Represents a suggested question shown to users before they start chatting.
class ExampleQuestion {
  final String question;
  final ExampleQuestionConfig? config;

  const ExampleQuestion({
    required this.question,
    this.config,
  });
}
