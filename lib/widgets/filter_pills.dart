import 'package:flutter/material.dart';

import '../models/item_category.dart';
import '../theme/app_theme.dart';

class FilterPills extends StatelessWidget {
  const FilterPills({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final ItemCategory? selected;
  final ValueChanged<ItemCategory?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _Pill(
            label: '전체',
            selected: selected == null,
            onTap: () => onSelected(null),
          ),
          const SizedBox(width: 8),
          for (final category in ItemCategory.values) ...[
            _Pill(
              label: category.label,
              selected: selected == category,
              onTap: () => onSelected(category),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = ThemeScope.of(context).palette;
    final textTheme = Theme.of(context).textTheme;
    return Material(
      color: selected ? palette.accent : ThemeScope.of(context).cardColor,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Text(
            label,
            style: textTheme.labelLarge?.copyWith(
              color: selected ? palette.onAccent : palette.text,
            ),
          ),
        ),
      ),
    );
  }
}
