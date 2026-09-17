import 'package:flutter/material.dart';

import '../models/checklist_item.dart';
import '../models/date_key.dart';
import '../state/app_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/check_item_tile.dart';
import '../widgets/filter_tabs.dart';
import '../widgets/week_strip.dart';
import 'item_editor_sheet.dart';

class TodayScreen extends StatelessWidget {
  const TodayScreen({
    super.key,
    required this.controller,
    required this.onOpenMood,
  });

  final AppController controller;
  final VoidCallback onOpenMood;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final palette = ThemeScope.of(context).palette;
        final textTheme = Theme.of(context).textTheme;
        final counts = controller.countForDate(controller.selectedDate);
        final items = controller.visibleItems;
        final isToday =
            DateKey.from(controller.selectedDate) ==
            DateKey.from(DateKey.today());

        return ListView(
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 28),
          children: [
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _pickDate(context),
                    child: Text(
                      DateKey.longLabel(controller.selectedDate),
                      style: textTheme.bodyMedium?.copyWith(
                        color: palette.textMuted,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: '항목 추가',
                  onPressed: () => openItemEditor(context),
                  icon: Icon(Icons.add, color: palette.text),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              isToday ? '오늘의 여백' : '그날의 여백',
              style: textTheme.displaySmall,
            ),
            const SizedBox(height: 8),
            Text(
              isToday ? '오늘도, 충분히 잘하고 있어요.' : '그날의 속도를 있는 그대로 남겨 두세요.',
              style: textTheme.bodyMedium?.copyWith(color: palette.textMuted),
            ),
            const SizedBox(height: 22),
            WeekStrip(
              selected: controller.selectedDate,
              onSelected: controller.selectDate,
            ),
            const SizedBox(height: 22),
            FilterTabs(
              selected: controller.filter,
              onSelected: controller.setFilter,
            ),
            const SizedBox(height: 26),
            Row(
              children: [
                Expanded(
                  child: Text('나를 위한 작은 약속', style: textTheme.titleMedium),
                ),
                Text(
                  '${counts.completed} / ${counts.total}',
                  key: const Key('today-count'),
                  style: textTheme.bodyMedium?.copyWith(
                    color: palette.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: Text(
                  '아직 약속이 없어요. 아래 버튼으로 오늘의 할 일을 남겨 보세요.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: palette.textMuted,
                  ),
                ),
              )
            else
              for (final item in items) ...[
                CheckItemTile(
                  item: item,
                  checked: controller.isCompleted(item),
                  onToggle: () => controller.toggleComplete(item.id),
                  onOpen: () => openItemEditor(context, item: item),
                ),
                Divider(height: 1, color: palette.divider),
              ],
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => openItemEditor(context),
                icon: Icon(Icons.add, size: 18, color: palette.accent),
                label: Text(
                  '할 일 추가',
                  style: textTheme.labelLarge?.copyWith(color: palette.accent),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Material(
              color: palette.highlight,
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                onTap: onOpenMood,
                borderRadius: BorderRadius.circular(18),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 14, 18),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '오늘 마음은 어때요?',
                              style: textTheme.titleSmall,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '지금 이 순간의 나를 기록해보세요.',
                              style: textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, color: palette.textMuted),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: controller.selectedDate,
      firstDate: DateTime(controller.selectedDate.year - 5),
      lastDate: DateTime(controller.selectedDate.year + 5),
      locale: const Locale('ko', 'KR'),
    );
    if (picked != null) {
      controller.selectDate(picked);
    }
  }

  Future<void> openItemEditor(
    BuildContext context, {
    ChecklistItem? item,
  }) {
    return showItemEditor(
      context: context,
      initialDate: controller.selectedDate,
      item: item,
      onSave: ({required title, required category, required date}) async {
        if (item == null) {
          await controller.addItem(title: title, category: category, date: date);
        } else {
          await controller.updateItem(
            id: item.id,
            title: title,
            category: category,
            date: date,
          );
        }
      },
      onDelete: item == null ? null : () => controller.deleteItem(item.id),
    );
  }
}
