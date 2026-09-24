// Shared top bar + optional sidebar wrapper for every demo screen.
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'app_theme.dart';
import 'demo_catalog.dart';

/// Wraps a demo's [body] with the shared top bar (back, title, theme toggle,
/// "Source" link) and, at wide widths, a persistent sidebar listing every
/// demo grouped per [demoCatalog]. DESIGN.md §9 "Demo scaffold".
class DemoScaffold extends StatefulWidget {
  const DemoScaffold({
    super.key,
    required this.title,
    required this.route,
    required this.body,
    required this.isDark,
    required this.onToggleTheme,
  });

  /// Top-bar title, `label` 16/600.
  final String title;

  /// This demo's route, used to highlight it in the sidebar and to resolve
  /// its [DemoEntry.sourceUrl].
  final String route;

  final Widget body;
  final bool isDark;
  final VoidCallback onToggleTheme;

  @override
  State<DemoScaffold> createState() => _DemoScaffoldState();
}

class _DemoScaffoldState extends State<DemoScaffold> {
  static const double _sidebarBreakpoint = 1100;
  static const double _sidebarWidth = 240;
  static const double _topBarHeight = 56;

  bool _scrolledUnder = false;

  void _onScrollNotification(ScrollNotification notification) {
    final scrolledUnder = notification.metrics.pixels > 0;
    if (scrolledUnder != _scrolledUnder) {
      setState(() => _scrolledUnder = scrolledUnder);
    }
  }

  Future<void> _openSource() async {
    DemoEntry? entry;
    for (final e in demoCatalog) {
      if (e.route == widget.route) {
        entry = e;
        break;
      }
    }
    if (entry == null) return;
    await launchUrl(entry.sourceUrl, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.canvas,
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(
              height: _topBarHeight,
              title: widget.title,
              isDark: widget.isDark,
              scrolledUnder: _scrolledUnder,
              onBack: () => Navigator.of(context).pop(),
              onToggleTheme: widget.onToggleTheme,
              onOpenSource: _openSource,
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final showSidebar =
                      constraints.maxWidth >= _sidebarBreakpoint;
                  final content = NotificationListener<ScrollNotification>(
                    onNotification: (notification) {
                      _onScrollNotification(notification);
                      return false;
                    },
                    child: widget.body,
                  );

                  if (!showSidebar) return content;

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        width: _sidebarWidth,
                        child: _Sidebar(
                          currentRoute: widget.route,
                          colors: colors,
                        ),
                      ),
                      VerticalDivider(width: 1, color: colors.border),
                      Expanded(child: content),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.height,
    required this.title,
    required this.isDark,
    required this.scrolledUnder,
    required this.onBack,
    required this.onToggleTheme,
    required this.onOpenSource,
  });

  final double height;
  final String title;
  final bool isDark;
  final bool scrolledUnder;
  final VoidCallback onBack;
  final VoidCallback onToggleTheme;
  final Future<void> Function() onOpenSource;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: colors.canvas,
        border: Border(
          bottom: BorderSide(
            color: scrolledUnder ? colors.border : Colors.transparent,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Back',
            icon: Icon(Icons.arrow_back_rounded, color: colors.textPrimary),
            onPressed: onBack,
          ),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
          ),
          IconButton(
            tooltip: isDark ? 'Switch to light theme' : 'Switch to dark theme',
            icon: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              color: colors.textSecondary,
            ),
            onPressed: onToggleTheme,
          ),
          IconButton(
            tooltip: 'View source on GitHub',
            icon: Icon(Icons.code_rounded, color: colors.textSecondary),
            onPressed: onOpenSource,
          ),
        ],
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.currentRoute, required this.colors});

  final String currentRoute;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      children: [
        for (final group in demoGroupOrder) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 12, 8, 4),
            child: Text(
              group,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: colors.textSecondary,
              ),
            ),
          ),
          for (final entry in demoCatalog.where((e) => e.group == group))
            _SidebarItem(
              entry: entry,
              isCurrent: entry.route == currentRoute,
              colors: colors,
            ),
        ],
      ],
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.entry,
    required this.isCurrent,
    required this.colors,
  });

  final DemoEntry entry;
  final bool isCurrent;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isCurrent ? colors.surfaceSunken : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: isCurrent
            ? null
            : () => Navigator.of(context).pushReplacementNamed(entry.route),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Text(
            entry.title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isCurrent ? colors.textPrimary : colors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
