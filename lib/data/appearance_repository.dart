import 'dart:io';

import '../models/appearance_settings.dart';
import 'local_json_store.dart';

class AppearanceRepository {
  AppearanceRepository(this._store);

  final LocalJsonStore _store;

  Future<AppearanceSettings> load() async {
    final json = await _store.readMap('appearance');
    if (json.isEmpty) {
      return AppearanceSettings.defaults();
    }
    final settings = AppearanceSettings.fromJson(json);
    if (settings.hasPersonalBackground) {
      final file = File(settings.personalBackgroundPath!);
      if (!await file.exists()) {
        return settings.copyWith(clearPersonalBackground: true);
      }
    }
    return settings;
  }

  Future<void> save(AppearanceSettings settings) {
    return _store.writeMap('appearance', settings.toJson());
  }
}
