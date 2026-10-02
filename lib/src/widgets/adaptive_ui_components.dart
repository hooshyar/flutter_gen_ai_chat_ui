import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Adaptive message bubble that adjusts to screen size and platform
class AdaptiveMessageBubble extends StatelessWidget {
  final Widget child;
  final bool isUser;
  final Color? backgroundColor;
  final Color? textColor;
  final EdgeInsets? padding;
  final BorderRadius? borderRadius;
  final double? maxWidth;
  final BoxShadow? shadow;
  final Border? border;

  const AdaptiveMessageBubble({
    super.key,
    required this.child,
    required this.isUser,
    this.backgroundColor,
    this.textColor,
    this.padding,
    this.borderRadius,
    this.maxWidth,
    this.shadow,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final theme = Theme.of(context);

    // Adaptive sizing based on screen width
    final adaptiveMaxWidth = maxWidth ?? _getAdaptiveMaxWidth(screenWidth);
    final adaptivePadding = padding ?? _getAdaptivePadding(screenWidth);
    final adaptiveBorderRadius = borderRadius ?? _getAdaptiveBorderRadius();

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: adaptiveMaxWidth),
      child: Container(
        padding: adaptivePadding,
        decoration: BoxDecoration(
          color: backgroundColor ?? _getDefaultBackgroundColor(context),
          borderRadius: adaptiveBorderRadius,
          border: border,
          boxShadow: shadow != null ? [shadow!] : _getDefaultShadow(context),
        ),
        child: DefaultTextStyle(
          style: theme.textTheme.bodyMedium!.copyWith(
            color: textColor ?? _getDefaultTextColor(context),
          ),
          child: child,
        ),
      ),
    );
  }

  double _getAdaptiveMaxWidth(double screenWidth) {
    if (screenWidth < 600) {
      // Mobile
      return screenWidth * 0.8;
    } else if (screenWidth < 1200) {
      // Tablet
      return screenWidth * 0.7;
    } else {
      // Desktop
      return screenWidth * 0.5;
    }
  }

  EdgeInsets _getAdaptivePadding(double screenWidth) {
    if (screenWidth < 600) {
      // Mobile - smaller padding
      return const EdgeInsets.symmetric(horizontal: 12, vertical: 8);
    } else {
      // Tablet/Desktop - larger padding
      return const EdgeInsets.symmetric(horizontal: 16, vertical: 12);
    }
  }

  BorderRadius _getAdaptiveBorderRadius() {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      // iOS style - more rounded
      return BorderRadius.circular(20);
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      // Android style - moderately rounded
      return BorderRadius.circular(16);
    } else {
      // Desktop - less rounded
      return BorderRadius.circular(12);
    }
  }

  Color _getDefaultBackgroundColor(BuildContext context) {
    final theme = Theme.of(context);
    if (isUser) {
      return theme.colorScheme.primary;
    } else {
      return theme.colorScheme.surfaceContainerHighest;
    }
  }

  Color _getDefaultTextColor(BuildContext context) {
    final theme = Theme.of(context);
    if (isUser) {
      return theme.colorScheme.onPrimary;
    } else {
      return theme.colorScheme.onSurface;
    }
  }

  List<BoxShadow>? _getDefaultShadow(BuildContext context) {
    return [
      BoxShadow(
        color: Theme.of(context).shadowColor.withValues(alpha: 0.1),
        blurRadius: 4,
        offset: const Offset(0, 2),
      ),
    ];
  }
}

/// Responsive chat layout that adapts to different screen sizes
class ResponsiveChatLayout extends StatelessWidget {
  final Widget messageList;
  final Widget inputField;
  final Widget? sidebar;
  final Widget? header;
  final EdgeInsets? padding;
  final bool showSidebar;

  const ResponsiveChatLayout({
    super.key,
    required this.messageList,
    required this.inputField,
    this.sidebar,
    this.header,
    this.padding,
    this.showSidebar = true,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;

        if (screenWidth < 600) {
          // Mobile layout - single column
          return _buildMobileLayout();
        } else if (screenWidth < 1200) {
          // Tablet layout - adaptive sidebar
          return _buildTabletLayout();
        } else {
          // Desktop layout - full sidebar
          return _buildDesktopLayout();
        }
      },
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        if (header != null) header!,
        Expanded(child: messageList),
        inputField,
      ],
    );
  }

  Widget _buildTabletLayout() {
    if (showSidebar && sidebar != null) {
      return Row(
        children: [
          SizedBox(width: 300, child: sidebar!),
          Expanded(
            child: Column(
              children: [
                if (header != null) header!,
                Expanded(child: messageList),
                inputField,
              ],
            ),
          ),
        ],
      );
    } else {
      return _buildMobileLayout();
    }
  }

  Widget _buildDesktopLayout() {
    if (showSidebar && sidebar != null) {
      return Row(
        children: [
          SizedBox(width: 350, child: sidebar!),
          Expanded(
            child: Column(
              children: [
                if (header != null) header!,
                Expanded(
                  child: Padding(
                    padding:
                        padding ?? const EdgeInsets.symmetric(horizontal: 24),
                    child: messageList,
                  ),
                ),
                Padding(
                  padding: padding ?? const EdgeInsets.all(24),
                  child: inputField,
                ),
              ],
            ),
          ),
        ],
      );
    } else {
      return Column(
        children: [
          if (header != null) header!,
          Expanded(
            child: Padding(
              padding: padding ?? const EdgeInsets.symmetric(horizontal: 24),
              child: messageList,
            ),
          ),
          Padding(
            padding: padding ?? const EdgeInsets.all(24),
            child: inputField,
          ),
        ],
      );
    }
  }
}

