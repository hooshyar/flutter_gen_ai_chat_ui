// Attachments — file upload button + rendering an attached file in a message.
//
// The package doesn't bundle a file picker (kept out of core to stay
// dependency-light — see FileUploadOptions.onFilesSelected docs). A real app
// wires a package like `file_picker` there; this demo simulates picking one
// file so the attachment button + message rendering can be shown without a
// platform file-picker dependency.
import 'package:flutter/material.dart';
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';

import '../services/mock_ai_service.dart';

class AttachmentsChatExample extends StatefulWidget {
  const AttachmentsChatExample({super.key});

  @override
  State<AttachmentsChatExample> createState() => _AttachmentsChatExampleState();
}

class _AttachmentsChatExampleState extends State<AttachmentsChatExample> {
  final _controller = ChatMessagesController();
  final _aiService = ExampleAiService(style: ResponseStyle.conversational);
  bool _isLoading = false;

  static const _currentUser = ChatUser(id: 'user', name: 'You');
  static const _aiUser = ChatUser(id: 'ai', name: 'Assistant');

  void _onSendMessage(ChatMessage message) async {
    _controller.addMessage(message);
    setState(() => _isLoading = true);
    try {
      final response = await _aiService.generateResponse(message.text);
      if (!mounted) return;
      _controller.addMessage(
        ChatMessage(text: response, user: _aiUser, createdAt: DateTime.now()),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Stands in for a real file picker. `onFilesSelected` receives whatever
  /// the picker returns — here just a marker — and this method builds the
  /// actual message the same way a real picker's result would be handled.
  void _simulateAttachFile() {
    _controller.addMessage(ChatMessage(
      text: 'Here is the report you asked for.',
      user: _currentUser,
      createdAt: DateTime.now(),
      media: const [
        ChatMedia(
          url: 'quarterly-report.pdf',
          type: ChatMediaType.document,
          fileName: 'quarterly-report.pdf',
          size: 482 * 1024,
          extension: 'pdf',
        ),
      ],
    ));
    setState(() => _isLoading = true);
    _aiService.generateResponse('quarterly-report.pdf').then((response) {
      if (!mounted) return;
      _controller.addMessage(
        ChatMessage(
          text: "Got it — I can see quarterly-report.pdf. $response",
          user: _aiUser,
          createdAt: DateTime.now(),
        ),
      );
      setState(() => _isLoading = false);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Attachments')),
      body: AiChatWidget(
        maxWidth: 720,
        currentUser: _currentUser,
        aiUser: _aiUser,
        controller: _controller,
        onSendMessage: _onSendMessage,
        loadingConfig: LoadingConfig(isLoading: _isLoading),
        fileUploadOptions: FileUploadOptions(
          enabled: true,
          uploadTooltip: 'Attach a file',
          onFilesSelected: (_) => _simulateAttachFile(),
        ),
        welcomeMessageConfig: const WelcomeMessageConfig(
          title: 'Tap the paperclip below to attach a file',
        ),
      ),
    );
  }
}
