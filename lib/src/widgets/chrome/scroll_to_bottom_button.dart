import 'package:flutter/material.dart';

import '../../models/chat/message_options.dart';
import '../../theme/chat_tokens.dart';

/// Floating "jump to latest message" control (`DESIGN.md` §8.10).
///
/// Package default: a 36px disc centered horizontally on the reading
/// column, 12px above the composer, with scale-and-fade show/hide, a level-2
/// shadow in light mode (none in dark — a `border` plus a top highlight
/// carries the elevation instead), and a small accent dot while there is new
/// streamed content below the fold.
class ScrollToBottomButton extends StatelessWidget {
  /// Creates the floating scroll-to-bottom control.
  const ScrollToBottomButton({
    super.key,
    required this.visible,
    required this.onPressed,
    this.options = const ScrollToBottomOptions(),
    this.showNewContentDot = false,
  });

  /// Whether the button should be shown (scale/fade animates between
  /// states; the widget still occupies layout space so its host `Stack`
  /// doesn't need to know which state is active).
  final bool visible;

  /// Invoked on tap. Callers are responsible for releasing any streaming
  /// pin and performing the actual scroll.
  final VoidCallback onPressed;

  /// Sizing, position and text options.
  final ScrollToBottomOptions options;

  /// Shows a small accent dot on the disc to signal new content below while
  /// streaming continues with the pin released.
  final bool showNewContentDot;

  /// Material/WCAG floor for an icon-only tap target — bigger than the
  /// visual disc, per `DESIGN.md` §8.13 ("hit targets 44x44 minimum"; this
  /// package rounds up to Material's 48x48 rather than the bare minimum,
  /// matching the rest of the package's icon-only controls).
  static const double _hitAreaSize = 48;

  /// The painted disc diameter (`DESIGN.md` §8.10).
  static const double _discSize = 36;

  @override
  Widget build(BuildContext context) {
    final tokens = ChatTokens.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final visualDisc = DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.surface,
        shape: BoxShape.circle,
        border: Border.all(color: tokens.border),
        boxShadow: isDark
            ? null
            : const [
                BoxShadow(
                  color: Color(0x0F181818),
                  offset: Offset(0, 1),
                  blurRadius: 2,
                ),
                BoxShadow(
                  color: Color(0x14181818),
                  offset: Offset(0, 4),
                  blurRadius: 12,
                ),
              ],
      ),
      child: SizedBox(
        width: _discSize,
        height: _discSize,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              Icons.arrow_downward_rounded,
              size: 18,
              color: tokens.textPrimary,
            ),
            if (options.showText) ...[
              Positioned(
                bottom: 2,
                child: Text(
                  options.buttonText,
                  style: TextStyle(fontSize: 10, color: tokens.textPrimary),
                ),
              ),
            ],
            if (showNewContentDot)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: tokens.accent,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    final disc = Semantics(
      button: true,
      label: options.buttonText,
      child: Tooltip(
        message: options.buttonText,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onPressed,
            child: SizedBox(
              width: _hitAreaSize,
              height: _hitAreaSize,
              child: Center(child: visualDisc),
            ),
          ),
        ),
      ),
    );

    final animated = AnimatedScale(
      scale: visible ? 1.0 : 0.9,
      duration: ChatMotion.of(context, ChatMotion.base),
      curve: ChatMotion.enter,
      child: AnimatedOpacity(
        opacity: visible ? 1.0 : 0.0,
        duration: ChatMotion.of(context, ChatMotion.base),
        curve: ChatMotion.enter,
        child: IgnorePointer(ignoring: !visible, child: disc),
      ),
    );

    final content = Padding(
      padding: EdgeInsets.only(bottom: options.bottomOffset),
      child: animated,
    );

    if (options.position == ScrollToBottomPosition.end) {
      return Align(
        alignment: AlignmentDirectional.bottomEnd,
        child: Padding(
          padding: EdgeInsetsDirectional.only(end: options.rightOffset),
          child: content,
        ),
      );
    }

    // Center position (default): horizontally centered on the reading
    // column, never parked over code in the bottom-right.
    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: ChatLayout.readingMaxWidth),
        child: Align(alignment: Alignment.bottomCenter, child: content),
      ),
    );
  }

  /// Whether reduced-motion is active — reserved for callers driving the
  /// `animateTo`/`jumpTo` scroll choice on tap; see `DESIGN.md` §8.10.
  static bool isReducedMotion(BuildContext context) =>
      ChatMotion.reduced(context);
}
