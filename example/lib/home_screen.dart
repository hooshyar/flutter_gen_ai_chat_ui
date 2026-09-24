// The example app's landing screen: a split hero (pitch + a live chat
// panel) above a grouped demo index. DESIGN.md §9 "Home screen".
import 'package:flutter/material.dart';
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import 'shell/app_theme.dart';
import 'shell/demo_catalog.dart';
import 'shell/live_preview.dart';

/// Width at which the hero and demo index switch from stacked to a split,
/// 12-column layout.
const double _heroBreakpoint = 1024;

/// Width at which the demo index lays out two groups per row.
const double _groupsTwoColumnBreakpoint = 840;

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onToggleTheme});

  final VoidCallback onToggleTheme;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.canvas,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= _heroBreakpoint;

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                isWide ? 32 : 20,
                24,
                isWide ? 32 : 20,
                48,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: _ThemeToggle(
                          isDark: isDark,
                          onToggle: onToggleTheme,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (isWide)
                        _WideHero(colors: colors)
                      else
                        _StackedHero(colors: colors),
                      const SizedBox(height: 48),
                      _DemoIndex(
                        colors: colors,
                        twoColumns:
                            constraints.maxWidth >= _groupsTwoColumnBreakpoint,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ThemeToggle extends StatelessWidget {
  const _ThemeToggle({required this.isDark, required this.onToggle});

  final bool isDark;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return IconButton(
      tooltip: isDark ? 'Switch to light theme' : 'Switch to dark theme',
      icon: Icon(
        isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
        color: colors.textSecondary,
      ),
      onPressed: onToggle,
    );
  }
}

// -- Hero --

class _WideHero extends StatelessWidget {
  const _WideHero({required this.colors});

  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 5,
            child: Align(
              alignment: Alignment.center,
              child: _HeroPitch(colors: colors, headlineSize: 40),
            ),
          ),
          const SizedBox(width: 32),
          const Expanded(
            flex: 7,
            child: LivePreview(height: 560),
          ),
        ],
      ),
    );
  }
}

class _StackedHero extends StatelessWidget {
  const _StackedHero({required this.colors});

  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _HeroPitch(colors: colors, headlineSize: 32),
        const SizedBox(height: 24),
        const LivePreview(height: 440),
      ],
    );
  }
}

class _HeroPitch extends StatelessWidget {
  const _HeroPitch({required this.colors, required this.headlineSize});

  final AppColors colors;
  final double headlineSize;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'flutter_gen_ai_chat_ui',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 12,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Chat UI for Flutter AI apps',
          style: TextStyle(
            fontSize: headlineSize,
            height: headlineSize == 40 ? 44 / 40 : 36 / 32,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.8,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Streaming markdown, syntax-highlighted code, RTL and tool '
          'results. One widget, zero config, fully themeable.',
          style: TextStyle(
            fontSize: 16,
            height: 1.56,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: 24),
        const ClipRRect(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          child: CodeBlockView(
            code: 'flutter pub add flutter_gen_ai_chat_ui',
            language: 'bash',
          ),
        ),
        const SizedBox(height: 16),
        InkWell(
          onTap: () => launchUrl(
            Uri.parse(
              'https://github.com/hooshyar/flutter_gen_ai_chat_ui',
            ),
            mode: LaunchMode.externalApplication,
          ),
          child: Text(
            'GitHub',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: colors.accent,
              decoration: TextDecoration.underline,
              decorationColor: colors.accent,
            ),
          ),
        ),
      ],
    );
  }
}

// -- Demo index --

class _DemoIndex extends StatelessWidget {
  const _DemoIndex({required this.colors, required this.twoColumns});

  final AppColors colors;
  final bool twoColumns;

  @override
  Widget build(BuildContext context) {
    final groups = demoGroupOrder
        .map((group) => DemoGroupSection(
              group: group,
              entries: demoCatalog.where((e) => e.group == group).toList(),
              colors: colors,
            ))
        .toList();

    if (!twoColumns) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final group in groups) ...[
            group,
            const SizedBox(height: 32),
          ],
        ],
      );
    }

    return Wrap(
      spacing: 48,
      runSpacing: 32,
      children: [
        for (final group in groups)
          SizedBox(
            width: (1200 - 48) / 2,
            child: group,
          ),
      ],
    );
  }
}

/// One group of demo rows with its section title. Public (rather than
/// private) so tests can count instances directly.
class DemoGroupSection extends StatelessWidget {
  const DemoGroupSection({
    super.key,
    required this.group,
    required this.entries,
    required this.colors,
  });

  final String group;
  final List<DemoEntry> entries;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          group,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: colors.textSecondary,
          ),
        ),
        for (final entry in entries) DemoIndexRow(entry: entry, colors: colors),
      ],
    );
  }
}

/// One row of the demo index. Public so tests can count instances directly.
class DemoIndexRow extends StatefulWidget {
  const DemoIndexRow({super.key, required this.entry, required this.colors});

  final DemoEntry entry;
  final AppColors colors;

  @override
  State<DemoIndexRow> createState() => _DemoIndexRowState();
}

class _DemoIndexRowState extends State<DemoIndexRow> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: InkWell(
        onTap: () => Navigator.of(context).pushNamed(widget.entry.route),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: colors.border)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.entry.title,
                      style: TextStyle(
                        fontSize: 14,
                        height: 20 / 14,
                        fontWeight: FontWeight.w500,
                        color: colors.textPrimary,
                      ),
                    ),
                    Text(
                      widget.entry.description,
                      style: TextStyle(
                        fontSize: 12,
                        height: 16 / 12,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedOpacity(
                opacity: _hovering ? 1 : 0,
                duration: const Duration(milliseconds: 150),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  size: 16,
                  color: colors.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
