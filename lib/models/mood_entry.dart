class MoodEntry {
  const MoodEntry({required this.date, required this.mood, required this.note});

  final String date;

  /// 1 지침 ~ 5 기쁨
  final int mood;
  final String note;

  bool get isEmpty => mood == 0 && note.trim().isEmpty;

  MoodEntry copyWith({String? date, int? mood, String? note}) {
    return MoodEntry(
      date: date ?? this.date,
      mood: mood ?? this.mood,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toJson() => {'date': date, 'mood': mood, 'note': note};

  factory MoodEntry.fromJson(Map<String, dynamic> json) {
    return MoodEntry(
      date: json['date'] as String,
      mood: json['mood'] as int? ?? 0,
      note: json['note'] as String? ?? '',
    );
  }

  static const labels = <int, String>{
    1: '지침',
    2: '차분',
    3: '평온',
    4: '설렘',
    5: '기쁨',
  };
}
