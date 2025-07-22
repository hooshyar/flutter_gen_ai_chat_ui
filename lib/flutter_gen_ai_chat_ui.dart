/// A Flutter package that provides a customizable chat UI for AI applications,
/// featuring streaming responses, code highlighting, and markdown support.
library flutter_gen_ai_chat_ui;

// Controllers
export 'src/controllers/chat_messages_controller.dart';

// Configuration
export 'src/models/ai_chat_config.dart';

// Core models
export 'src/models/chat/models.dart';
export 'src/models/example_question.dart';
export 'src/models/example_question_config.dart' hide ExampleQuestion;
export 'src/models/file_upload_options.dart';
export 'src/models/input_options.dart';
export 'src/models/models.dart';
export 'src/models/welcome_message_config.dart';

// Theme
export 'src/theme/custom_theme_extension.dart';

// Utils
export 'src/utils/color_extensions.dart';
export 'src/utils/glassmorphic_container.dart';

// Widgets
export 'src/widgets/ai_chat_widget.dart';
export 'src/widgets/chat_input.dart';
export 'src/widgets/custom_chat_widget.dart';
export 'src/widgets/glassmorphic_container.dart';
export 'src/widgets/loading_widget.dart';
export 'src/widgets/message_attachment.dart';
