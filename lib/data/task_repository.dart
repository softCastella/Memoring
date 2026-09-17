import '../models/checklist_item.dart';
import '../models/routine_completion.dart';
import 'local_json_store.dart';

class TaskRepository {
  TaskRepository(this._store);

  final LocalJsonStore _store;

  Future<List<ChecklistItem>> loadItems() async {
    final json = await _store.readMap('items');
    final raw = json['items'];
    if (raw is! List) {
      return [];
    }
    return raw
        .whereType<Map>()
        .map((item) => ChecklistItem.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<void> saveItems(List<ChecklistItem> items) {
    return _store.writeMap('items', {
      'items': items.map((item) => item.toJson()).toList(),
    });
  }

  Future<Set<RoutineCompletion>> loadCompletions() async {
    final json = await _store.readMap('routine_completions');
    final raw = json['completions'];
    if (raw is! List) {
      return <RoutineCompletion>{};
    }
    return raw
        .whereType<Map>()
        .map(
          (item) =>
              RoutineCompletion.fromJson(Map<String, dynamic>.from(item)),
        )
        .toSet();
  }

  Future<void> saveCompletions(Set<RoutineCompletion> completions) {
    return _store.writeMap('routine_completions', {
      'completions': completions.map((item) => item.toJson()).toList(),
    });
  }
}
