import 'item_category.dart';
import 'topic_page.dart';

class ChecklistItem {
  const ChecklistItem({
    required this.id,
    required this.title,
    required this.category,
    required this.date,
    required this.completed,
    required this.createdAt,
    this.repeatsDaily = false,
    this.sortIndex = 0,
    this.pageId = TopicPage.inboxId,
  });

  final String id;
  final String title;
  final ItemCategory category;

  /// 한 번만 하는 항목은 해당 날짜. 매일 다시 하는 항목은 반복을 시작하는 날짜.
  final String date;
  final bool completed;
  final DateTime createdAt;
  final bool repeatsDaily;
  final int sortIndex;
  final String pageId;

  /// 자정이 지나면 같은 자리에 미완료로 다시 나타난다.
  bool get repeatsEachDay =>
      repeatsDaily || category == ItemCategory.routine;

  bool get isRoutine => repeatsEachDay;

  ChecklistItem copyWith({
    String? id,
    String? title,
    ItemCategory? category,
    String? date,
    bool? completed,
    DateTime? createdAt,
    bool? repeatsDaily,
    int? sortIndex,
    String? pageId,
  }) {
    return ChecklistItem(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      date: date ?? this.date,
      completed: completed ?? this.completed,
      createdAt: createdAt ?? this.createdAt,
      repeatsDaily: repeatsDaily ?? this.repeatsDaily,
      sortIndex: sortIndex ?? this.sortIndex,
      pageId: pageId ?? this.pageId,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'category': category.storageName,
    'date': date,
    'completed': completed,
    'createdAt': createdAt.toIso8601String(),
    'repeatsDaily': repeatsEachDay,
    'sortIndex': sortIndex,
    'pageId': pageId,
  };

  factory ChecklistItem.fromJson(Map<String, dynamic> json) {
    final category = ItemCategory.fromStorage(json['category'] as String);
    final createdAt =
        DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now();
    return ChecklistItem(
      id: json['id'] as String,
      title: json['title'] as String,
      category: category,
      date: json['date'] as String,
      completed: json['completed'] as bool? ?? false,
      createdAt: createdAt,
      repeatsDaily:
          json['repeatsDaily'] as bool? ?? category == ItemCategory.routine,
      sortIndex:
          (json['sortIndex'] as num?)?.toInt() ??
          createdAt.millisecondsSinceEpoch,
      pageId: json['pageId'] as String? ?? TopicPage.inboxId,
    );
  }
}
