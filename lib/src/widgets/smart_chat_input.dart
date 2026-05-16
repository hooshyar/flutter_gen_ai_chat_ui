import 'package:flutter/material.dart';

/// Enhanced chat input widget with advanced features
class SmartChatInput extends StatefulWidget {
  final TextEditingController? controller;
  final String? hintText;
  final VoidCallback? onSend;
  final void Function(String)? onTextChanged;
  final bool enabled;
  final int maxLines;
  final bool showSendButton;
  final Widget? sendButton;
  final List<Widget> prefixWidgets;
  final List<Widget> suffixWidgets;
  final InputDecoration? decoration;
  final SmartInputStyle style;
  final bool autoFocus;
  final EdgeInsets padding;

  const SmartChatInput({
    super.key,
    this.controller,
    this.hintText,
    this.onSend,
    this.onTextChanged,
    this.enabled = true,
    this.maxLines = 5,
    this.showSendButton = true,
    this.sendButton,
    this.prefixWidgets = const [],
    this.suffixWidgets = const [],
    this.decoration,
    this.style = SmartInputStyle.modern,
    this.autoFocus = false,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  State<SmartChatInput> createState() => _SmartChatInputState();
}

class _SmartChatInputState extends State<SmartChatInput>
    with TickerProviderStateMixin {
  late TextEditingController _controller;
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;
  bool _isEmpty = true;
  bool _isFocused = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _isEmpty = _controller.text.isEmpty;

    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);

    if (widget.autoFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Guard against the widget being disposed before the next frame —
        // `_focusNode` is disposed in `dispose()` and calling
        // `requestFocus()` on a disposed FocusNode throws.
        if (!mounted) return;
        _focusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    _glowController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final isEmpty = _controller.text.isEmpty;
    if (isEmpty != _isEmpty) {
      setState(() {
        _isEmpty = isEmpty;
      });
    }
    widget.onTextChanged?.call(_controller.text);
  }

  void _onFocusChanged() {
    final isFocused = _focusNode.hasFocus;
    if (isFocused != _isFocused) {
      setState(() {
        _isFocused = isFocused;
      });

      if (isFocused) {
        _glowController.repeat(reverse: true);
      } else {
        _glowController.stop();
      }
    }
  }

  void _handleSend() {
    if (_controller.text.trim().isNotEmpty) {
      widget.onSend?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: widget.padding,
      child: _buildInputForStyle(),
    );
  }

  Widget _buildInputForStyle() {
    switch (widget.style) {
      case SmartInputStyle.modern:
        return _buildModernInput();
      case SmartInputStyle.glassmorphic:
        return _buildGlassmorphicInput();
      case SmartInputStyle.neon:
        return _buildNeonInput();
      case SmartInputStyle.minimal:
        return _buildMinimalInput();
      case SmartInputStyle.elegant:
        return _buildElegantInput();
    }
  }

  Widget _buildModernInput() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _isFocused
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          width: _isFocused ? 2 : 1,
        ),
        boxShadow: [
          if (_isFocused)
            BoxShadow(
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
              blurRadius: 12,
              spreadRadius: 2,
            ),
        ],
      ),
      child: _buildInputRow(),
    );
  }

  Widget _buildGlassmorphicInput() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.1),
            Colors.white.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
          child: _buildInputRow(),
        ),
      ),
    );
  }

  Widget _buildNeonInput() {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E2E),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFF00D9FF),
              width: 2,
            ),
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                      color: const Color(0xFF00D9FF).withValues(
                        alpha: _glowAnimation.value * 0.5,
                      ),
                      blurRadius: 20 * _glowAnimation.value,
                      spreadRadius: 2 * _glowAnimation.value,
                    ),
                  ]
                : null,
          ),
          child: _buildInputRow(
            textColor: Colors.white,
            hintColor: Colors.white.withValues(alpha: 0.6),
          ),
        );
      },
    );
  }

  Widget _buildMinimalInput() {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: _isFocused
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
            width: _isFocused ? 2 : 1,
          ),
        ),
      ),
      child: _buildInputRow(),
    );
  }

  Widget _buildElegantInput() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context)
                .colorScheme
                .primaryContainer
                .withValues(alpha: 0.1),
            Theme.of(context)
                .colorScheme
                .secondaryContainer
                .withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isFocused
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)
              : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: _buildInputRow(),
    );
  }

  Widget _buildInputRow({Color? textColor, Color? hintColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Prefix widgets
        if (widget.prefixWidgets.isNotEmpty) ...[
          ...widget.prefixWidgets,
          const SizedBox(width: 8),
        ],

        // Text input
        Expanded(
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            enabled: widget.enabled,
            maxLines: widget.maxLines,
            minLines: 1,
            style: TextStyle(color: textColor),
            decoration: (widget.decoration ??
                InputDecoration(
                  hintText: widget.hintText ?? 'Type a message...',
                  hintStyle: TextStyle(color: hintColor),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                )),
            onSubmitted: (_) => _handleSend(),
          ),
        ),

        // Suffix widgets
        if (widget.suffixWidgets.isNotEmpty) ...[
          const SizedBox(width: 8),
          ...widget.suffixWidgets,
        ],

        // Send button
        if (widget.showSendButton) ...[
          const SizedBox(width: 8),
          _buildSendButton(),
        ],

        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildSendButton() {
    if (widget.sendButton != null) {
      return widget.sendButton!;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: IconButton(
        onPressed: _isEmpty ? null : _handleSend,
        icon: AnimatedRotation(
          turns: _isEmpty ? 0 : 0.25,
          duration: const Duration(milliseconds: 200),
          child: Icon(
            _isEmpty ? Icons.send_outlined : Icons.send,
            color: _isEmpty
                ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)
                : Theme.of(context).colorScheme.primary,
          ),
        ),
        style: IconButton.styleFrom(
          backgroundColor: _isEmpty
              ? Colors.transparent
              : Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        ),
      ),
    );
  }
}

