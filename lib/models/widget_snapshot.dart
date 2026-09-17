import 'appearance_settings.dart';
import 'checklist_item.dart';

/// 이후 Android 홈 위젯이 읽을 요약 스냅샷.
/// 앱 안 미리보기와는 별개이며, 이 파일만으로는 홈 위젯이 구현된 것이 아니다.
class WidgetSnapshot {
  const WidgetSnapshot({
    required this.date,
    required this.completed,
    required this.total,
    required this.items,
    required this.appearance,
  });

  final String date;
  final int completed;
  final int total;
  final List<WidgetSnapshotItem> items;
  final AppearanceSettings appearance;

  Map<String, dynamic> toJson() => {
    'date': date,
    'completed': completed,
    'total': total,
    'progress': total == 0 ? 0.0 : completed / total,
    'items': items.map((item) => item.toJson()).toList(),
    'appearance': appearance.toJson(),
  };
}

class WidgetSnapshotItem {
  const WidgetSnapshotItem({
    required this.id,
    required this.title,
    required this.done,
    required this.category,
  });

  final String id;
  final String title;
  final bool done;
  final String category;

  factory WidgetSnapshotItem.fromChecklist({
    required ChecklistItem item,
    required bool done,
  }) {
    return WidgetSnapshotItem(
      id: item.id,
      title: item.title,
      done: done,
      category: item.category.storageName,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'done': done,
    'category': category,
  };
}
