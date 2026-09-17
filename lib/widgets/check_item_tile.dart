import 'package:flutter/material.dart';

import '../models/checklist_item.dart';
import '../theme/app_theme.dart';
import 'circular_check.dart';

class CheckItemTile extends StatelessWidget {
  const CheckItemTile({
    super.key,
    required this.item,
    required this.checked,
    required this.onToggle,
    required this.onOpen,
  });

  final ChecklistItem item;
  final bool checked;
  final VoidCallback onToggle;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final palette = ThemeScope.of(context).palette;
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: onOpen,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            CircularCheck(checked: checked, onTap: onToggle),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item.title,
                style: textTheme.bodyLarge?.copyWith(
                  color: checked ? palette.completedText : palette.text,
                ),
              ),
            ),
            Text(
              item.category.label,
              style: textTheme.bodySmall?.copyWith(color: palette.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
