import 'package:flutter/material.dart';
import '../models/chat/media.dart';
import '../utils/color_extensions.dart';
import 'attachment_lightbox.dart';

/// Displays a media attachment in a chat message
class MessageAttachment extends StatelessWidget {
  /// The media to display
  final ChatMedia media;

  /// Whether to enable tapping on images
  final bool enableImageTaps;

  /// Callback when the media is tapped
  final void Function(ChatMedia)? onTap;

  /// Custom builder for rendering media
  final Widget Function(BuildContext, ChatMedia)? customBuilder;

  /// Whether tapping an image (when [onTap] is not set) opens a built-in
  /// full-screen [AttachmentLightbox]. Defaults to false — additive,
  /// existing consumers see no change in tap behavior unless they opt in.
  /// Has no effect when [onTap] is set; an explicit [onTap] always wins.
  final bool enableBuiltInLightbox;

  /// The other media in the same message, used so the built-in lightbox can
  /// page through every image in the message rather than showing just the
  /// one that was tapped. Defaults to `[media]` (a single-image gallery)
  /// when not provided. Non-image entries are filtered out automatically.
  final List<ChatMedia>? siblingMedia;

  /// Creates a [MessageAttachment] widget
  const MessageAttachment({
    super.key,
    required this.media,
    this.customBuilder,
    this.onTap,
    this.enableImageTaps = true,
    this.enableBuiltInLightbox = false,
    this.siblingMedia,
  });

  @override
  Widget build(BuildContext context) {
    final Widget child;
    // Use custom builder if provided
    if (customBuilder != null) {
      child = customBuilder!(context, media);
    } else if (media.customBuilder != null) {
      // Use media's custom builder if provided
      child = media.customBuilder!(context, media);
    } else {
      // Default rendering based on media type
      child = _buildByType(context);
    }

    final progress = media.uploadProgress;
    if (progress == null || progress >= 1.0) return child;
    return _withUploadProgressOverlay(context, child, progress);
  }

  /// Overlays a centered circular progress indicator + percentage on top of
  /// [child] while `media.uploadProgress` is set and below 1.0. Applies
  /// uniformly regardless of media type, so every attachment kind gets the
  /// same "uploading" treatment without each type-specific builder needing
  /// its own progress-rendering logic.
  Widget _withUploadProgressOverlay(
      BuildContext context, Widget child, double progress) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Opacity(opacity: 0.5, child: child),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.black.withOpacityCompat(0.55),
            shape: BoxShape.circle,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  strokeWidth: 3,
                  color: Colors.white,
                  backgroundColor: Colors.white.withOpacityCompat(0.3),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${(progress.clamp(0.0, 1.0) * 100).round()}%',
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _handleImageTap(BuildContext context) {
    if (onTap != null) {
      onTap!(media);
      return;
    }
    if (!enableBuiltInLightbox) return;

    final gallery = (siblingMedia ?? [media])
        .where((m) => m.type == ChatMediaType.image)
        .toList();
    var initialIndex = gallery.indexOf(media);
    if (initialIndex < 0) {
      // `media` itself isn't in `gallery` (e.g. siblingMedia was passed
      // without it, or filtering removed it) — show it on its own rather
      // than silently jumping to a different image.
      gallery.insert(0, media);
      initialIndex = 0;
    }
    AttachmentLightbox.show(context,
        images: gallery, initialIndex: initialIndex);
  }

  Widget _buildByType(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    switch (media.type) {
      case ChatMediaType.image:
        return _buildImageAttachment(context, isDarkMode);
      case ChatMediaType.video:
        return _buildVideoAttachment(context, isDarkMode);
      case ChatMediaType.audio:
        return _buildAudioAttachment(context, isDarkMode);
      case ChatMediaType.document:
        return _buildDocumentAttachment(context, isDarkMode);
      case ChatMediaType.other:
        return _buildGenericAttachment(context, isDarkMode);
    }
  }

  Widget _buildImageAttachment(BuildContext context, bool isDarkMode) {
    return GestureDetector(
      onTap: enableImageTaps ? () => _handleImageTap(context) : null,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
          maxHeight: 200,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
            width: 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.network(
          media.url,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              width: 200,
              height: 150,
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                      strokeWidth: 2,
                      color: Theme.of(context).primaryColor,
                      backgroundColor:
                          Theme.of(context).primaryColor.withValues(alpha: 0.2),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Loading image...',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (loadingProgress.expectedTotalBytes != null)
                      Text(
                        '${((loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!) * 100).toInt()}%',
                        style: TextStyle(
                          fontSize: 10,
                          color:
                              isDarkMode ? Colors.grey[500] : Colors.grey[500],
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: 200,
              height: 150,
              color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
              child: const Center(
                child: Icon(Icons.broken_image, size: 40),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildVideoAttachment(BuildContext context, bool isDarkMode) {
    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[850] : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Image.network(
                (media.metadata?['thumbnail'] as String?) ??
                    'https://via.placeholder.com/250x150',
                fit: BoxFit.cover,
                width: 250,
                height: 150,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    width: 250,
                    height: 150,
                    color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                            strokeWidth: 2,
                            color: Theme.of(context).primaryColor,
                            backgroundColor: Theme.of(context)
                                .primaryColor
                                .withValues(alpha: 0.2),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Loading thumbnail...',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDarkMode
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 250,
                    height: 150,
                    color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                    child: const Icon(Icons.videocam, size: 40),
                  );
                },
              ),
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacityCompat(0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                const Icon(Icons.videocam, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    media.fileName ?? 'Video',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          if (media.size != null)
            Padding(
              padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
              child: Text(
                _formatFileSize(media.size!),
                style: TextStyle(
                  fontSize: 12,
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAudioAttachment(BuildContext context, bool isDarkMode) {
    return Container(
      width: 250,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[850] : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacityCompat(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.audiotrack,
              color: Theme.of(context).primaryColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  media.fileName ?? 'Audio file',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (media.size != null)
                  Text(
                    _formatFileSize(media.size!),
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.play_arrow),
            onPressed: () => onTap?.call(media),
            color: Theme.of(context).primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentAttachment(BuildContext context, bool isDarkMode) {
    return Container(
      width: 250,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[850] : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacityCompat(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getDocumentIcon(media.extension),
              color: Theme.of(context).primaryColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  media.fileName ?? 'Document',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (media.size != null || media.extension != null)
                  Text(
                    media.size != null
                        ? '${media.extension?.toUpperCase() ?? ''} • ${_formatFileSize(media.size!)}'
                        : media.extension?.toUpperCase() ?? '',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => onTap?.call(media),
            color: Theme.of(context).primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildGenericAttachment(BuildContext context, bool isDarkMode) {
    return Container(
      width: 250,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[850] : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacityCompat(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.insert_drive_file,
              color: Theme.of(context).primaryColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  media.fileName ?? 'File',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (media.size != null)
                  Text(
                    _formatFileSize(media.size!),
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => onTap?.call(media),
            color: Theme.of(context).primaryColor,
          ),
        ],
      ),
    );
  }

  // Helper to format file size in human-readable format
  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  // Helper to get icon based on document type
  IconData _getDocumentIcon(String? extension) {
    if (extension == null) return Icons.insert_drive_file;

    switch (extension.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'txt':
        return Icons.article;
      case 'zip':
      case 'rar':
      case '7z':
        return Icons.folder_zip;
      default:
        return Icons.insert_drive_file;
    }
  }
}
