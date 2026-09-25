import 'dart:ui';

import 'package:flutter/material.dart';

/// Animation presets for chat UI elements with professional timing and curves
@immutable
class ChatAnimationPresets {
  /// Micro-interaction durations (fast, subtle interactions)
  final Duration microInteraction;
  final Duration quickTransition;
  final Duration mediumTransition;
  final Duration slowTransition;

  /// Message animation durations
  final Duration messageSlideIn;
  final Duration messageFadeIn;
  final Duration messageTypewriter;
  final Duration messageExpansion;

  /// Input field animation durations
  final Duration inputFocus;
  final Duration inputExpansion;
  final Duration sendButtonPress;
  final Duration attachmentButton;

  /// Loading and streaming durations
  final Duration streamingIndicator;
  final Duration typingIndicator;
  final Duration skeletonShimmer;
  final Duration pullToRefresh;

  /// Theme transition durations
  final Duration themeSwitch;
  final Duration colorTransition;
  final Duration layoutTransition;

  /// Animation curves for different interactions
  final Curve elasticOut;
  final Curve smoothOut;
  final Curve quickOut;
  final Curve slideOut;
  final Curve bounceOut;
  final Curve materialEase;

  /// Message-specific curves
  final Curve messageSlideInCurve;
  final Curve messageFadeInCurve;
  final Curve messageExpansionCurve;

  /// Input-specific curves
  final Curve inputFocusCurve;
  final Curve sendButtonCurve;

  /// Spring physics for advanced animations
  final SpringDescription springPhysics;
  final SpringDescription gentleSpring;
  final SpringDescription snappySpring;

  const ChatAnimationPresets({
    // Micro-interaction durations
    this.microInteraction = const Duration(milliseconds: 150),
    this.quickTransition = const Duration(milliseconds: 200),
    this.mediumTransition = const Duration(milliseconds: 300),
    this.slowTransition = const Duration(milliseconds: 400),

    // Message animations
    this.messageSlideIn = const Duration(milliseconds: 350),
    this.messageFadeIn = const Duration(milliseconds: 250),
    this.messageTypewriter = const Duration(milliseconds: 30),
    this.messageExpansion = const Duration(milliseconds: 300),

    // Input animations
    this.inputFocus = const Duration(milliseconds: 200),
    this.inputExpansion = const Duration(milliseconds: 250),
    this.sendButtonPress = const Duration(milliseconds: 100),
    this.attachmentButton = const Duration(milliseconds: 150),

    // Loading animations
    this.streamingIndicator = const Duration(milliseconds: 800),
    this.typingIndicator = const Duration(milliseconds: 1200),
    this.skeletonShimmer = const Duration(milliseconds: 1500),
    this.pullToRefresh = const Duration(milliseconds: 400),

    // Theme transitions
    this.themeSwitch = const Duration(milliseconds: 350),
    this.colorTransition = const Duration(milliseconds: 200),
    this.layoutTransition = const Duration(milliseconds: 300),

    // Animation curves
    this.elasticOut = Curves.elasticOut,
    this.smoothOut = Curves.easeOutCubic,
    this.quickOut = Curves.easeOutQuart,
    this.slideOut = Curves.decelerate,
    this.bounceOut = Curves.bounceOut,
    this.materialEase = Curves.easeInOut,

    // Message curves
    this.messageSlideInCurve = Curves.easeOutCubic,
    this.messageFadeInCurve = Curves.easeInOut,
    this.messageExpansionCurve = Curves.easeOutQuart,

    // Input curves
    this.inputFocusCurve = Curves.easeOutCubic,
    this.sendButtonCurve = Curves.easeOutBack,

    // Spring physics
    this.springPhysics = const SpringDescription(
      mass: 1.0,
      stiffness: 100.0,
      damping: 15.0,
    ),
    this.gentleSpring = const SpringDescription(
      mass: 1.0,
      stiffness: 80.0,
      damping: 20.0,
    ),
    this.snappySpring = const SpringDescription(
      mass: 1.0,
      stiffness: 200.0,
      damping: 10.0,
    ),
  });

