import '../models/appearance_settings.dart';
import 'background_file_store.dart';
import 'local_json_store.dart';

class AppearanceRepository {
  AppearanceRepository(this._store, {this.files});

  final LocalJsonStore _store;
  final BackgroundFileStore? files;

  Future<AppearanceSettings> load() async {
    final json = await _store.readMap('appearance');
    if (json.isEmpty) {
      return AppearanceSettings.defaults();
    }
    final settings = AppearanceSettings.fromJson(json);
    final path = settings.personalBackgroundPath;
    if (path != null &&
        path.isNotEmpty &&
        files != null &&
        !files!.exists(path)) {
      return settings.copyWith(clearPersonalBackground: true);
    }
    return settings;
  }

  Future<void> save(AppearanceSettings settings) {
    return _store.writeMap('appearance', settings.toJson());
  }
}
