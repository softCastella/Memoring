import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import '../models/app_theme_id.dart';
import '../models/appearance_settings.dart';
import '../models/checklist_item.dart';
import '../models/date_key.dart';
import '../models/item_category.dart';
import '../models/mood_entry.dart';
import '../models/routine_completion.dart';
import '../models/widget_snapshot.dart';
import '../preview/sample_data.dart';
import '../data/appearance_repository.dart';
import '../data/background_file_store.dart';
import '../data/local_json_store.dart';
import '../data/mood_repository.dart';
import '../data/task_repository.dart';
import '../data/widget_snapshot_writer.dart';

class AppController extends ChangeNotifier {
  AppController({
    required this.taskRepository,
    required this.moodRepository,
    required this.appearanceRepository,
    required this.backgroundFileStore,
    required this.widgetSnapshotWriter,
  });

  static Future<AppController> bootstrap(Directory root) async {
    final store = LocalJsonStore(root);
    final controller = AppController(
      taskRepository: TaskRepository(store),
      moodRepository: MoodRepository(store),
      appearanceRepository: AppearanceRepository(store),
      backgroundFileStore: BackgroundFileStore(root),
      widgetSnapshotWriter: WidgetSnapshotWriter(store),
    );
    await controller.load();
    return controller;
  }

  final TaskRepository taskRepository;
  final MoodRepository moodRepository;
  final AppearanceRepository appearanceRepository;
  final BackgroundFileStore backgroundFileStore;
  final WidgetSnapshotWriter widgetSnapshotWriter;

  bool ready = false;
  String? loadError;
  DateTime selectedDate = DateKey.today();
  ItemCategory? filter;
  List<ChecklistItem> items = [];
  Set<RoutineCompletion> completions = {};
  Map<String, MoodEntry> moods = {};
  AppearanceSettings appearance = AppearanceSettings.defaults();

  String get selectedDateKey => DateKey.from(selectedDate);

  Future<void> load() async {
    try {
      items = await taskRepository.loadItems();
      completions = await taskRepository.loadCompletions();
      moods = await moodRepository.loadAll();
      appearance = await appearanceRepository.load();
      if (AppConfig.useSampleData) {
        await _seedPreviewIfEmpty();
      }
      ready = true;
      loadError = null;
      await _writeWidgetSnapshot();
      notifyListeners();
    } catch (error) {
      loadError = error.toString();
      ready = false;
      notifyListeners();
    }
  }

  void selectDate(DateTime date) {
    selectedDate = DateKey.only(date);
    notifyListeners();
  }

  void setFilter(ItemCategory? category) {
    filter = category;
    notifyListeners();
  }

  List<ChecklistItem> itemsForDate(DateTime date, {ItemCategory? category}) {
    final key = DateKey.from(date);
    final visible = items.where((item) {
      if (item.isRoutine) {
        return item.date.compareTo(key) <= 0;
      }
      return item.date == key;
    }).where((item) {
      return category == null || item.category == category;
    }).toList();

    visible.sort((a, b) {
      final aDone = isCompleted(a, key);
      final bDone = isCompleted(b, key);
      if (aDone != bDone) {
        return aDone ? 1 : -1;
      }
      return a.createdAt.compareTo(b.createdAt);
    });
    return visible;
  }

  List<ChecklistItem> get visibleItems =>
      itemsForDate(selectedDate, category: filter);

  bool isCompleted(ChecklistItem item, [String? date]) {
    final key = date ?? selectedDateKey;
    if (item.isRoutine) {
      return completions.contains(RoutineCompletion(itemId: item.id, date: key));
    }
    return item.completed;
  }

  ({int completed, int total}) countForDate(DateTime date) {
    final list = itemsForDate(date);
    final key = DateKey.from(date);
    final completed = list.where((item) => isCompleted(item, key)).length;
    return (completed: completed, total: list.length);
  }

  Future<ChecklistItem> addItem({
    required String title,
    required ItemCategory category,
    required DateTime date,
  }) async {
    final item = ChecklistItem(
      id: _newId(),
      title: title.trim(),
      category: category,
      date: DateKey.from(date),
      completed: false,
      createdAt: DateTime.now(),
    );
    items = [...items, item];
    await _persistTasks();
    notifyListeners();
    return item;
  }

