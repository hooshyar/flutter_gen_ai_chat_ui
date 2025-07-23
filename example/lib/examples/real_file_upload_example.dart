import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:provider/provider.dart';

import '../models/app_state.dart';

/// A real file upload example that demonstrates how to use the Flutter Gen AI Chat UI
/// with actual file picking and image selection functionality.
class RealFileUploadExample extends StatefulWidget {
  const RealFileUploadExample({super.key});

  @override
  State<RealFileUploadExample> createState() => _RealFileUploadExampleState();
}

class _RealFileUploadExampleState extends State<RealFileUploadExample> {
  // Chat controller to manage messages
  final _chatController = ChatMessagesController();

  // User definitions
  final _currentUser = const ChatUser(id: 'user123', firstName: 'You');
  final _aiUser = const ChatUser(
    id: 'ai123',
    firstName: 'AI Assistant',
    avatar: 'https://ui-avatars.com/api/?name=AI&background=6366f1&color=fff',
  );

  // Loading state
  bool _isGenerating = false;

  // File pickers
  final ImagePicker _imagePicker = ImagePicker();

  // Temporary files
  final List<File> _temporaryFiles = [];

  @override
  void initState() {
    super.initState();

    // Add welcome message
    _chatController.addMessage(
      ChatMessage(
        text: '# Real File Upload Example 📤\n\n'
            'This example demonstrates real file upload capabilities:\n\n'
            '- **Image uploads** from camera or gallery\n'
            '- **Document uploads** from file system\n'
            '- **Multiple file selection**\n'
            '- **File preview** before sending\n\n'
            'Try uploading files using the attachment button!',
        user: _aiUser,
        createdAt: DateTime.now(),
        isMarkdown: true,
      ),
    );
  }

  /// Handle file upload selection
  Future<void> _handleFileUpload(List<Object> files) async {
    // Show a bottom sheet with file upload options
    await showModalBottomSheet(
      context: context,
      builder: (context) => _buildFileUploadOptions(context),
    );
  }