  /// Create a copy with different values
  ChatAnimationPresets copyWith({
    Duration? microInteraction,
    Duration? quickTransition,
    Duration? mediumTransition,
    Duration? slowTransition,
    Duration? messageSlideIn,
    Duration? messageFadeIn,
    Duration? messageTypewriter,
    Duration? messageExpansion,
    Duration? inputFocus,
    Duration? inputExpansion,
    Duration? sendButtonPress,
    Duration? attachmentButton,
    Duration? streamingIndicator,
    Duration? typingIndicator,
    Duration? skeletonShimmer,
    Duration? pullToRefresh,
    Duration? themeSwitch,
    Duration? colorTransition,
    Duration? layoutTransition,
    Curve? elasticOut,
    Curve? smoothOut,
    Curve? quickOut,
    Curve? slideOut,
    Curve? bounceOut,
    Curve? materialEase,
    Curve? messageSlideInCurve,
    Curve? messageFadeInCurve,
    Curve? messageExpansionCurve,
    Curve? inputFocusCurve,
    Curve? sendButtonCurve,
    SpringDescription? springPhysics,
    SpringDescription? gentleSpring,
    SpringDescription? snappySpring,
  }) {
    return ChatAnimationPresets(
      microInteraction: microInteraction ?? this.microInteraction,
      quickTransition: quickTransition ?? this.quickTransition,
      mediumTransition: mediumTransition ?? this.mediumTransition,
      slowTransition: slowTransition ?? this.slowTransition,
      messageSlideIn: messageSlideIn ?? this.messageSlideIn,
      messageFadeIn: messageFadeIn ?? this.messageFadeIn,
      messageTypewriter: messageTypewriter ?? this.messageTypewriter,
      messageExpansion: messageExpansion ?? this.messageExpansion,
      inputFocus: inputFocus ?? this.inputFocus,
      inputExpansion: inputExpansion ?? this.inputExpansion,
      sendButtonPress: sendButtonPress ?? this.sendButtonPress,
      attachmentButton: attachmentButton ?? this.attachmentButton,
      streamingIndicator: streamingIndicator ?? this.streamingIndicator,
      typingIndicator: typingIndicator ?? this.typingIndicator,
      skeletonShimmer: skeletonShimmer ?? this.skeletonShimmer,
      pullToRefresh: pullToRefresh ?? this.pullToRefresh,
      themeSwitch: themeSwitch ?? this.themeSwitch,
      colorTransition: colorTransition ?? this.colorTransition,
      layoutTransition: layoutTransition ?? this.layoutTransition,
      elasticOut: elasticOut ?? this.elasticOut,
      smoothOut: smoothOut ?? this.smoothOut,
      quickOut: quickOut ?? this.quickOut,
      slideOut: slideOut ?? this.slideOut,
      bounceOut: bounceOut ?? this.bounceOut,
      materialEase: materialEase ?? this.materialEase,
      messageSlideInCurve: messageSlideInCurve ?? this.messageSlideInCurve,
      messageFadeInCurve: messageFadeInCurve ?? this.messageFadeInCurve,
      messageExpansionCurve:
          messageExpansionCurve ?? this.messageExpansionCurve,
      inputFocusCurve: inputFocusCurve ?? this.inputFocusCurve,
      sendButtonCurve: sendButtonCurve ?? this.sendButtonCurve,
      springPhysics: springPhysics ?? this.springPhysics,
      gentleSpring: gentleSpring ?? this.gentleSpring,
      snappySpring: snappySpring ?? this.snappySpring,
    );
  }

