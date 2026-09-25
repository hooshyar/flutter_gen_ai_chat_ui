import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/example_question.dart';
import '../../models/welcome_message_config.dart';
import '../../theme/chat_tokens.dart';

/// The package's default empty-conversation state (`DESIGN.md` §8.6).
///
/// No card, no shadow, no emoji: a greeting positioned at 38% of the
/// available height inside the 760-wide reading column, with up to four
/// suggestion tiles below it. Every visual is overridable through
/// [welcomeMessageConfig] (`containerDecoration`, `titleStyle`,
/// `questionsSectionTitle`, per-question `config`) — this widget is only
/// reached once [WelcomeMessageConfig.builder] has been checked by the
/// caller.
class ChatEmptyState extends StatelessWidget {
  /// Creates the default empty-conversation state.
  const ChatEmptyState({
    super.key,
    required this.exampleQuestions,
    required this.onQuestionTap,
    this.welcomeMessageConfig,
  });

  /// Suggested questions rendered as tappable tiles below the greeting.
  final List<ExampleQuestion> exampleQuestions;

  /// Invoked with a question's text when its tile is tapped.
  final ValueChanged<String> onQuestionTap;

  /// Optional legacy/override configuration. When null, every value falls
  /// back to the package default described in `DESIGN.md` §8.6.
  final WelcomeMessageConfig? welcomeMessageConfig;

  @override
  Widget build(BuildContext context) {
    final tokens = ChatTokens.of(context);
    final config = welcomeMessageConfig;
    final title = config?.title;
    final subtitle = config?.subtitle;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final availableHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : MediaQuery.sizeOf(context).height;
        final columnWidth = math.min(
          availableWidth,
          ChatLayout.readingMaxWidth,
        );
        final isWide = availableWidth >= 840;
        final isTwoColumn = columnWidth >= 600;

        final titleStyle = config?.titleStyle ??
            TextStyle(
              fontSize: isWide ? 32 : 28,
              height: (isWide ? 38 : 34) / (isWide ? 32 : 28),
              fontWeight: FontWeight.w600,
              letterSpacing: -0.4,
              color: tokens.textPrimary,
            );
        final subtitleStyle = config?.subtitleStyle ??
            TextStyle(fontSize: 16, height: 1.56, color: tokens.textSecondary);

        Widget content = Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) ...[
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: titleStyle,
              ),
            ],
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: subtitleStyle,
              ),
            ],
            if (exampleQuestions.isNotEmpty) ...[
              const SizedBox(height: ChatSpace.s24),
              if ((config?.questionsSectionTitle ?? '').isNotEmpty) ...[
                Text(
                  config!.questionsSectionTitle,
                  style: config.questionsSectionTitleStyle ??
                      TextStyle(
                        fontSize: 14,
                        height: 20 / 14,
                        fontWeight: FontWeight.w500,
                        color: tokens.textSecondary,
                      ),
                ),
                const SizedBox(height: ChatSpace.s12),
              ],
              _SuggestionGrid(
                questions: exampleQuestions,
                twoColumn: isTwoColumn,
                columnWidth: columnWidth,
                onQuestionTap: onQuestionTap,
              ),
            ],
          ],
        );

        if (config?.containerDecoration != null) {
          content = Container(
            padding: config?.containerPadding ?? const EdgeInsets.all(24),
            decoration: config?.containerDecoration,
            child: content,
          );
        }

        return Padding(
          padding: EdgeInsets.only(top: availableHeight * 0.38),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: ChatLayout.readingMaxWidth,
              ),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: content,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SuggestionGrid extends StatelessWidget {
  const _SuggestionGrid({
    required this.questions,
    required this.twoColumn,
    required this.columnWidth,
    required this.onQuestionTap,
  });

  final List<ExampleQuestion> questions;
  final bool twoColumn;
  final double columnWidth;
  final ValueChanged<String> onQuestionTap;

  @override
  Widget build(BuildContext context) {
    final tileWidth =
        twoColumn ? (columnWidth - ChatSpace.s8) / 2 : columnWidth;
    return Wrap(
      spacing: ChatSpace.s8,
      runSpacing: ChatSpace.s8,
      children: [
        for (final question in questions)
          SizedBox(
            width: tileWidth,
            child: _EmptyStateTile(
              question: question,
              onTap: () => onQuestionTap(question.question),
            ),
          ),
      ],
    );
  }
}

class _EmptyStateTile extends StatefulWidget {
  const _EmptyStateTile({required this.question, required this.onTap});

  final ExampleQuestion question;
  final VoidCallback onTap;

  @override
  State<_EmptyStateTile> createState() => _EmptyStateTileState();
}

class _EmptyStateTileState extends State<_EmptyStateTile> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final tokens = ChatTokens.of(context);
    final config = widget.question.config;
    final filled = _hovered || _pressed;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: ChatMotion.of(context, ChatMotion.fast),
          padding: config?.containerPadding ??
              const EdgeInsets.symmetric(
                vertical: ChatSpace.s16 - 2,
                horizontal: ChatSpace.s16,
              ),
          decoration: config?.containerDecoration ??
              BoxDecoration(
                color: filled ? tokens.surfaceSunken : Colors.transparent,
                borderRadius: BorderRadius.circular(ChatRadius.md),
                border: Border.all(color: tokens.border),
              ),
          child: Row(
            children: [
              if (config != null) ...[
                Icon(
                  config.iconData,
                  size: config.iconSize,
                  color: config.iconColor ?? tokens.textSecondary,
                ),
                SizedBox(width: config.spacing),
              ],
              Expanded(
                child: Text(
                  widget.question.question,
                  style: config?.textStyle ??
                      TextStyle(
                        fontSize: 14,
                        height: 20 / 14,
                        fontWeight: FontWeight.w500,
                        color: tokens.textPrimary,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
