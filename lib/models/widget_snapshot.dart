import 'appearance_settings.dart';
import 'checklist_item.dart';
import 'item_category.dart';
import 'topic_page.dart';

/// 이후 Android 홈 위젯이 읽을 요약 스냅샷.
/// 앱 안 미리보기와는 별개이며, 이 파일만으로는 홈 위젯이 구현된 것이 아니다.
class WidgetSnapshot {
  const WidgetSnapshot({
    required this.date,
    required this.completed,
    required this.total,
    required this.items,
    required this.appearance,
    this.pageId = TopicPage.inboxId,
    this.pageName = '오늘',
  });

  final String date;
  final int completed;
  final int total;
  final List<WidgetSnapshotItem> items;
  final AppearanceSettings appearance;
  final String pageId;
  final String pageName;

  bool get isInbox => pageId == TopicPage.inboxId;

  String get listTitle => isInbox ? '오늘의 리스트' : pageName;

  String get progressTitle => isInbox ? '오늘의 진행' : pageName;

  Map<String, dynamic> toJson() => {
    'date': date,
    'pageId': pageId,
    'pageName': pageName,
    'completed': completed,
    'total': total,
    'progress': total == 0 ? 0.0 : completed / total,
    'items': items.map((item) => item.toJson()).toList(),
    'appearance': appearance.toJson(),
  };

  Map<String, dynamic> toWidgetPayload(String dateLabel) => {
    'id': pageId,
    'name': pageName,
    'title_list': listTitle,
    'title_progress': progressTitle,
    'date_label': dateLabel,
    'count_label': '$completed / $total',
    'progress': total == 0 ? 0 : ((completed / total) * 100).round(),
    'empty': total == 0,
    'items': items
        .take(4)
        .map(
          (item) => {
            'id': item.id,
            'title': item.title,
            'done': item.done,
            'category': item.categoryLabel,
            'repeats': item.repeatsDaily,
          },
        )
        .toList(),
  };
}

class WidgetSnapshotItem {
  const WidgetSnapshotItem({
    required this.id,
    required this.title,
    required this.done,
    required this.category,
    this.repeatsDaily = false,
  });

  final String id;
  final String title;
  final bool done;
  final String category;
  final bool repeatsDaily;

  factory WidgetSnapshotItem.fromChecklist({
    required ChecklistItem item,
    required bool done,
  }) {
    return WidgetSnapshotItem(
      id: item.id,
      title: item.title,
      done: done,
      category: item.category.storageName,
      repeatsDaily: item.repeatsEachDay,
    );
  }

  String get categoryLabel => ItemCategory.fromStorage(category).label;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'done': done,
    'category': category,
    'repeatsDaily': repeatsDaily,
  };
}
