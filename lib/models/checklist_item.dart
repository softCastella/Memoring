import 'item_category.dart';

class ChecklistItem {
  const ChecklistItem({
    required this.id,
    required this.title,
    required this.category,
    required this.date,
    required this.completed,
    required this.createdAt,
  });

  final String id;
  final String title;
  final ItemCategory category;

  /// 할 일·공부·업무는 해당 날짜. 루틴은 반복을 시작하는 날짜.
  final String date;
  final bool completed;
  final DateTime createdAt;

  bool get isRoutine => category == ItemCategory.routine;

  ChecklistItem copyWith({
    String? id,
    String? title,
    ItemCategory? category,
    String? date,
    bool? completed,
    DateTime? createdAt,
  }) {
    return ChecklistItem(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      date: date ?? this.date,
      completed: completed ?? this.completed,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'category': category.storageName,
    'date': date,
    'completed': completed,
    'createdAt': createdAt.toIso8601String(),
  };

  factory ChecklistItem.fromJson(Map<String, dynamic> json) {
    return ChecklistItem(
      id: json['id'] as String,
      title: json['title'] as String,
      category: ItemCategory.fromStorage(json['category'] as String),
      date: json['date'] as String,
      completed: json['completed'] as bool? ?? false,
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
