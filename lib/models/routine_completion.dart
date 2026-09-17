class RoutineCompletion {
  const RoutineCompletion({required this.itemId, required this.date});

  final String itemId;
  final String date;

  String get key => '$itemId|$date';

  Map<String, dynamic> toJson() => {'itemId': itemId, 'date': date};

  factory RoutineCompletion.fromJson(Map<String, dynamic> json) {
    return RoutineCompletion(
      itemId: json['itemId'] as String,
      date: json['date'] as String,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is RoutineCompletion &&
        other.itemId == itemId &&
        other.date == date;
  }

  @override
  int get hashCode => Object.hash(itemId, date);
}