/// Platform-aware UI components
class PlatformAwareComponents {
  /// Get platform-specific loading indicator
  static Widget loadingIndicator({Color? color, double? size}) {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return SizedBox(
        width: size ?? 20,
        height: size ?? 20,
        child: CircularProgressIndicator.adaptive(
          valueColor: AlwaysStoppedAnimation(color),
        ),
      );
    } else {
      return SizedBox(
        width: size ?? 20,
        height: size ?? 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation(color),
        ),
      );
    }
  }

  /// Get platform-specific button style
  static ButtonStyle getButtonStyle(
    BuildContext context, {
    bool isPrimary = true,
  }) {
    final theme = Theme.of(context);

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor:
            isPrimary ? theme.colorScheme.primary : theme.colorScheme.secondary,
        foregroundColor: isPrimary
            ? theme.colorScheme.onPrimary
            : theme.colorScheme.onSecondary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      );
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      return ElevatedButton.styleFrom(
        elevation: isPrimary ? 2 : 1,
        backgroundColor:
            isPrimary ? theme.colorScheme.primary : theme.colorScheme.secondary,
        foregroundColor: isPrimary
            ? theme.colorScheme.onPrimary
            : theme.colorScheme.onSecondary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      );
    } else {
      // Desktop
      return ElevatedButton.styleFrom(
        elevation: 1,
        backgroundColor:
            isPrimary ? theme.colorScheme.primary : theme.colorScheme.secondary,
        foregroundColor: isPrimary
            ? theme.colorScheme.onPrimary
            : theme.colorScheme.onSecondary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      );
    }
  }

  /// Get platform-specific input decoration
  static InputDecoration getInputDecoration(
    BuildContext context, {
    String? hintText,
    IconData? prefixIcon,
    Widget? suffixIcon,
  }) {
    final theme = Theme.of(context);

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return InputDecoration(
        hintText: hintText,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: theme.colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      );
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      return InputDecoration(
        hintText: hintText,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: theme.colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: theme.colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: theme.colorScheme.primary),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      );
    } else {
      // Desktop
      return InputDecoration(
        hintText: hintText,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: theme.colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: theme.colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      );
    }
  }
}

/// Breakpoint-based layout helper
class LayoutBreakpoints {
  static const double mobile = 600;
  static const double tablet = 1200;
  static const double desktop = 1920;

  /// Get current device type based on width
  static DeviceType getDeviceType(double width) {
    if (width < mobile) return DeviceType.mobile;
    if (width < tablet) return DeviceType.tablet;
    return DeviceType.desktop;
  }

  /// Check if current width is mobile
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobile;
  }

  /// Check if current width is tablet
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobile && width < tablet;
  }

  /// Check if current width is desktop
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= tablet;
  }
}

/// Device type enumeration
enum DeviceType { mobile, tablet, desktop }

/// Adaptive grid widget that adjusts column count based on screen size
class AdaptiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double childAspectRatio;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final EdgeInsets padding;

  const AdaptiveGrid({
    super.key,
    required this.children,
    this.childAspectRatio = 1.0,
    this.mainAxisSpacing = 8.0,
    this.crossAxisSpacing = 8.0,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final deviceType = LayoutBreakpoints.getDeviceType(
          constraints.maxWidth,
        );
        final crossAxisCount = _getCrossAxisCount(deviceType);

        return Padding(
          padding: padding,
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: childAspectRatio,
              mainAxisSpacing: mainAxisSpacing,
              crossAxisSpacing: crossAxisSpacing,
            ),
            itemCount: children.length,
            itemBuilder: (context, index) => children[index],
          ),
        );
      },
    );
  }

  int _getCrossAxisCount(DeviceType deviceType) {
    switch (deviceType) {
      case DeviceType.mobile:
        return 1;
      case DeviceType.tablet:
        return 2;
      case DeviceType.desktop:
        return 3;
    }
  }
}

/// Adaptive spacing that changes based on screen size
class AdaptiveSpacing extends StatelessWidget {
  final Axis direction;
  final double mobile;
  final double tablet;
  final double desktop;

  const AdaptiveSpacing({
    super.key,
    this.direction = Axis.vertical,
    this.mobile = 8.0,
    this.tablet = 12.0,
    this.desktop = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    final deviceType = LayoutBreakpoints.getDeviceType(
      MediaQuery.of(context).size.width,
    );

    double spacing;
    switch (deviceType) {
      case DeviceType.mobile:
        spacing = mobile;
        break;
      case DeviceType.tablet:
        spacing = tablet;
        break;
      case DeviceType.desktop:
        spacing = desktop;
        break;
    }

    if (direction == Axis.vertical) {
      return SizedBox(height: spacing);
    } else {
      return SizedBox(width: spacing);
    }
  }
}

/// Safe area wrapper that adapts to different platforms
class AdaptiveSafeArea extends StatelessWidget {
  final Widget child;
  final bool top;
  final bool bottom;
  final bool left;
  final bool right;

  const AdaptiveSafeArea({
    super.key,
    required this.child,
    this.top = true,
    this.bottom = true,
    this.left = true,
    this.right = true,
  });

  @override
  Widget build(BuildContext context) {
    // On desktop, we don't need safe area
    if (LayoutBreakpoints.isDesktop(context)) {
      return child;
    }

    return SafeArea(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: child,
    );
  }
}
