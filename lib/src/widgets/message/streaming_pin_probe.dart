import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Wraps one message row of the chat list and remembers the height it was
/// last laid out at.
///
/// The streaming pin (`ScrollBehaviorConfig.pinDuringStreaming`) positions
/// the list while the list itself is still being laid out, so that a frame
/// is never painted with the pinned message in the wrong place (issue #42).
/// At that point the framework does not allow reading another render box's
/// `size`, so this probe records its own height during its own layout, where
/// that is allowed, and the pin reads [RenderStreamingPinProbe.laidOutHeight]
/// instead.
///
/// It is a plain proxy: it has no effect on layout, painting or hit testing.
class StreamingPinProbe extends SingleChildRenderObjectWidget {
  /// Creates a probe around [child].
  const StreamingPinProbe({super.key, super.child});

  @override
  RenderStreamingPinProbe createRenderObject(BuildContext context) =>
      RenderStreamingPinProbe();
}

/// Render object of [StreamingPinProbe].
class RenderStreamingPinProbe extends RenderProxyBox {
  /// Creates the render object, optionally with a [child].
  RenderStreamingPinProbe([RenderBox? child]) : super(child);

  double? _laidOutHeight;

  /// The height this box had at the end of its most recent layout, or null
  /// before its first layout. Unlike `size`, it can be read by anyone at any
  /// time, including while an ancestor is still being laid out.
  double? get laidOutHeight => _laidOutHeight;

  @override
  void performLayout() {
    super.performLayout();
    _laidOutHeight = size.height;
  }
}
