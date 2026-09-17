import 'package:flutter/material.dart';

import '../models/date_key.dart';
import '../models/mood_entry.dart';
import '../state/app_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/mood_selector.dart';

class MoodScreen extends StatefulWidget {
  const MoodScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<MoodScreen> createState() => _MoodScreenState();
}

class _MoodScreenState extends State<MoodScreen> {
  late final TextEditingController _note;
  int _mood = 0;
  String _boundDate = '';

  AppController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _note = TextEditingController();
    controller.addListener(_syncFromController);
    _syncFromController();
  }

  @override
  void dispose() {
    controller.removeListener(_syncFromController);
    _note.dispose();
    super.dispose();
  }

  void _syncFromController() {
    final entry = controller.moodFor(controller.selectedDate);
    if (_boundDate == entry.date) {
      return;
    }
    _boundDate = entry.date;
    _mood = entry.mood;
    if (_note.text != entry.note) {
      _note.text = entry.note;
    }
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final palette = ThemeScope.of(context).palette;
        final textTheme = Theme.of(context).textTheme;
        final past = _recentEntries();
        final inset = MediaQuery.viewInsetsOf(context).bottom;

        return ListView(
          padding: EdgeInsets.fromLTRB(22, 8, 22, 24 + inset),
          children: [
            Center(
              child: Text('마음 기록', style: textTheme.titleMedium),
            ),
            const SizedBox(height: 22),
            Center(
              child: InkWell(
                onTap: () => _pickDate(context),
                child: Text(
                  DateKey.longLabel(controller.selectedDate),
                  style: textTheme.bodySmall,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Center(
              child: Text('지금, 내 마음은', style: textTheme.displaySmall),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                '오늘의 마음을 한 단어로 표현해보세요.',
                style: textTheme.bodyMedium?.copyWith(color: palette.textMuted),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            MoodSelector(
              value: _mood,
              onChanged: (mood) => setState(() => _mood = mood),
            ),
            const SizedBox(height: 28),
            Text('오늘의 한 줄', style: textTheme.titleSmall),
            const SizedBox(height: 8),
            TextField(
              controller: _note,
              minLines: 3,
              maxLines: 6,
              style: textTheme.bodyLarge,
              decoration: InputDecoration(
                hintText: '서두르지 않고,\n내 속도로 하루를 보냈어요.',
                filled: false,
                border: UnderlineInputBorder(
                  borderSide: BorderSide(color: palette.divider),
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: palette.divider),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: palette.accent),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(
                backgroundColor: palette.accent,
                foregroundColor: palette.onAccent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text('기록 저장'),
            ),
            if (past.isNotEmpty) ...[
              const SizedBox(height: 32),
              Text('지난 기록', style: textTheme.titleMedium),
              const SizedBox(height: 12),
              for (final item in past) ...[
                AppCard(
                  onTap: () => controller.selectDate(DateKey.parse(item.date)),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.date, style: textTheme.labelLarge),
                            const SizedBox(height: 4),
                            Text(
                              item.note.isEmpty
                                  ? MoodEntry.labels[item.mood] ?? '기록됨'
                                  : item.note,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.bodyMedium?.copyWith(
                                color: palette.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        MoodEntry.labels[item.mood] ?? '',
                        style: textTheme.labelLarge?.copyWith(
                          color: palette.accent,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ],
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

  Future<void> _save() async {
    await controller.saveMood(mood: _mood, note: _note.text);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('오늘의 마음을 저장했어요.')),
    );
  }

  List<MoodEntry> _recentEntries() {
    final current = DateKey.from(controller.selectedDate);
    final list = controller.moods.values
        .where((entry) => entry.date != current && !entry.isEmpty)
        .toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list.take(12).toList();
  }
}
