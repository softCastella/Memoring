import '../models/memo.dart';
import 'local_json_store.dart';

class MemoRepository {
  MemoRepository(this._store);

  final LocalJsonStore _store;

  Future<List<Memo>> loadAll() async {
    final json = await _store.readMap('memos');
    final raw = json['memos'];
    if (raw is! List) {
      return [];
    }
    return raw
        .whereType<Map>()
        .map((item) => Memo.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<void> saveAll(List<Memo> memos) {
    return _store.writeMap('memos', {
      'memos': memos.map((item) => item.toJson()).toList(),
    });
  }
}
