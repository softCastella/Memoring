/// 로컬 달력 날짜 키 (yyyy-MM-dd). UTC 자정 변환을 쓰지 않는다.
class DateKey {
  static String from(DateTime date) {
    final local = DateTime(date.year, date.month, date.day);
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '${local.year}-$month-$day';
  }

  static DateTime parse(String key) {
    final parts = key.split('-');
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }

  static DateTime today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  static DateTime only(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static DateTime addDays(DateTime date, int days) =>
      DateTime(date.year, date.month, date.day + days);

  static DateTime weekStart(DateTime date) {
    final local = only(date);
    return local.subtract(Duration(days: local.weekday - 1));
  }

  static const weekdaysLong = [
    '월요일',
    '화요일',
    '수요일',
    '목요일',
    '금요일',
    '토요일',
    '일요일',
  ];

  static const weekdaysShort = ['월', '화', '수', '목', '금', '토', '일'];

  static String longLabel(DateTime date) {
    return '${date.month}월 ${date.day}일 ${weekdaysLong[date.weekday - 1]}';
  }

  static String widgetLabel(DateTime date) {
    return '${date.month}월 ${date.day}일 (${weekdaysShort[date.weekday - 1]})';
  }
}
