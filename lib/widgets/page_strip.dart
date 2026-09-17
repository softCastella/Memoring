import 'package:flutter/material.dart';

import '../models/topic_page.dart';
import '../theme/app_theme.dart';

class PageStrip extends StatelessWidget {
  const PageStrip({
    super.key,
    required this.pages,
    required this.selectedId,
    required this.onSelected,
    required this.onAddPage,
    required this.onAddItem,
    required this.onEdit,
  });

  final List<TopicPage> pages;
  final String selectedId;
  final ValueChanged<String> onSelected;
  final VoidCallback onAddPage;
  final VoidCallback onAddItem;
  final ValueChanged<TopicPage> onEdit;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final page in pages) ...[
            _PageChip(
              label: page.name,
              selected: page.id == selectedId,
              onTap: () => onSelected(page.id),
              onLongPress: page.isInbox ? null : () => onEdit(page),
            ),
            const SizedBox(width: 8),
          ],
          _OvalBadge(label: '+ 페이지', onTap: onAddPage),
          const SizedBox(width: 8),
          _OvalBadge(label: '+ 항목', onTap: onAddItem),
        ],
      ),
    );
  }
}

class _OvalBadge extends StatelessWidget {
  const _OvalBadge({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = ThemeScope.of(context).palette;
    final textTheme = Theme.of(context).textTheme;
    return Material(
      color: palette.accentSoft,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            label,
            style: textTheme.labelLarge?.copyWith(
              color: palette.text,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}

class _PageChip extends StatelessWidget {
  const _PageChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.onLongPress,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final palette = ThemeScope.of(context).palette;
    final textTheme = Theme.of(context).textTheme;
    return Material(
      color: selected ? palette.text : Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            label,
            style: textTheme.labelLarge?.copyWith(
              color: selected ? palette.surface : palette.textMuted,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}