  /// Build the file upload options bottom sheet
  Widget _buildFileUploadOptions(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          leading: const Icon(Icons.camera_alt),
          title: const Text('Take Photo'),
          onTap: () {
            Navigator.pop(context);
            _pickImage(ImageSource.camera);
          },
        ),
        ListTile(
          leading: const Icon(Icons.photo_library),
          title: const Text('Choose from Gallery'),
          onTap: () {
            Navigator.pop(context);
            _pickImage(ImageSource.gallery);
          },
        ),
        ListTile(
          leading: const Icon(Icons.attach_file),
          title: const Text('Upload Document'),
          onTap: () {
            Navigator.pop(context);
            _pickFile();
          },
        ),
        ListTile(
          leading: const Icon(Icons.folder),
          title: const Text('Upload Multiple Files'),
          onTap: () {
            Navigator.pop(context);
            _pickMultipleFiles();
          },
        ),
      ],
    );
  }

  /// Pick an image from the camera or gallery
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final File file = File(pickedFile.path);

        // Show caption dialog
        if (!mounted) return;
        final String? caption = await _showCaptionDialog(context);

        // Send file with the caption (empty string if skipped)
        _sendFileMessage([file], caption ?? '');
      }
    } catch (e) {
      _showErrorSnackBar('Error picking image: $e');
    }
  }

  /// Show a dialog to add a caption to an image
  Future<String?> _showCaptionDialog(BuildContext context) {
    final TextEditingController captionController = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add a caption'),
          content: TextField(
            controller: captionController,
            decoration: const InputDecoration(
              hintText: 'Enter a caption for your image...',
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(), // Skip caption
              child: const Text('Skip'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context)
                  .pop(captionController.text), // Add caption
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  /// Pick a single file
  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles();

      if (result != null) {
        File file = File(result.files.single.path!);

        // For documents, we could use the same caption feature or a different dialog
        if (!mounted) return;
        final String? caption = await _showCaptionDialog(context);

        _sendFileMessage([file], caption ?? '');
      }
    } catch (e) {
      _showErrorSnackBar('Error picking file: $e');
    }
  }

  /// Pick multiple files
  Future<void> _pickMultipleFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
      );

      if (result != null) {
        List<File> files = result.paths.map((path) => File(path!)).toList();

        // For multiple files, we might want a different caption approach
        if (!mounted) return;
        final String? caption =
            await _showMultipleFilesCaptionDialog(context, files.length);

        _sendFileMessage(files, caption ?? '');
      }
    } catch (e) {
      _showErrorSnackBar('Error picking files: $e');
    }
  }

  /// Show a dialog for multiple files caption
  Future<String?> _showMultipleFilesCaptionDialog(
      BuildContext context, int fileCount) {
    final TextEditingController captionController = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add a caption for $fileCount files'),
          content: TextField(
            controller: captionController,
            decoration: const InputDecoration(
              hintText: 'Enter a caption for your files...',
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(), // Skip caption
              child: const Text('Skip'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context)
                  .pop(captionController.text), // Add caption
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  /// Send a message with file attachments
  void _sendFileMessage(List<File> files, String caption) async {
    try {
      // Create media attachments from files
      List<ChatMedia> media = [];

      for (File file in files) {
        // Get file information
        String fileName = path.basename(file.path);
        int fileSize = await file.length();
        String fileExtension =
            path.extension(file.path).toLowerCase().replaceAll('.', '');

        // Save the file to app documents directory to make it accessible
        // (this step is necessary especially for temporary camera files)
        final Directory appDocDir = await getApplicationDocumentsDirectory();
        final String appDocPath = appDocDir.path;
        final String destFilePath =
            '$appDocPath/${DateTime.now().millisecondsSinceEpoch}_$fileName';

        final File destFile = await file.copy(destFilePath);
        _temporaryFiles.add(destFile); // Store for later cleanup

        // Determine file type
        ChatMediaType mediaType;
        if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(fileExtension)) {
          mediaType = ChatMediaType.image;
        } else if (['mp4', 'mov', 'avi', 'webm'].contains(fileExtension)) {
          mediaType = ChatMediaType.video;
        } else if (['mp3', 'wav', 'ogg', 'm4a'].contains(fileExtension)) {
          mediaType = ChatMediaType.audio;
        } else if (['pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'txt']
            .contains(fileExtension)) {
          mediaType = ChatMediaType.document;
        } else {
          mediaType = ChatMediaType.other;
        }

        // Create chat media object
        // Use file:// URI to access the local file
        media.add(ChatMedia(
          url: 'file://${destFile.path}',
          type: mediaType,
          fileName: fileName,
          extension: fileExtension,
          size: fileSize,
        ));
      }

      // Add user message with attachments
      _chatController.addMessage(
        ChatMessage(
          // Use the caption if provided, otherwise use a default message
          text: caption.isNotEmpty
              ? caption
              : (media.length > 1
                  ? 'I\'ve uploaded ${media.length} files.'
                  : 'I\'ve uploaded a file.'),
          user: _currentUser,
          createdAt: DateTime.now(),
          media: media,
        ),
      );

      // Generate AI response
      _generateAIResponse(media, caption);
    } catch (e) {
      _showErrorSnackBar('Error sending file: $e');
    }
  }

  /// Generate an AI response based on the attachments
  void _generateAIResponse(List<ChatMedia> attachments, String caption) {
    setState(() => _isGenerating = true);

    // Simulate AI processing time
    Future.delayed(const Duration(milliseconds: 1500), () {
      String response = '';
      final bool hasCaption = caption.isNotEmpty;

      if (attachments.length == 1) {
        final media = attachments.first;
        final String captionAcknowledgment =
            hasCaption ? ' and your caption: "${caption}"' : '';

        switch (media.type) {
          case ChatMediaType.image:
            response =
                'I\'ve received your image file$captionAcknowledgment (${_formatFileSize(media.size!)}). I can see this is a ${media.extension?.toUpperCase()} image named "${media.fileName}". Would you like me to analyze the content of this image?';
            break;
          case ChatMediaType.document:
            final extension = media.extension?.toUpperCase() ?? 'DOCUMENT';
            response =
                'I\'ve received your $extension file$captionAcknowledgment (${_formatFileSize(media.size!)}). The document is named "${media.fileName}". Would you like me to extract text or analyze the content of this document?';
            break;
          case ChatMediaType.video:
            response =
                'I\'ve received your video file$captionAcknowledgment (${_formatFileSize(media.size!)}). The file is in ${media.extension?.toUpperCase()} format and is named "${media.fileName}". Would you like me to extract audio or analyze frames from this video?';
            break;
          case ChatMediaType.audio:
            response =
                'I\'ve received your audio file$captionAcknowledgment (${_formatFileSize(media.size!)}). The file is in ${media.extension?.toUpperCase()} format and is named "${media.fileName}". Would you like me to transcribe this audio file or analyze its content?';
            break;
          case ChatMediaType.other:
            response =
                'I\'ve received your file$captionAcknowledgment (${_formatFileSize(media.size!)}). The file is named "${media.fileName}". What would you like me to do with this file?';
            break;
        }
      } else {
        // Multiple files
        final types = attachments
            .map((m) => m.type.toString().split('.').last)
            .toSet()
            .join(', ');
        final totalSize =
            attachments.fold<int>(0, (sum, media) => sum + (media.size ?? 0));
        final fileNames = attachments.map((m) => m.fileName).join(', ');

        final String captionAcknowledgment =
            hasCaption ? ' with caption: "$caption"' : '';

        response =
            'I\'ve received your ${attachments.length} files$captionAcknowledgment (${_formatFileSize(totalSize)}). The files include $types types, and are named: $fileNames. How would you like me to process these files?';
      }

      _chatController.addMessage(
        ChatMessage(
          text: response,
          user: _aiUser,
          createdAt: DateTime.now(),
        ),
      );

      setState(() => _isGenerating = false);
    });
  }

  /// Format file size in human-readable form
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

  /// Show an error snackbar
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Handle sending a text message
  Future<void> _handleSendMessage(ChatMessage message) async {
    setState(() => _isGenerating = true);

    // Simulate AI processing time
    await Future.delayed(const Duration(milliseconds: 800));

    _chatController.addMessage(
      ChatMessage(
        text:
            'Thanks for your message: "${message.text}"\n\nTo try the file upload functionality, click the attachment button in the input bar.',
        user: _aiUser,
        createdAt: DateTime.now(),
      ),
    );

    setState(() => _isGenerating = false);
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final colorScheme = Theme.of(context).colorScheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Real File Upload Example'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Theme toggle
          IconButton(
            icon: Icon(
              appState.themeMode == ThemeMode.dark
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
            onPressed: appState.toggleTheme,
            tooltip: 'Toggle theme',
          ),
          // Reset conversation
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _chatController.clearMessages();
              // Re-add welcome message
              _chatController.addMessage(
                ChatMessage(
                  text: '# Real File Upload Example 📤\n\n'
                      'This example demonstrates real file upload capabilities:\n\n'
                      '- **Image uploads** from camera or gallery\n'
                      '- **Document uploads** from file system\n'
                      '- **Multiple file selection**\n'
                      '- **File preview** before sending\n\n'
                      'Try uploading files using the attachment button!',
                  user: _aiUser,
                  createdAt: DateTime.now(),
                  isMarkdown: true,
                ),
              );
            },
            tooltip: 'Reset conversation',
          ),
        ],
      ),
      body: AiChatWidget(
        // Required parameters
        currentUser: _currentUser,
        aiUser: _aiUser,
        controller: _chatController,
        onSendMessage: _handleSendMessage,

        // Max width constraint
        maxWidth: appState.chatMaxWidth,

        // Loading configuration
        loadingConfig: LoadingConfig(
          isLoading: _isGenerating,
        ),

        // Message customization
        messageOptions: MessageOptions(
          showUserName: true,
          showTime: true,
          enableImageTaps: true,
          onMediaTap: (media) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Tapped on: ${media.fileName ?? 'File'}'),
                backgroundColor: colorScheme.primaryContainer,
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          bubbleStyle: BubbleStyle(
            userBubbleColor: colorScheme.primaryContainer,
            aiBubbleColor:
                isDarkMode ? colorScheme.surfaceContainerHighest : colorScheme.surface,
          ),
        ),

        // File upload configuration
        fileUploadOptions: FileUploadOptions(
          enabled: true,
          uploadIcon: Icons.attach_file,
          uploadIconColor: colorScheme.primary,
          uploadTooltip: 'Upload Files',
          onFilesSelected: _handleFileUpload,
          maxFilesPerMessage: 5,
        ),

        // Input customization
        inputOptions: InputOptions(
          sendOnEnter: true,
          decoration: InputDecoration(
            hintText: 'Type a message or upload files...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: isDarkMode
                ? colorScheme.surfaceContainerHighest
                : colorScheme.surfaceContainerHigh,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Clean up temporary files
    for (File file in _temporaryFiles) {
      try {
        if (file.existsSync()) {
          file.deleteSync();
        }
      } catch (_) {
        // Ignore errors on cleanup
      }
    }

    _chatController.dispose();
    super.dispose();
  }
}
