import 'package:flutter/material.dart';

/// The package's neutral colour ramp plus a single host-derived accent.
///
/// Values follow `DESIGN.md` §3 exactly. Use [ChatTokens.of] to resolve the
/// active set (light/dark) with `accent`/`onAccent` bound to the host
/// [ColorScheme], or reach for [ChatTokens.light] / [ChatTokens.dark]
/// directly when brightness is already known and no host accent is wanted.
@immutable
class ChatTokens {
  const ChatTokens({
    required this.canvas,
    required this.surface,
    required this.surfaceSunken,
    required this.userBubble,
    required this.border,
    required this.borderStrong,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.accent,
    required this.onAccent,
    required this.ink,
    required this.onInk,
    required this.danger,
    required this.inlineCodeBg,
    required this.codeBg,
    required this.codeBorder,
  });

  /// Light token set with EXACT hex values from `DESIGN.md` §3 (Light).
  static const ChatTokens light = ChatTokens(
    canvas: Color(0xFFFBFBFA),
    surface: Color(0xFFFFFFFF),
    surfaceSunken: Color(0xFFF3F3F1),
    userBubble: Color(0xFFEFEFEC),
    border: Color(0xFFE4E4E2),
    borderStrong: Color(0xFF85858D),
    textPrimary: Color(0xFF18181B),
    textSecondary: Color(0xFF52525B),
    textTertiary: Color(0xFF6B6B73),
    accent: Color(0xFF2450D6),
    onAccent: Color(0xFFFFFFFF),
    ink: Color(0xFF18181B),
    onInk: Color(0xFFFBFBFA),
    danger: Color(0xFFC4321C),
    inlineCodeBg: Color(0xFFEEEEEB),
    codeBg: Color(0xFFF6F6F4),
    codeBorder: Color(0xFFE4E4E2),
  );

  /// Dark token set with EXACT hex values from `DESIGN.md` §3 (Dark).
  static const ChatTokens dark = ChatTokens(
    canvas: Color(0xFF111113),
    surface: Color(0xFF18181B),
    surfaceSunken: Color(0xFF1C1C1F),
    userBubble: Color(0xFF26262A),
    border: Color(0xFF2A2A2F),
    borderStrong: Color(0xFF6A6A72),
    textPrimary: Color(0xFFEDEDEF),
    textSecondary: Color(0xFFA8A8B0),
    textTertiary: Color(0xFF8C8C94),
    accent: Color(0xFF8AA8FF),
    onAccent: Color(0xFF111113),
    ink: Color(0xFFEDEDEF),
    onInk: Color(0xFF111113),
    danger: Color(0xFFFF7A66),
    inlineCodeBg: Color(0xFF232327),
    codeBg: Color(0xFF161618),
    codeBorder: Color(0xFF2A2A2F),
  );

  /// Resolves [light] or [dark] from `Theme.of(context).brightness`, with
  /// `accent`/`onAccent` bound to the host's `colorScheme.primary`/
  /// `colorScheme.onPrimary` (package rule: the host's accent, not a fixed
  /// brand colour, drives links/focus/selection).
  static ChatTokens of(BuildContext context) {
    final theme = Theme.of(context);
    final base = theme.brightness == Brightness.dark ? dark : light;
    return base.copyWith(
      accent: theme.colorScheme.primary,
      onAccent: theme.colorScheme.onPrimary,
    );
  }

  final Color canvas;
  final Color surface;
  final Color surfaceSunken;
  final Color userBubble;
  final Color border;
  final Color borderStrong;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color accent;
  final Color onAccent;
  final Color ink;
  final Color onInk;
  final Color danger;
  final Color inlineCodeBg;
  final Color codeBg;
  final Color codeBorder;