  /// Scale all animation durations by a factor
  ChatAnimationPresets scale(double scaleFactor) {
    return ChatAnimationPresets(
      microInteraction: Duration(
        milliseconds: (microInteraction.inMilliseconds * scaleFactor).round(),
      ),
      quickTransition: Duration(
        milliseconds: (quickTransition.inMilliseconds * scaleFactor).round(),
      ),
      mediumTransition: Duration(
        milliseconds: (mediumTransition.inMilliseconds * scaleFactor).round(),
      ),
      slowTransition: Duration(
        milliseconds: (slowTransition.inMilliseconds * scaleFactor).round(),
      ),
      messageSlideIn: Duration(
        milliseconds: (messageSlideIn.inMilliseconds * scaleFactor).round(),
      ),
      messageFadeIn: Duration(
        milliseconds: (messageFadeIn.inMilliseconds * scaleFactor).round(),
      ),
      messageTypewriter: Duration(
        milliseconds: (messageTypewriter.inMilliseconds * scaleFactor).round(),
      ),
      messageExpansion: Duration(
        milliseconds: (messageExpansion.inMilliseconds * scaleFactor).round(),
      ),
      inputFocus: Duration(
        milliseconds: (inputFocus.inMilliseconds * scaleFactor).round(),
      ),
      inputExpansion: Duration(
        milliseconds: (inputExpansion.inMilliseconds * scaleFactor).round(),
      ),
      sendButtonPress: Duration(
        milliseconds: (sendButtonPress.inMilliseconds * scaleFactor).round(),
      ),
      attachmentButton: Duration(
        milliseconds: (attachmentButton.inMilliseconds * scaleFactor).round(),
      ),
      streamingIndicator: Duration(
        milliseconds: (streamingIndicator.inMilliseconds * scaleFactor).round(),
      ),
      typingIndicator: Duration(
        milliseconds: (typingIndicator.inMilliseconds * scaleFactor).round(),
      ),
      skeletonShimmer: Duration(
        milliseconds: (skeletonShimmer.inMilliseconds * scaleFactor).round(),
      ),
      pullToRefresh: Duration(
        milliseconds: (pullToRefresh.inMilliseconds * scaleFactor).round(),
      ),
      themeSwitch: Duration(
        milliseconds: (themeSwitch.inMilliseconds * scaleFactor).round(),
      ),
      colorTransition: Duration(
        milliseconds: (colorTransition.inMilliseconds * scaleFactor).round(),
      ),
      layoutTransition: Duration(
        milliseconds: (layoutTransition.inMilliseconds * scaleFactor).round(),
      ),
      // Curves remain the same
      elasticOut: elasticOut,
      smoothOut: smoothOut,
      quickOut: quickOut,
      slideOut: slideOut,
      bounceOut: bounceOut,
      materialEase: materialEase,
      messageSlideInCurve: messageSlideInCurve,
      messageFadeInCurve: messageFadeInCurve,
      messageExpansionCurve: messageExpansionCurve,
      inputFocusCurve: inputFocusCurve,
      sendButtonCurve: sendButtonCurve,
      springPhysics: springPhysics,
      gentleSpring: gentleSpring,
      snappySpring: snappySpring,
    );
  }

  /// Lerp between two animation preset instances
  ChatAnimationPresets lerp(ChatAnimationPresets other, double t) {
    return ChatAnimationPresets(
      microInteraction: _lerpDuration(
        microInteraction,
        other.microInteraction,
        t,
      ),
      quickTransition: _lerpDuration(quickTransition, other.quickTransition, t),
      mediumTransition: _lerpDuration(
        mediumTransition,
        other.mediumTransition,
        t,
      ),
      slowTransition: _lerpDuration(slowTransition, other.slowTransition, t),
      messageSlideIn: _lerpDuration(messageSlideIn, other.messageSlideIn, t),
      messageFadeIn: _lerpDuration(messageFadeIn, other.messageFadeIn, t),
      messageTypewriter: _lerpDuration(
        messageTypewriter,
        other.messageTypewriter,
        t,
      ),
      messageExpansion: _lerpDuration(
        messageExpansion,
        other.messageExpansion,
        t,
      ),
      inputFocus: _lerpDuration(inputFocus, other.inputFocus, t),
      inputExpansion: _lerpDuration(inputExpansion, other.inputExpansion, t),
      sendButtonPress: _lerpDuration(sendButtonPress, other.sendButtonPress, t),
      attachmentButton: _lerpDuration(
        attachmentButton,
        other.attachmentButton,
        t,
      ),
      streamingIndicator: _lerpDuration(
        streamingIndicator,
        other.streamingIndicator,
        t,
      ),
      typingIndicator: _lerpDuration(typingIndicator, other.typingIndicator, t),
      skeletonShimmer: _lerpDuration(skeletonShimmer, other.skeletonShimmer, t),
      pullToRefresh: _lerpDuration(pullToRefresh, other.pullToRefresh, t),
      themeSwitch: _lerpDuration(themeSwitch, other.themeSwitch, t),
      colorTransition: _lerpDuration(colorTransition, other.colorTransition, t),
      layoutTransition: _lerpDuration(
        layoutTransition,
        other.layoutTransition,
        t,
      ),
      // Curves don't lerp - use threshold
      elasticOut: t < 0.5 ? elasticOut : other.elasticOut,
      smoothOut: t < 0.5 ? smoothOut : other.smoothOut,
      quickOut: t < 0.5 ? quickOut : other.quickOut,
      slideOut: t < 0.5 ? slideOut : other.slideOut,
      bounceOut: t < 0.5 ? bounceOut : other.bounceOut,
      materialEase: t < 0.5 ? materialEase : other.materialEase,
      messageSlideInCurve:
          t < 0.5 ? messageSlideInCurve : other.messageSlideInCurve,
      messageFadeInCurve:
          t < 0.5 ? messageFadeInCurve : other.messageFadeInCurve,
      messageExpansionCurve:
          t < 0.5 ? messageExpansionCurve : other.messageExpansionCurve,
      inputFocusCurve: t < 0.5 ? inputFocusCurve : other.inputFocusCurve,
      sendButtonCurve: t < 0.5 ? sendButtonCurve : other.sendButtonCurve,
      springPhysics: t < 0.5 ? springPhysics : other.springPhysics,
      gentleSpring: t < 0.5 ? gentleSpring : other.gentleSpring,
      snappySpring: t < 0.5 ? snappySpring : other.snappySpring,
    );
  }

