import '../models/widget_snapshot.dart';
import 'local_json_store.dart';

class WidgetSnapshotWriter {
  WidgetSnapshotWriter(this._store);

  final LocalJsonStore _store;

  Future<void> write(WidgetSnapshot snapshot) {
    return _store.writeMap('widget_snapshot', snapshot.toJson());
  }
}