  Future<void> updateItem({
    required String id,
    required String title,
    required ItemCategory category,
    required DateTime date,
  }) async {
    items = [
      for (final item in items)
        if (item.id == id)
          item.copyWith(
            title: title.trim(),
            category: category,
            date: DateKey.from(date),
            completed: category == ItemCategory.routine ? false : item.completed,
          )
        else
          item,
    ];
    await _persistTasks();
    notifyListeners();
  }

  Future<void> deleteItem(String id) async {
    items = items.where((item) => item.id != id).toList();
    completions = completions.where((item) => item.itemId != id).toSet();
    await _persistTasks();
    notifyListeners();
  }

  Future<void> toggleComplete(String id) async {
    final item = items.firstWhere((entry) => entry.id == id);
    if (item.isRoutine) {
      final mark = RoutineCompletion(itemId: id, date: selectedDateKey);
      if (completions.contains(mark)) {
        completions = completions.where((entry) => entry != mark).toSet();
      } else {
        completions = {...completions, mark};
      }
    } else {
      items = [
        for (final entry in items)
          if (entry.id == id) entry.copyWith(completed: !entry.completed) else entry,
      ];
    }
    await _persistTasks();
    notifyListeners();
  }

  MoodEntry moodFor(DateTime date) {
    return moods[DateKey.from(date)] ??
        MoodEntry(date: DateKey.from(date), mood: 0, note: '');
  }

  Future<void> saveMood({required int mood, required String note}) async {
    final key = selectedDateKey;
    if (mood == 0 && note.trim().isEmpty) {
      moods = Map.of(moods)..remove(key);
    } else {
      moods = Map.of(moods)
        ..[key] = MoodEntry(date: key, mood: mood, note: note.trim());
    }
    await moodRepository.saveAll(moods);
    notifyListeners();
  }

  Future<void> setTheme(AppThemeId themeId) async {
    appearance = appearance.copyWith(themeId: themeId);
    await appearanceRepository.save(appearance);
    await _writeWidgetSnapshot();
    notifyListeners();
  }

  Future<String> persistPickedBackground(File source) {
    return backgroundFileStore.persistPersonal(source, fileName: 'draft');
  }

  Future<void> applyAppearance(AppearanceSettings next) async {
    var settings = next;
    if (next.hasPersonalBackground) {
      final source = File(next.personalBackgroundPath!);
      if (await source.exists()) {
        final path = await backgroundFileStore.persistPersonal(
          source,
          fileName: 'current',
        );
        settings = next.copyWith(personalBackgroundPath: path);
      }
    } else {
      await backgroundFileStore.clearPersonal();
      settings = next.copyWith(clearPersonalBackground: true);
    }
    appearance = settings;
    await appearanceRepository.save(appearance);
    await _writeWidgetSnapshot();
    notifyListeners();
  }

  Future<void> restoreDefaultAppearance() async {
    await backgroundFileStore.clearPersonal();
    appearance = AppearanceSettings.defaults();
    await appearanceRepository.save(appearance);
    await _writeWidgetSnapshot();
    notifyListeners();
  }

  Future<void> _persistTasks() async {
    await taskRepository.saveItems(items);
    await taskRepository.saveCompletions(completions);
    await _writeWidgetSnapshot();
  }

  Future<void> _writeWidgetSnapshot() async {
    final today = DateKey.today();
    final list = itemsForDate(today);
    final counts = countForDate(today);
    final snapshot = WidgetSnapshot(
      date: DateKey.from(today),
      completed: counts.completed,
      total: counts.total,
      items: list
          .take(6)
          .map(
            (item) => WidgetSnapshotItem.fromChecklist(
              item: item,
              done: isCompleted(item, DateKey.from(today)),
            ),
          )
          .toList(),
      appearance: appearance,
    );
    await widgetSnapshotWriter.write(snapshot);
  }

  Future<void> _seedPreviewIfEmpty() async {
    if (items.isNotEmpty || moods.isNotEmpty) {
      return;
    }
    final today = DateKey.today();
    items = [
      for (var i = 0; i < PreviewSample.itemTitles.length; i++)
        ChecklistItem(
          id: 'sample-$i',
          title: PreviewSample.itemTitles[i],
          category: i == 2 ? ItemCategory.routine : ItemCategory.todo,
          date: DateKey.from(today),
          completed: false,
          createdAt: DateTime.now(),
        ),
    ];
    await _persistTasks();
  }

  String _newId() {
    final random = Random();
    return '${DateTime.now().microsecondsSinceEpoch}-${random.nextInt(1 << 32)}';
  }
}
