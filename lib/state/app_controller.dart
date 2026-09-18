import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../catalog/background_pack.dart';
import '../catalog/catalog_client.dart';
import '../catalog/catalog_store.dart';
import '../catalog/entitlement.dart';
import '../config/app_config.dart';
import '../home_widget/home_widget_sync.dart';
import '../models/app_theme_id.dart';
import '../models/appearance_settings.dart';
import '../models/checklist_item.dart';
import '../models/date_key.dart';
import '../models/item_category.dart';
import '../models/memo.dart';
import '../models/mood_entry.dart';
import '../models/routine_completion.dart';
import '../models/topic_page.dart';
import '../models/widget_snapshot.dart';
import '../preview/sample_data.dart';
import '../data/appearance_repository.dart';
import '../data/background_file_store.dart';
import '../data/background_library.dart';
import '../data/local_json_store.dart';
import '../data/memo_repository.dart';
import '../data/mood_repository.dart';
import '../data/task_repository.dart';
import '../data/topic_repository.dart';
import '../data/widget_snapshot_writer.dart';

class AppController extends ChangeNotifier {
  AppController({
    required this.taskRepository,
    required this.moodRepository,
    required this.memoRepository,
    required this.appearanceRepository,
    required this.backgroundFileStore,
    required this.widgetSnapshotWriter,
    required this.topicRepository,
    required this.catalog,
    required this.library,
    this.entitlements = const EntitlementVerifier(),
    HomeWidgetSync? homeWidgetSync,
  }) : homeWidgetSync = homeWidgetSync ?? HomeWidgetSync() {
    catalog.addListener(notifyListeners);
  }

  static Future<AppController> bootstrap({
    String namespace = 'app',
    bool syncCatalog = false,
  }) async {
    final store = LocalJsonStore(namespace: namespace);
    await store.ensureReady();
    final files = BackgroundFileStore(namespace: namespace);
    await files.load();
    final catalog = CatalogStore(
      client: syncCatalog ? CatalogClient() : null,
    );
    await catalog.load();
    final library = BackgroundLibrary(store);
    await library.load();
    final controller = AppController(
      taskRepository: TaskRepository(store),
      moodRepository: MoodRepository(store),
      memoRepository: MemoRepository(store),
      appearanceRepository: AppearanceRepository(store, files: files),
      backgroundFileStore: files,
      widgetSnapshotWriter: WidgetSnapshotWriter(store),
      topicRepository: TopicRepository(store),
      catalog: catalog,
      library: library,
    );
    await controller.load();
    return controller;
  }

  final TaskRepository taskRepository;
  final MoodRepository moodRepository;
  final MemoRepository memoRepository;
  final AppearanceRepository appearanceRepository;
  final BackgroundFileStore backgroundFileStore;
  final WidgetSnapshotWriter widgetSnapshotWriter;
  final TopicRepository topicRepository;
  final CatalogStore catalog;
  final BackgroundLibrary library;
  final EntitlementVerifier entitlements;
  final HomeWidgetSync homeWidgetSync;

  bool ready = false;
  String? loadError;
  DateTime selectedDate = DateKey.today();
  ItemCategory? filter;
  List<ChecklistItem> items = [];
  List<TopicPage> pages = [TopicPage.inbox()];
  String selectedPageId = TopicPage.inboxId;
  Set<RoutineCompletion> completions = {};
  Map<String, MoodEntry> moods = {};
  List<Memo> memos = [];
  AppearanceSettings appearance = AppearanceSettings.defaults();

  String get selectedDateKey => DateKey.from(selectedDate);

  TopicPage get selectedPage => pages.firstWhere(
    (page) => page.id == selectedPageId,
    orElse: TopicPage.inbox,
  );

  void selectPage(String pageId) {
    selectedPageId = pageId;
    notifyListeners();
  }

