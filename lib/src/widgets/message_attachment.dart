import 'package:flutter/material.dart';
import '../models/chat/media.dart';
import '../utils/color_extensions.dart';

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

  /// Creates a [MessageAttachment] widget
  const MessageAttachment({
    super.key,
    required this.media,
    this.customBuilder,
    this.onTap,
    this.enableImageTaps = true,
  });

  @override
  Widget build(BuildContext context) {
    // Use custom builder if provided
    if (customBuilder != null) {
      return customBuilder!(context, media);
    }

    // Use media's custom builder if provided
    if (media.customBuilder != null) {
      return media.customBuilder!(context, media);
    }

    // Default rendering based on media type
    return _buildByType(context);
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
      default:
        return _buildGenericAttachment(context, isDarkMode);
    }
  }

  Widget _buildImageAttachment(BuildContext context, bool isDarkMode) {
    return GestureDetector(
      onTap: enableImageTaps ? () => onTap?.call(media) : null,
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
              color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
              child: Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
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
