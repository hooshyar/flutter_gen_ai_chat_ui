import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'example_configs.dart';

class ShowcaseSidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final bool isDark;
  final VoidCallback onToggleTheme;

  const ShowcaseSidebar({
    super.key,
    required this.selectedIndex,
    required this.onSelect,
    required this.isDark,
    required this.onToggleTheme,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF161616) : const Color(0xFFFAFAFA);
    final border = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE5E5E5);
    final textColor = isDark ? Colors.white : Colors.black87;
    final mutedColor = isDark ? Colors.white54 : Colors.black45;

    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: bg,
        border: Border(right: BorderSide(color: border, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 4),
            child: Text(
              'Flutter Gen AI Chat UI',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Row(
              children: [
                Text(
                  'v0.9.0',
                  style: TextStyle(fontSize: 12, color: mutedColor),
                ),
                const Spacer(),
                _iconLink(
                  Icons.open_in_new,
                  'https://pub.dev/packages/flutter_gen_ai_chat_ui',
                  mutedColor,
                  'pub.dev',
                ),
                const SizedBox(width: 8),
                _iconLink(
                  Icons.code,
                  'https://github.com/hooshyar/flutter_gen_ai_chat_ui',
                  mutedColor,
                  'GitHub',
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: onToggleTheme,
                  borderRadius: BorderRadius.circular(4),
                  child: Icon(
                    isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                    size: 16,
                    color: mutedColor,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: border),
          const SizedBox(height: 8),
          // Example list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              itemCount: examples.length,
              itemBuilder: (context, index) {
                final example = examples[index];
                final isSelected = index == selectedIndex;
                final selectedBg = isDark
                    ? const Color(0xFF2A2A2A)
                    : const Color(0xFFEEEEFF);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Material(
                    color: isSelected ? selectedBg : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => onSelect(index),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              example.icon,
                              size: 18,
                              color: isSelected
                                  ? (isDark ? Colors.indigoAccent : Colors.indigo)
                                  : mutedColor,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    example.title,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                      color: textColor,
                                    ),
                                  ),
                                  Text(
                                    example.subtitle,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: mutedColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconLink(IconData icon, String url, Color color, String tooltip) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: () => launchUrl(Uri.parse(url)),
        borderRadius: BorderRadius.circular(4),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}

/// Mobile bottom navigation for examples
class ShowcaseBottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const ShowcaseBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: selectedIndex,
      onTap: onSelect,
      type: BottomNavigationBarType.fixed,
      selectedFontSize: 11,
      unselectedFontSize: 11,
      items: examples
          .map((e) => BottomNavigationBarItem(
                icon: Icon(e.icon),
                label: e.title.split(' ').first,
              ))
          .toList(),
    );
  }
}
