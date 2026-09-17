class TopicPage {
  const TopicPage({
    required this.id,
    required this.name,
    required this.sortIndex,
    required this.createdAt,
  });

  static const inboxId = 'inbox';

  final String id;
  final String name;
  final int sortIndex;
  final DateTime createdAt;

  bool get isInbox => id == inboxId;

  static TopicPage inbox() {
    return TopicPage(
      id: inboxId,
      name: '오늘',
      sortIndex: 0,
      createdAt: DateTime(2026, 1, 1),
    );
  }

  TopicPage copyWith({String? name, int? sortIndex}) {
    return TopicPage(
      id: id,
      name: name ?? this.name,
      sortIndex: sortIndex ?? this.sortIndex,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'sortIndex': sortIndex,
    'createdAt': createdAt.toIso8601String(),
  };

  factory TopicPage.fromJson(Map<String, dynamic> json) {
    return TopicPage(
      id: json['id'] as String,
      name: json['name'] as String,
      sortIndex: (json['sortIndex'] as num?)?.toInt() ?? 0,
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
