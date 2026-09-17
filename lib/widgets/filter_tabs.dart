import 'package:flutter/material.dart';

import '../models/item_category.dart';
import '../theme/app_theme.dart';

class FilterTabs extends StatelessWidget {
  const FilterTabs({
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
          _Tab(
            label: '전체',
            selected: selected == null,
            onTap: () => onSelected(null),
          ),
          const SizedBox(width: 22),
          _Tab(
            label: ItemCategory.todo.label,
            selected: selected == ItemCategory.todo,
            onTap: () => onSelected(ItemCategory.todo),
          ),
          const SizedBox(width: 22),
          _Tab(
            label: ItemCategory.study.label,
            selected: selected == ItemCategory.study,
            onTap: () => onSelected(ItemCategory.study),
          ),
          const SizedBox(width: 22),
          _Tab(
            label: ItemCategory.routine.label,
            selected: selected == ItemCategory.routine,
            onTap: () => onSelected(ItemCategory.routine),
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
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
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 6, top: 4),
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected ? palette.accent : Colors.transparent,
                width: 1.6,
              ),
            ),
          ),
          child: Text(
            label,
            style: textTheme.labelLarge?.copyWith(
              color: selected ? palette.accent : palette.textMuted,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}
