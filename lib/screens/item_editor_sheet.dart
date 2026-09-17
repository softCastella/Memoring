import 'package:flutter/material.dart';

import '../models/checklist_item.dart';
import '../models/date_key.dart';
import '../models/item_category.dart';
import '../theme/app_theme.dart';

Future<void> showItemEditor({
  required BuildContext context,
  required DateTime initialDate,
  required Future<void> Function({
    required String title,
    required ItemCategory category,
    required DateTime date,
  })
  onSave,
  Future<void> Function()? onDelete,
  ChecklistItem? item,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) {
      return ItemEditorSheet(
        initialDate: initialDate,
        item: item,
        onSave: onSave,
        onDelete: onDelete,
      );
    },
  );
}

class ItemEditorSheet extends StatefulWidget {
  const ItemEditorSheet({
    super.key,
    required this.initialDate,
    required this.onSave,
    this.onDelete,
    this.item,
  });

  final DateTime initialDate;
  final ChecklistItem? item;
  final Future<void> Function({
    required String title,
    required ItemCategory category,
    required DateTime date,
  })
  onSave;
  final Future<void> Function()? onDelete;

  @override
  State<ItemEditorSheet> createState() => _ItemEditorSheetState();
}

class _ItemEditorSheetState extends State<ItemEditorSheet> {
  late final TextEditingController _title;
  late ItemCategory _category;
  late DateTime _date;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.item?.title ?? '');
    _category = widget.item?.category ?? ItemCategory.todo;
    _date = widget.item == null
        ? DateKey.only(widget.initialDate)
        : DateKey.parse(widget.item!.date);
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = ThemeScope.of(context).palette;
    final textTheme = Theme.of(context).textTheme;
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    final editing = widget.item != null;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + inset),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: palette.divider,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(editing ? '항목 수정' : '항목 추가', style: textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(
              controller: _title,
              autofocus: true,
              textInputAction: TextInputAction.done,
              style: textTheme.bodyLarge,
              decoration: const InputDecoration(hintText: '무엇을 기록할까요?'),
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 16),
            Text('분류', style: textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final category in ItemCategory.values)
                  ChoiceChip(
                    label: Text(category.label),
                    selected: _category == category,
                    showCheckmark: false,
                    onSelected: (_) => setState(() => _category = category),
                    selectedColor: palette.accentSoft,
                    labelStyle: textTheme.labelLarge?.copyWith(
                      color: palette.text,
                    ),
                    backgroundColor: palette.background,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                      side: BorderSide(color: palette.divider),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              _category == ItemCategory.routine ? '시작일' : '날짜',
              style: textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: _pickDate,
                child: Text(
                  '${_date.year}.${_date.month.toString().padLeft(2, '0')}.${_date.day.toString().padLeft(2, '0')}',
                  style: textTheme.bodyLarge?.copyWith(color: palette.accent),
                ),
              ),
            ),
            if (_category == ItemCategory.routine)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '매일 반복되며, 완료 여부는 날짜마다 따로 저장됩니다.',
                  style: textTheme.bodySmall,
                ),
              ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: palette.accent,
                foregroundColor: palette.onAccent,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(editing ? '저장' : '추가'),
            ),
            if (editing && widget.onDelete != null)
              TextButton(
                onPressed: _saving ? null : _delete,
                child: Text(
                  '삭제',
                  style: textTheme.labelLarge?.copyWith(
                    color: const Color(0xFFB46868),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(_date.year - 5),
      lastDate: DateTime(_date.year + 5),
      locale: const Locale('ko', 'KR'),
    );
    if (picked != null) {
      setState(() => _date = DateKey.only(picked));
    }
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    if (title.isEmpty) {
      return;
    }
    setState(() => _saving = true);
    await widget.onSave(title: title, category: _category, date: _date);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _delete() async {
    setState(() => _saving = true);
    await widget.onDelete?.call();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}
