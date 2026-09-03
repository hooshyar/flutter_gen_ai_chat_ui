import 'package:flutter/material.dart';
import '../models/chat/media.dart';
import '../utils/color_extensions.dart';

/// A full-screen, swipeable, pinch-to-zoom preview for image attachments.
///
/// Not shown automatically — `MessageAttachment` opens it when
/// `enableBuiltInLightbox` is true and a consumer hasn't supplied their own
/// `onTap`. Can also be invoked directly (e.g. from a custom
/// `fileDisplayBuilder`) via [AttachmentLightbox.show].
class AttachmentLightbox extends StatefulWidget {
  /// Creates a lightbox over [images], initially showing [initialIndex].
  const AttachmentLightbox({
    super.key,
    required this.images,
    this.initialIndex = 0,
  });

  /// The images to page through. Non-image entries are ignored by
  /// `MessageAttachment` before this widget is built — this widget assumes
  /// every entry is displayable as an image.
  final List<ChatMedia> images;

  /// Which image in [images] to show first.
  final int initialIndex;

  /// Pushes an [AttachmentLightbox] as a translucent full-screen route.
  static Future<void> show(
    BuildContext context, {
    required List<ChatMedia> images,
    int initialIndex = 0,
  }) {
    return Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: Colors.black87,
        transitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (context, animation, secondaryAnimation) {
          return FadeTransition(
            opacity: animation,
            child: AttachmentLightbox(
              images: images,
              initialIndex: initialIndex,
            ),
          );
        },
      ),
    );
  }

  @override
  State<AttachmentLightbox> createState() => _AttachmentLightboxState();
}

class _AttachmentLightboxState extends State<AttachmentLightbox> {
  late final PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, widget.images.length - 1);
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final current = widget.images[_currentIndex];
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Stack(
          children: [
            GestureDetector(
              // Tapping the scrim (outside the zoomable image) dismisses —
              // InteractiveViewer consumes taps on the image itself.
              onTap: () => Navigator.of(context).maybePop(),
              behavior: HitTestBehavior.opaque,
              child: PageView.builder(
                controller: _pageController,
                itemCount: widget.images.length,
                onPageChanged: (index) => setState(() => _currentIndex = index),
                itemBuilder: (context, index) {
                  final media = widget.images[index];
                  return InteractiveViewer(
                    minScale: 1.0,
                    maxScale: 4.0,
                    child: Center(
                      child: Image.network(
                        media.url,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.broken_image,
                          color: Colors.white.withOpacityCompat(0.7),
                          size: 48,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                tooltip: 'Close',
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ),
            if (widget.images.length > 1)
              Positioned(
                bottom: 24,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacityCompat(0.5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '${_currentIndex + 1} / ${widget.images.length}',
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                ),
              ),
            if (current.fileName != null)
              Positioned(
                bottom: widget.images.length > 1 ? 56 : 24,
                left: 16,
                right: 16,
                child: Center(
                  child: Text(
                    current.fileName!,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withOpacityCompat(0.85),
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
