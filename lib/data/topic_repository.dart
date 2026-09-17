import '../models/topic_page.dart';
import 'local_json_store.dart';

class TopicRepository {
  TopicRepository(this._store);

  final LocalJsonStore _store;

  Future<List<TopicPage>> load() async {
    final json = await _store.readMap('topic_pages');
    final raw = json['pages'];
    if (raw is! List) {
      return [TopicPage.inbox()];
    }
    final pages = raw
        .whereType<Map>()
        .map((item) => TopicPage.fromJson(Map<String, dynamic>.from(item)))
        .toList();
    if (pages.every((page) => !page.isInbox)) {
      pages.insert(0, TopicPage.inbox());
    }
    pages.sort((a, b) => a.sortIndex.compareTo(b.sortIndex));
    return pages;
  }

  Future<void> save(List<TopicPage> pages) {
    return _store.writeMap('topic_pages', {
      'pages': pages.map((page) => page.toJson()).toList(),
    });
  }
}