  Duration _lerpDuration(Duration a, Duration b, double t) {
    return Duration(
      milliseconds: lerpDouble(
            a.inMilliseconds.toDouble(),
            b.inMilliseconds.toDouble(),
            t,
          )?.round() ??
          a.inMilliseconds,
    );
  }

  /// Predefined animation presets
  static const ChatAnimationPresets standard = ChatAnimationPresets();

  static final ChatAnimationPresets fast = const ChatAnimationPresets().scale(
    0.7,
  );

  static final ChatAnimationPresets slow = const ChatAnimationPresets().scale(
    1.5,
  );

  static const ChatAnimationPresets reduced = ChatAnimationPresets(
    microInteraction: Duration(milliseconds: 0),
    quickTransition: Duration(milliseconds: 0),
    mediumTransition: Duration(milliseconds: 0),
    slowTransition: Duration(milliseconds: 0),
    messageSlideIn: Duration(milliseconds: 0),
    messageFadeIn: Duration(milliseconds: 0),
    inputFocus: Duration(milliseconds: 0),
    sendButtonPress: Duration(milliseconds: 0),
    themeSwitch: Duration(milliseconds: 0),
  );

  static const ChatAnimationPresets chatGptStyle = ChatAnimationPresets(
    messageTypewriter: Duration(milliseconds: 25),
    messageSlideIn: Duration(milliseconds: 300),
    messageFadeIn: Duration(milliseconds: 200),
    messageSlideInCurve: Curves.easeOutCubic,
    messageFadeInCurve: Curves.easeInOut,
  );

  static const ChatAnimationPresets claudeStyle = ChatAnimationPresets(
    messageTypewriter: Duration(milliseconds: 35),
    messageSlideIn: Duration(milliseconds: 350),
    messageFadeIn: Duration(milliseconds: 250),
    messageSlideInCurve: Curves.easeOutQuart,
    messageFadeInCurve: Curves.easeOut,
  );

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ChatAnimationPresets &&
            microInteraction == other.microInteraction &&
            quickTransition == other.quickTransition &&
            mediumTransition == other.mediumTransition &&
            messageSlideIn == other.messageSlideIn &&
            messageFadeIn == other.messageFadeIn &&
            messageTypewriter == other.messageTypewriter &&
            inputFocus == other.inputFocus &&
            sendButtonPress == other.sendButtonPress &&
            themeSwitch == other.themeSwitch);
  }

  @override
  int get hashCode {
    return Object.hash(
      microInteraction,
      quickTransition,
      mediumTransition,
      messageSlideIn,
      messageFadeIn,
      messageTypewriter,
      inputFocus,
      sendButtonPress,
      themeSwitch,
    );
  }
}