  /// Returns a copy with the given fields replaced.
  ChatTokens copyWith({
    Color? canvas,
    Color? surface,
    Color? surfaceSunken,
    Color? userBubble,
    Color? border,
    Color? borderStrong,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? accent,
    Color? onAccent,
    Color? ink,
    Color? onInk,
    Color? danger,
    Color? inlineCodeBg,
    Color? codeBg,
    Color? codeBorder,
  }) {
    return ChatTokens(
      canvas: canvas ?? this.canvas,
      surface: surface ?? this.surface,
      surfaceSunken: surfaceSunken ?? this.surfaceSunken,
      userBubble: userBubble ?? this.userBubble,
      border: border ?? this.border,
      borderStrong: borderStrong ?? this.borderStrong,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      accent: accent ?? this.accent,
      onAccent: onAccent ?? this.onAccent,
      ink: ink ?? this.ink,
      onInk: onInk ?? this.onInk,
      danger: danger ?? this.danger,
      inlineCodeBg: inlineCodeBg ?? this.inlineCodeBg,
      codeBg: codeBg ?? this.codeBg,
      codeBorder: codeBorder ?? this.codeBorder,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatTokens &&
          other.canvas == canvas &&
          other.surface == surface &&
          other.surfaceSunken == surfaceSunken &&
          other.userBubble == userBubble &&
          other.border == border &&
          other.borderStrong == borderStrong &&
          other.textPrimary == textPrimary &&
          other.textSecondary == textSecondary &&
          other.textTertiary == textTertiary &&
          other.accent == accent &&
          other.onAccent == onAccent &&
          other.ink == ink &&
          other.onInk == onInk &&
          other.danger == danger &&
          other.inlineCodeBg == inlineCodeBg &&
          other.codeBg == codeBg &&
          other.codeBorder == codeBorder;

  @override
  int get hashCode => Object.hash(
        canvas,
        surface,
        surfaceSunken,
        userBubble,
        border,
        borderStrong,
        textPrimary,
        textSecondary,
        textTertiary,
        accent,
        onAccent,
        ink,
        onInk,
        danger,
        inlineCodeBg,
        codeBg,
        codeBorder,
      );
}

/// The package's 4px spacing scale (`DESIGN.md` §5).
abstract final class ChatSpace {
  static const double s2 = 2;
  static const double s4 = 4;
  static const double s8 = 8;
  static const double s12 = 12;
  static const double s16 = 16;
  static const double s20 = 20;
  static const double s24 = 24;
  static const double s32 = 32;
  static const double s48 = 48;
  static const double s64 = 64;
}

/// The package's corner-radius scale (`DESIGN.md` §5).
abstract final class ChatRadius {
  /// Inline `code` chips.
  static const double inline = 4;

  /// Tooltips, small buttons.
  static const double sm = 8;

  /// Code blocks, prompt tiles, rich result cards, attachments.
  static const double md = 12;

  /// User bubble.
  static const double bubble = 20;

  /// Composer.
  static const double composer = 24;

  /// Tail corner on the last bubble of a consecutive user group.
  static const double tail = 6;
}

/// Reading-column and composer width constraints (`DESIGN.md` §5).
abstract final class ChatLayout {
  /// Max width of the message reading column.
  static const double readingMaxWidth = 760;

  /// Max width of the composer.
  static const double composerMaxWidth = 800;

  /// Max fraction of the reading column a user bubble may take.
  static const double userBubbleMaxFraction = 0.8;

  /// Absolute cap on a user bubble's width, in logical pixels.
  static const double userBubbleMaxWidth = 560;
}

/// Motion durations and curves (`DESIGN.md` §7). Widgets must read these
/// tokens rather than writing raw `Duration(milliseconds: ...)` literals, and
/// must resolve every duration through [ChatMotion.of] so reduced-motion
/// users get `Duration.zero` automatically.
abstract final class ChatMotion {
  /// Button scale 1.0 -> 0.96 on press.
  static const Duration press = Duration(milliseconds: 100);

  /// Hover fills, icon swaps (copy -> check), action row opacity.
  static const Duration fast = Duration(milliseconds: 150);

  /// Message appear, scroll button show/hide.
  static const Duration base = Duration(milliseconds: 220);

  /// Empty state exit, scroll-to-bottom `animateTo`.
  static const Duration slow = Duration(milliseconds: 320);

  /// Send <-> stop icon morph.
  static const Duration sendMorph = Duration(milliseconds: 160);

  /// Opacity 0 -> 1 on newly revealed streamed text.
  static const Duration streamFade = Duration(milliseconds: 180);

  /// Live caret opacity 0.35 <-> 1.0, repeating, while streaming.
  static const Duration caretPulse = Duration(milliseconds: 900);

  /// Shimmer sweep across the "Thinking" label, repeating.
  static const Duration thinkingSweep = Duration(milliseconds: 1600);

  /// Emphasized-decelerate entrance curve.
  static const Curve enter = Cubic(0.2, 0, 0, 1);

  /// Accelerate exit curve, used at roughly 70% of the matching enter
  /// duration.
  static const Curve exit = Cubic(0.4, 0, 1, 1);

  /// Whether the ambient [MediaQuery] requests reduced/disabled animations.
  static bool reduced(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  /// Resolves [duration] to [Duration.zero] when [reduced] is true for
  /// [context]; otherwise returns [duration] unchanged.
  static Duration of(BuildContext context, Duration duration) =>
      reduced(context) ? Duration.zero : duration;
}