/// Smart input styles
enum SmartInputStyle {
  modern,
  glassmorphic,
  neon,
  minimal,
  elegant,
}

/// Animated attachment button widget
class AttachmentButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final List<AttachmentOption> options;
  final IconData icon;
  final Color? color;

  const AttachmentButton({
    super.key,
    this.onPressed,
    this.options = const [],
    this.icon = Icons.attach_file,
    this.color,
  });

  @override
  State<AttachmentButton> createState() => _AttachmentButtonState();
}

class _AttachmentButtonState extends State<AttachmentButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Attachment options
        if (_isExpanded)
          ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).shadowColor.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: widget.options.map(_buildOptionButton).toList(),
              ),
            ),
          ),

        // Main attachment button
        IconButton(
          onPressed:
              widget.options.isEmpty ? widget.onPressed : _toggleExpansion,
          icon: AnimatedRotation(
            turns: _isExpanded ? 0.125 : 0,
            duration: const Duration(milliseconds: 300),
            child: Icon(
              widget.icon,
              color: widget.color ?? Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOptionButton(AttachmentOption option) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: SizedBox(
        width: double.infinity,
        child: TextButton.icon(
          onPressed: () {
            option.onPressed();
            _toggleExpansion();
          },
          icon: Icon(option.icon, size: 18),
          label: Text(option.label),
          style: TextButton.styleFrom(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
      ),
    );
  }
}

/// Attachment option definition
class AttachmentOption {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const AttachmentOption({
    required this.label,
    required this.icon,
    required this.onPressed,
  });
}

/// Voice input button with recording animation
class VoiceInputButton extends StatefulWidget {
  final VoidCallback? onStartRecording;
  final VoidCallback? onStopRecording;
  final bool isRecording;
  final Color? color;

  const VoiceInputButton({
    super.key,
    this.onStartRecording,
    this.onStopRecording,
    this.isRecording = false,
    this.color,
  });

  @override
  State<VoiceInputButton> createState() => _VoiceInputButtonState();
}

class _VoiceInputButtonState extends State<VoiceInputButton>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(VoiceInputButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRecording && !oldWidget.isRecording) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.isRecording && oldWidget.isRecording) {
      _pulseController
        ..stop()
        ..reset();
    }
  }

  void _handlePress() {
    if (widget.isRecording) {
      widget.onStopRecording?.call();
    } else {
      widget.onStartRecording?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handlePress,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: widget.isRecording ? _pulseAnimation.value : 1.0,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: widget.isRecording
                    ? Colors.red.withValues(alpha: 0.2)
                    : Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: widget.isRecording
                    ? Border.all(color: Colors.red, width: 2)
                    : null,
              ),
              child: Icon(
                widget.isRecording ? Icons.stop : Icons.mic,
                color: widget.isRecording
                    ? Colors.red
                    : widget.color ?? Theme.of(context).colorScheme.primary,
                size: 20,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Typing indicator widget
class TypingIndicator extends StatefulWidget {
  final String text;
  final TextStyle? textStyle;
  final Duration animationDuration;

  const TypingIndicator({
    super.key,
    this.text = 'AI is typing',
    this.textStyle,
    this.animationDuration = const Duration(milliseconds: 1200),
  });

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _currentDot = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _controller
      ..addListener(() {
        final progress = _controller.value * 3;
        final newDot = progress.floor() % 3;
        if (newDot != _currentDot) {
          setState(() {
            _currentDot = newDot;
          });
        }
      })
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.text,
          style: widget.textStyle ?? Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(width: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: index == _currentDot
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context)
                        .colorScheme
                        .outline
                        .withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
            );
          }),
        ),
      ],
    );
  }
}
