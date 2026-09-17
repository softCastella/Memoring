import '../models/mood_entry.dart';
import 'local_json_store.dart';

class MoodRepository {
  MoodRepository(this._store);

  final LocalJsonStore _store;

  Future<Map<String, MoodEntry>> loadAll() async {
    final json = await _store.readMap('mood_entries');
    final raw = json['entries'];
    if (raw is! List) {
      return {};
    }
    final map = <String, MoodEntry>{};
    for (final item in raw.whereType<Map>()) {
      final entry = MoodEntry.fromJson(Map<String, dynamic>.from(item));
      map[entry.date] = entry;
    }
    return map;
  }

  Future<void> saveAll(Map<String, MoodEntry> entries) {
    return _store.writeMap('mood_entries', {
      'entries': entries.values.map((item) => item.toJson()).toList(),
    });
  }
}
