import 'package:flutter/material.dart';

import 'chat/media.dart'; // Add import for ChatMedia

/// Options for customizing the file upload functionality
class FileUploadOptions {
  /// Whether file uploading is enabled
  final bool enabled;

  /// Custom icon for the file upload button
  final IconData? uploadIcon;

  /// Custom color for the file upload button
  final Color? uploadIconColor;

  /// Custom size for the file upload button
  final double? uploadIconSize;

  /// Custom tooltip for the file upload button
  final String? uploadTooltip;

  /// Callback to be invoked when a file is selected
  final void Function(List<Object>)? onFilesSelected;

  /// Maximum number of files allowed in a single message
  final int maxFilesPerMessage;

  /// Maximum file size in bytes (defaults to 10MB)
  final int maxFileSize;

  /// Allowed file types for upload
  final List<String>? allowedFileTypes;

  /// Custom builder for the upload button
  final Widget Function(BuildContext, VoidCallback)? customUploadButtonBuilder;

  /// Custom builder for file preview before sending
  final Widget Function(BuildContext, Object)? filePreviewBuilder;

  /// Custom builder for file display in chat message
  final Widget Function(BuildContext, ChatMedia)? fileDisplayBuilder;

  /// Whether to show a confirmation dialog before sending files
  final bool confirmBeforeSend;

  /// Custom text for the upload button
  final String? uploadButtonText;

  const FileUploadOptions({
    this.enabled = true,
    this.uploadIcon = Icons.attach_file,
    this.uploadIconColor,
    this.uploadIconSize = 24.0,
    this.uploadTooltip = 'Attach files',
    this.onFilesSelected,
    this.maxFilesPerMessage = 5,
    this.maxFileSize = 10 * 1024 * 1024, // 10MB default
    this.allowedFileTypes,
    this.customUploadButtonBuilder,
    this.filePreviewBuilder,
    this.fileDisplayBuilder,
    this.confirmBeforeSend = false,
    this.uploadButtonText,
  });

  /// Creates a copy of this FileUploadOptions with the given fields replaced with new values
  FileUploadOptions copyWith({
    bool? enabled,
    IconData? uploadIcon,
    Color? uploadIconColor,
    double? uploadIconSize,
    String? uploadTooltip,
    void Function(List<Object>)? onFilesSelected,
    int? maxFilesPerMessage,
    int? maxFileSize,
    List<String>? allowedFileTypes,
    Widget Function(BuildContext, VoidCallback)? customUploadButtonBuilder,
    Widget Function(BuildContext, Object)? filePreviewBuilder,
    Widget Function(BuildContext, ChatMedia)? fileDisplayBuilder,
    bool? confirmBeforeSend,
    String? uploadButtonText,
  }) =>
      FileUploadOptions(
        enabled: enabled ?? this.enabled,
        uploadIcon: uploadIcon ?? this.uploadIcon,
        uploadIconColor: uploadIconColor ?? this.uploadIconColor,
        uploadIconSize: uploadIconSize ?? this.uploadIconSize,
        uploadTooltip: uploadTooltip ?? this.uploadTooltip,
        onFilesSelected: onFilesSelected ?? this.onFilesSelected,
        maxFilesPerMessage: maxFilesPerMessage ?? this.maxFilesPerMessage,
        maxFileSize: maxFileSize ?? this.maxFileSize,
        allowedFileTypes: allowedFileTypes ?? this.allowedFileTypes,
        customUploadButtonBuilder:
            customUploadButtonBuilder ?? this.customUploadButtonBuilder,
        filePreviewBuilder: filePreviewBuilder ?? this.filePreviewBuilder,
        fileDisplayBuilder: fileDisplayBuilder ?? this.fileDisplayBuilder,
        confirmBeforeSend: confirmBeforeSend ?? this.confirmBeforeSend,
        uploadButtonText: uploadButtonText ?? this.uploadButtonText,
      );
}
