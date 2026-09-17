import 'package:flutter/material.dart';

import '../models/checklist_item.dart';
import '../models/date_key.dart';
import '../models/topic_page.dart';
import '../state/app_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/check_item_tile.dart';
import '../widgets/filter_tabs.dart';
import '../widgets/page_strip.dart';
import '../widgets/week_strip.dart';
import 'item_editor_sheet.dart';

class TodayScreen extends StatefulWidget {
  const TodayScreen({
    super.key,
    required this.controller,
    required this.onOpenMood,
  });

  final AppController controller;
  final VoidCallback onOpenMood;

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  AppController get controller => widget.controller;
  VoidCallback get onOpenMood => widget.onOpenMood;

  @override
  void initState() {
    super.initState();
    controller.addListener(_onChange);
  }

  @override
  void didUpdateWidget(covariant TodayScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onChange);
      widget.controller.addListener(_onChange);
    }
  }

  @override
  void dispose() {
    controller.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = ThemeScope.of(context).palette;
    final textTheme = Theme.of(context).textTheme;
    final counts = controller.countForDate(
      controller.selectedDate,
      pageId: controller.selectedPageId,
    );
    final items = controller.visibleItems;
    final page = controller.selectedPage;
    final isToday =
        DateKey.from(controller.selectedDate) ==
        DateKey.from(DateKey.today());
    final headline = page.isInbox
        ? (isToday ? '오늘의 여백' : '그날의 여백')
        : page.name;
    final subtitle = page.isInbox
        ? (isToday ? '오늘도, 충분히 잘하고 있어요.' : '그날의 속도를 있는 그대로 남겨 두세요.')
        : '이 주제의 작은 약속들';

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 0),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                InkWell(
                  onTap: () => _pickDate(context),
                  child: Text(
                    DateKey.longLabel(controller.selectedDate),
                    style: textTheme.bodySmall?.copyWith(
                      color: palette.textMuted,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  headline,
                  style: textTheme.displaySmall,
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: textTheme.bodyMedium?.copyWith(
                    color: palette.textMuted,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  '체크리스트 페이지',
                  style: textTheme.labelMedium,
                ),
                const SizedBox(height: 8),
                PageStrip(
                  pages: controller.pages,
                  selectedId: controller.selectedPageId,
                  onSelected: controller.selectPage,
                  onAddPage: () => _createPage(context),
                  onAddItem: () => openItemEditor(context),
                  onEdit: (topic) => _editPage(context, topic),
                ),
                const SizedBox(height: 22),
                WeekStrip(
                  selected: controller.selectedDate,
                  onSelected: controller.selectDate,
                ),
                const SizedBox(height: 18),
                FilterTabs(
                  selected: controller.filter,
                  onSelected: controller.setFilter,
                ),
                const SizedBox(height: 26),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '나를 위한 작은 약속',
                        style: textTheme.titleMedium,
                      ),
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
              ],
            ),
          ),
        ),
        if (items.isEmpty)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            sliver: SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: Text(
                  page.isInbox
                      ? '아직 약속이 없어요. 아래 버튼으로 오늘의 할 일을 남겨 보세요.'
                      : '아직 약속이 없어요. 아래 버튼으로 이 주제의 할 일을 남겨 보세요.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: palette.textMuted,
                  ),
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            sliver: SliverReorderableList(
              itemCount: items.length,
              onReorder: controller.reorderVisible,
              proxyDecorator: (child, index, animation) {
                return AnimatedBuilder(
                  animation: animation,
                  builder: (context, _) {
                    return Material(
                      elevation: 3 * animation.value,
                      color: palette.surface,
                      shadowColor: palette.text.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      child: child,
                    );
                  },
                );
              },
              itemBuilder: (context, index) {
                final item = items[index];
                return CheckItemTile(
                  key: ValueKey(item.id),
                  item: item,
                  checked: controller.isCompleted(item),
                  onToggle: () => controller.toggleComplete(item.id),
                  onOpen: () => openItemEditor(context, item: item),
                  reorderIndex: index,
                );
              },
            ),
          ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 28),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => openItemEditor(context),
                    icon: Icon(Icons.add, size: 18, color: palette.accent),
                    label: Text(
                      '할 일 추가',
                      style: textTheme.labelLarge?.copyWith(
                        color: palette.accent,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 56),
                Material(
                  color: palette.highlight,
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    onTap: onOpenMood,
                    borderRadius: BorderRadius.circular(20),
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
            ),
          ),
        ),
      ],
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

  Future<void> _createPage(BuildContext context) async {
    final name = await _askPageName(context, title: '주제 페이지');
    if (name == null || name.isEmpty) {
      return;
    }
    await controller.createPage(name);
  }

  Future<void> _editPage(BuildContext context, TopicPage page) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('이름 바꾸기'),
                onTap: () => Navigator.pop(context, 'rename'),
              ),
              ListTile(
                title: Text(
                  '페이지 삭제',
                  style: TextStyle(color: const Color(0xFFB46868)),
                ),
                onTap: () => Navigator.pop(context, 'delete'),
              ),
            ],
          ),
        );
      },
    );
    if (!context.mounted || action == null) {
      return;
    }
    if (action == 'rename') {
      final name = await _askPageName(
        context,
        title: '이름 바꾸기',
        initial: page.name,
      );
      if (name == null || name.isEmpty) {
        return;
      }
      await controller.renamePage(page.id, name);
      return;
    }
    if (action == 'delete') {
      await controller.deletePage(page.id);
    }
  }

  Future<String?> _askPageName(
    BuildContext context, {
    required String title,
    String initial = '',
  }) {
    final palette = ThemeScope.of(context).palette;
    final editor = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: editor,
            autofocus: true,
            decoration: const InputDecoration(hintText: '공부, 살림, 업무...'),
            onSubmitted: (value) => Navigator.pop(context, value.trim()),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('취소', style: TextStyle(color: palette.textMuted)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, editor.text.trim()),
              child: Text('저장', style: TextStyle(color: palette.accent)),
            ),
          ],
        );
      },
    ).whenComplete(editor.dispose);
  }

  Future<void> openItemEditor(
    BuildContext context, {
    ChecklistItem? item,
  }) {
    return showItemEditor(
      context: context,
      initialDate: controller.selectedDate,
      item: item,
      onSave: ({
        required title,
        required category,
        required date,
        required repeatsDaily,
      }) async {
        if (item == null) {
          await controller.addItem(
            title: title,
            category: category,
            date: date,
            repeatsDaily: repeatsDaily,
          );
        } else {
          await controller.updateItem(
            id: item.id,
            title: title,
            category: category,
            date: date,
            repeatsDaily: repeatsDaily,
          );
        }
      },
      onDelete: item == null ? null : () => controller.deleteItem(item.id),
    );
  }
}
