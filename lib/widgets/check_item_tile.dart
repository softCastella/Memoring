import 'package:flutter/foundation.dart';
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
    this.reorderIndex,
  });

  final ChecklistItem item;
  final bool checked;
  final VoidCallback onToggle;
  final VoidCallback onOpen;
  final int? reorderIndex;

  @override
  Widget build(BuildContext context) {
    final palette = ThemeScope.of(context).palette;
    final textTheme = Theme.of(context).textTheme;
    final textColor = checked ? palette.completedText : palette.text;

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: palette.divider)),
        ),
        child: Row(
          children: [
            if (reorderIndex != null) _LeadingDragHandle(index: reorderIndex!),
            CircularCheck(checked: checked, onTap: onToggle),
            const SizedBox(width: 12),
            Expanded(
              child: InkWell(
                onTap: onOpen,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Text(
                          item.title,
                          style: textTheme.bodyLarge?.copyWith(color: textColor),
                        ),
                        if (checked)
                          Positioned(
                            left: 0,
                            right: -10,
                            top: 0,
                            bottom: 0,
                            child: IgnorePointer(
                              child: Center(
                                child: Container(
                                  height: 1.2,
                                  color: palette.completedText.withValues(
                                    alpha: 0.7,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (item.repeatsEachDay) ...[
              const SizedBox(width: 8),
              const _DailyBadge(),
            ],
            const SizedBox(width: 8),
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

class _LeadingDragHandle extends StatelessWidget {
  const _LeadingDragHandle({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    final palette = ThemeScope.of(context).palette;
    final handle = Semantics(
      label: '순서 변경',
      button: true,
      child: SizedBox(
        width: 36,
        height: 44,
        child: Icon(
          Icons.drag_indicator,
          size: 22,
          color: palette.textMuted,
        ),
      ),
    );
    final useImmediateDrag =
        kIsWeb ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux;
    if (useImmediateDrag) {
      return MouseRegion(
        cursor: SystemMouseCursors.grab,
        child: ReorderableDragStartListener(index: index, child: handle),
      );
    }
    return ReorderableDelayedDragStartListener(index: index, child: handle);
  }
}

class _DailyBadge extends StatelessWidget {
  const _DailyBadge();

  @override
  Widget build(BuildContext context) {
    final palette = ThemeScope.of(context).palette;
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      label: '매일 다시',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: palette.accentSoft,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_today, size: 12, color: palette.accent),
            const SizedBox(width: 4),
            Text(
              '매일',
              style: textTheme.labelMedium?.copyWith(
                color: palette.accent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