  Future<TopicPage> createPage(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return selectedPage;
    }
    final nextIndex =
        pages.fold<int>(-1, (maxIndex, page) => max(maxIndex, page.sortIndex)) +
        1;
    final page = TopicPage(
      id: _newId(),
      name: trimmed,
      sortIndex: nextIndex,
      createdAt: DateTime.now(),
    );
    pages = [...pages, page];
    selectedPageId = page.id;
    notifyListeners();
    await topicRepository.save(pages);
    return page;
  }

  Future<void> renamePage(String id, String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return;
    }
    pages = [
      for (final page in pages)
        if (page.id == id) page.copyWith(name: trimmed) else page,
    ];
    notifyListeners();
    await topicRepository.save(pages);
  }

  Future<void> deletePage(String id) async {
    if (id == TopicPage.inboxId) {
      return;
    }
    items = [
      for (final item in items)
        if (item.pageId == id)
          item.copyWith(pageId: TopicPage.inboxId)
        else
          item,
    ];
    pages = pages.where((page) => page.id != id).toList();
    if (selectedPageId == id) {
      selectedPageId = TopicPage.inboxId;
    }
    notifyListeners();
    await topicRepository.save(pages);
    await _persistTasks();
  }

  Future<void> load() async {
    try {
      items = await taskRepository.loadItems();
      pages = await topicRepository.load();
      selectedPageId = TopicPage.inboxId;
      completions = await taskRepository.loadCompletions();
      moods = await moodRepository.loadAll();
      memos = await memoRepository.loadAll();
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

  List<ChecklistItem> itemsForDate(
    DateTime date, {
    ItemCategory? category,
    String? pageId,
  }) {
    final key = DateKey.from(date);
    final visible = items.where((item) {
      if (pageId != null && item.pageId != pageId) {
        return false;
      }
      if (item.repeatsEachDay) {
        return item.date.compareTo(key) <= 0;
      }
      return item.date == key;
    }).where((item) {
      if (category == null) {
        return true;
      }
      if (category == ItemCategory.routine) {
        return item.repeatsEachDay;
      }
      return item.category == category;
    }).toList();

    visible.sort((a, b) {
      final byIndex = a.sortIndex.compareTo(b.sortIndex);
      if (byIndex != 0) {
        return byIndex;
      }
      return a.createdAt.compareTo(b.createdAt);
    });
    return visible;
  }

  List<ChecklistItem> get visibleItems => itemsForDate(
        selectedDate,
        category: filter,
        pageId: selectedPageId,
      );

  bool isCompleted(ChecklistItem item, [String? date]) {
    final key = date ?? selectedDateKey;
    if (item.repeatsEachDay) {
      return completions.contains(RoutineCompletion(itemId: item.id, date: key));
    }
    return item.completed;
  }

  ({int completed, int total}) countForDate(
    DateTime date, {
    String? pageId,
  }) {
    final list = itemsForDate(date, pageId: pageId);
    final key = DateKey.from(date);
    final completed = list.where((item) => isCompleted(item, key)).length;
    return (completed: completed, total: list.length);
  }

  Future<ChecklistItem> addItem({
    required String title,
    required ItemCategory category,
    required DateTime date,
    bool repeatsDaily = false,
  }) async {
    final repeating = repeatsDaily || category == ItemCategory.routine;
    final nextIndex =
        items.fold<int>(-1, (maxIndex, item) => max(maxIndex, item.sortIndex)) +
        1;
    final item = ChecklistItem(
      id: _newId(),
      title: title.trim(),
      category: category,
      date: DateKey.from(date),
      completed: false,
      createdAt: DateTime.now(),
      repeatsDaily: repeating,
      sortIndex: nextIndex,
      pageId: selectedPageId,
    );
    items = [...items, item];
    notifyListeners();
    await _persistTasks();
    return item;
  }

  Future<void> updateItem({
    required String id,
    required String title,
    required ItemCategory category,
    required DateTime date,
    bool repeatsDaily = false,
  }) async {
    final repeating = repeatsDaily || category == ItemCategory.routine;
    items = [
      for (final item in items)
        if (item.id == id)
          item.copyWith(
            title: title.trim(),
            category: category,
            date: DateKey.from(date),
            completed: repeating ? false : item.completed,
            repeatsDaily: repeating,
          )
        else
          item,
    ];
    notifyListeners();
    await _persistTasks();
  }

  Future<void> deleteItem(String id) async {
    items = items.where((item) => item.id != id).toList();
    completions = completions.where((item) => item.itemId != id).toSet();
    notifyListeners();
    await _persistTasks();
  }

  Future<void> reorderVisible(int oldIndex, int newIndex) async {
    final visible = visibleItems.toList();
    if (oldIndex < 0 || oldIndex >= visible.length) {
      return;
    }
    var target = newIndex;
    if (oldIndex < target) {
      target -= 1;
    }
    target = target.clamp(0, visible.length - 1);
    final moved = visible.removeAt(oldIndex);
    visible.insert(target, moved);
    final slots = visible.map((item) => item.sortIndex).toList()..sort();
    final nextIndex = {
      for (var i = 0; i < visible.length; i++) visible[i].id: slots[i],
    };
    items = [
      for (final item in items)
        if (nextIndex.containsKey(item.id))
          item.copyWith(sortIndex: nextIndex[item.id])
        else
          item,
    ];
    notifyListeners();
    await _persistTasks();
  }

  Future<void> toggleComplete(String id) async {
    final item = items.firstWhere((entry) => entry.id == id);
    if (item.repeatsEachDay) {
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
    notifyListeners();
    await _persistTasks();
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
    notifyListeners();
    await moodRepository.saveAll(moods);
  }

  Future<void> setTheme(AppThemeId themeId) async {
    appearance = appearance.copyWith(themeId: themeId);
    notifyListeners();
    await appearanceRepository.save(appearance);
    await _writeWidgetSnapshot();
  }

  Future<String> persistPickedBackground(
    List<int> bytes, {
    String ext = '.jpg',
  }) {
    return backgroundFileStore.persistBytes(
      bytes,
      fileName: 'draft',
      ext: ext,
    );
  }

  Future<void> applyAppearance(AppearanceSettings next) async {
    var settings = next;
    final path = next.personalBackgroundPath;
    if (path != null && path.isNotEmpty) {
      final bytes = await backgroundFileStore.read(path);
      if (bytes != null) {
        final saved = await backgroundFileStore.persistBytes(
          bytes,
          fileName: 'current',
          ext: backgroundFileStore.extensionOf(path),
        );
        settings = next.copyWith(personalBackgroundPath: saved);
      }
    } else if (next.catalogBackgroundId == null ||
        next.catalogBackgroundId!.isEmpty) {
      await backgroundFileStore.clearPersonal();
      settings = next.copyWith(
        clearPersonalBackground: true,
        clearCatalogBackground: true,
      );
      await library.clearApplied();
    }
    appearance = settings;
    notifyListeners();
    await appearanceRepository.save(appearance);
    await _writeWidgetSnapshot();
  }

  Future<void> restoreDefaultBackground() async {
    await backgroundFileStore.clearPersonal();
    appearance = appearance.copyWith(
      clearPersonalBackground: true,
      clearCatalogBackground: true,
      scale: 1,
      offsetX: 0,
      offsetY: 0,
      blur: 0,
      cardOpacity: 1,
    );
    notifyListeners();
    await library.clearApplied();
    await appearanceRepository.save(appearance);
    await _writeWidgetSnapshot();
  }

  Future<void> restoreDefaultAppearance() async {
    await restoreDefaultBackground();
    appearance = AppearanceSettings.defaults();
    notifyListeners();
    await appearanceRepository.save(appearance);
    await _writeWidgetSnapshot();
  }

  List<BackgroundPack> get storePacks => catalog.publishedPacks;

  Future<void> refreshCatalog() async {
    await catalog.syncFromServer();
    notifyListeners();
  }

  List<BackgroundPack> storePacksFor(String? category) {
    final packs = storePacks;
    if (category == null) {
      return packs;
    }
    return packs.where((item) => item.category == category).toList();
  }

  Future<bool> canAccessPack(BackgroundPack pack, {BackgroundAsset? asset}) {
    return entitlements.canAccess(pack, asset: asset);
  }

  Future<void> togglePackFavorite(String packId) async {
    await library.toggleFavorite(packId);
    notifyListeners();
  }

  Future<void> downloadPack(BackgroundPack pack) async {
    if (!await entitlements.canAccess(pack)) {
      throw const PaidContentLocked();
    }
    await library.markDownloaded(pack.id);
    notifyListeners();
  }

  Future<void> applyCatalogBackground({
    required BackgroundPack pack,
    required BackgroundAsset asset,
  }) async {
    if (!await entitlements.canAccess(pack, asset: asset)) {
      throw const PaidContentLocked();
    }
    if (asset.base64Data.isEmpty) {
      throw StateError('이미지가 없는 배경입니다.');
    }
    late final Uint8List bytes;
    try {
      bytes = Uint8List.fromList(base64Decode(asset.base64Data));
    } on FormatException {
      throw StateError('이미지를 열 수 없어요.');
    }
    var ext = '.jpg';
    if (asset.mimeType.contains('png')) {
      ext = '.png';
    } else if (asset.mimeType.contains('webp')) {
      ext = '.webp';
    }
    final path = await backgroundFileStore.persistBytes(
      bytes,
      fileName: 'current',
      ext: ext,
    );
    appearance = appearance.copyWith(
      personalBackgroundPath: path,
      catalogBackgroundId: '${pack.id}/${asset.id}',
      cardOpacity: appearance.cardOpacity < 0.88 ? appearance.cardOpacity : 0.88,
    );
    await appearanceRepository.save(appearance);
    await library.markDownloaded(pack.id);
    await library.markApplied(packId: pack.id, assetId: asset.id);
    try {
      await _writeWidgetSnapshot();
    } catch (_) {}
    notifyListeners();
  }

  Future<void> _persistTasks() async {
    await taskRepository.saveItems(items);
    await taskRepository.saveCompletions(completions);
    await _writeWidgetSnapshot();
  }

  Future<void> _writeWidgetSnapshot() async {
    final today = DateKey.today();
    final snapshots = [
      for (final page in pages) _snapshotForPage(page, today),
    ];
    final inbox = snapshots.firstWhere(
      (snapshot) => snapshot.pageId == TopicPage.inboxId,
      orElse: () => snapshots.first,
    );
    await widgetSnapshotWriter.write(inbox);
    await homeWidgetSync.publish(snapshots, memo: widgetMemo);
  }

  List<Memo> get sortedMemos {
    final copy = [...memos];
    copy.sort((a, b) {
      if (a.pinned != b.pinned) {
        return a.pinned ? -1 : 1;
      }
      return b.updatedAt.compareTo(a.updatedAt);
    });
    return copy;
  }

  Memo? get widgetMemo {
    final pinned = memos.where((item) => item.pinned);
    if (pinned.isNotEmpty) {
      return pinned.first;
    }
    if (memos.isEmpty) {
      return null;
    }
    final copy = [...memos];
    copy.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return copy.first;
  }

  Future<Memo?> upsertMemo({
    String? id,
    required String title,
    required String body,
  }) async {
    final now = DateTime.now();
    final trimmedTitle = title.trim();
    final trimmedBody = body.trim();
    if (trimmedTitle.isEmpty && trimmedBody.isEmpty) {
      if (id != null) {
        await deleteMemo(id);
      }
      return null;
    }
    if (id == null) {
      final memo = Memo(
        id: _newId(),
        title: trimmedTitle,
        body: trimmedBody,
        createdAt: now,
        updatedAt: now,
      );
      memos = [...memos, memo];
      await _persistMemos();
      return memo;
    }
    memos = [
      for (final memo in memos)
        if (memo.id == id)
          memo.copyWith(
            title: trimmedTitle,
            body: trimmedBody,
            updatedAt: now,
          )
        else
          memo,
    ];
    await _persistMemos();
    return memos.firstWhere((item) => item.id == id);
  }

  Future<void> deleteMemo(String id) async {
    memos = [for (final memo in memos) if (memo.id != id) memo];
    await _persistMemos();
  }

  Future<void> toggleMemoPinned(String id) async {
    final current = memos.where((item) => item.id == id);
    if (current.isEmpty) {
      return;
    }
    final pin = !current.first.pinned;
    memos = [
      for (final memo in memos)
        memo.copyWith(pinned: memo.id == id ? pin : false),
    ];
    await _persistMemos();
  }

  Future<void> _persistMemos() async {
    await memoRepository.saveAll(memos);
    await _writeWidgetSnapshot();
    notifyListeners();
  }

  WidgetSnapshot _snapshotForPage(TopicPage page, DateTime today) {
    final list = itemsForDate(today, pageId: page.id);
    final counts = countForDate(today, pageId: page.id);
    return WidgetSnapshot(
      date: DateKey.from(today),
      pageId: page.id,
      pageName: page.name,
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
  }

  Future<void> _seedPreviewIfEmpty() async {
    if (items.isNotEmpty || moods.isNotEmpty) {
      return;
    }
    final today = DateKey.from(DateKey.today());
    pages = [
      TopicPage.inbox(),
      TopicPage(
        id: 'sample-study',
        name: '공부',
        sortIndex: 1,
        createdAt: DateTime.now(),
      ),
    ];
    items = [
      for (var i = 0; i < PreviewSample.previewItems.length; i++)
        ChecklistItem(
          id: 'sample-$i',
          title: PreviewSample.previewItems[i].title,
          category: PreviewSample.previewItems[i].category,
          date: today,
          completed: PreviewSample.previewItems[i].repeatsDaily
              ? false
              : PreviewSample.previewItems[i].done,
          createdAt: DateTime.now().add(Duration(milliseconds: i)),
          repeatsDaily: PreviewSample.previewItems[i].repeatsDaily,
          sortIndex: i,
          pageId: PreviewSample.previewItems[i].pageId,
        ),
    ];
    completions = {
      for (var i = 0; i < PreviewSample.previewItems.length; i++)
        if (PreviewSample.previewItems[i].repeatsDaily &&
            PreviewSample.previewItems[i].done)
          RoutineCompletion(itemId: 'sample-$i', date: today),
    };
    moods = {
      today: MoodEntry(date: today, mood: 3, note: '서두르지 않고, 내 속도로 하루를 보냈어요.'),
    };
    await topicRepository.save(pages);
    await moodRepository.saveAll(moods);
    await _persistTasks();
  }

  String _newId() {
    final random = Random();
    return '${DateTime.now().microsecondsSinceEpoch}-${random.nextInt(0x7fffffff)}';
  }
}
