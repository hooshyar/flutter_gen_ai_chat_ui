// The single source of truth for every demo screen: its route, home-screen
// copy, group and GitHub source link. `HomeScreen` and `DemoScaffold` both
// read this list so the two stay in sync.

/// One entry in the demo index.
class DemoEntry {
  const DemoEntry({
    required this.route,
    required this.title,
    required this.description,
    required this.group,
    required this.sourceFile,
  });

  /// Named route, registered in `main.dart`.
  final String route;

  /// Row title on the home screen and in the demo scaffold's sidebar.
  final String title;

  /// One-line row description on the home screen.
  final String description;

  /// One of [demoGroupOrder].
  final String group;

  /// File name (no extension) under `example/lib/examples/`, used to build
  /// [sourceUrl].
  final String sourceFile;

  /// GitHub link to this demo's source, opened by the scaffold's "Source"
  /// button.
  Uri get sourceUrl => Uri.parse(
        'https://github.com/hooshyar/flutter_gen_ai_chat_ui/blob/main/'
        'example/lib/examples/$sourceFile.dart',
      );
}

/// Display order for the groups in [demoCatalog].
const List<String> demoGroupOrder = ['Core', 'Agents', 'Input', 'Global'];

/// Every demo, grouped per DESIGN.md §9.
const List<DemoEntry> demoCatalog = [
  DemoEntry(
    route: '/basic',
    title: 'Basic',
    description: 'Zero styling, only the required arguments.',
    group: 'Core',
    sourceFile: 'basic_chat',
  ),
  DemoEntry(
    route: '/streaming',
    title: 'Streaming',
    description: 'Word-by-word reveal with syntax-highlighted code.',
    group: 'Core',
    sourceFile: 'streaming_chat',
  ),
  DemoEntry(
    route: '/themed',
    title: 'Themes',
    description: 'Switch between brand presets and light or dark.',
    group: 'Core',
    sourceFile: 'themed_chat',
  ),
  DemoEntry(
    route: '/actions',
    title: 'Actions',
    description: 'Tool calls rendered as code, then a result card.',
    group: 'Agents',
    sourceFile: 'actions_chat',
  ),
  DemoEntry(
    route: '/rich-widgets',
    title: 'Rich results',
    description: 'Weather, product and chart cards inline.',
    group: 'Agents',
    sourceFile: 'rich_widgets_chat',
  ),
  DemoEntry(
    route: '/attachments',
    title: 'Attachments',
    description: 'File upload button and attached-file rendering.',
    group: 'Input',
    sourceFile: 'attachments_chat',
  ),
  DemoEntry(
    route: '/voice',
    title: 'Voice',
    description: 'Mic and send toggle with the voice send button.',
    group: 'Input',
    sourceFile: 'voice_chat',
  ),
  DemoEntry(
    route: '/rtl',
    title: 'RTL',
    description: 'Arabic and Sorani Kurdish, mirrored layout.',
    group: 'Global',
    sourceFile: 'rtl_chat',
  ),
];
