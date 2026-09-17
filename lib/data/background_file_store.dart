import 'dart:convert';
import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';

class BackgroundFileStore {
  BackgroundFileStore({
    required this.namespace,
    this._preferences,
  }) {
    current = this;
  }

  static BackgroundFileStore? current;

  final String namespace;
  SharedPreferences? _preferences;
  final Map<String, Uint8List> _cache = {};

  Future<void> load() async {
    _preferences ??= await SharedPreferences.getInstance();
    final prefix = _keyPrefix;
    for (final key in _preferences!.getKeys()) {
      if (!key.startsWith(prefix)) {
        continue;
      }
      final raw = _preferences!.getString(key);
      if (raw == null || raw.isEmpty) {
        continue;
      }
      try {
        _cache[key] = Uint8List.fromList(base64Decode(raw));
      } catch (_) {}
    }
  }

  String get _keyPrefix => 'memoring.bg.$namespace.';

  String _token(String fileName, String ext) => '$_keyPrefix$fileName$ext';

  bool exists(String path) => _cache.containsKey(path);

  Uint8List? readSync(String path) => _cache[path];

  Future<Uint8List?> read(String path) async {
    return _cache[path];
  }

  String extensionOf(String path) {
    final dot = path.lastIndexOf('.');
    if (dot < 0) {
      return '.jpg';
    }
    return path.substring(dot).toLowerCase();
  }

  Future<String> persistBytes(
    List<int> bytes, {
    String fileName = 'current',
    String ext = '.jpg',
  }) async {
    await load();
    var suffix = ext.toLowerCase();
    if (suffix.isEmpty) {
      suffix = '.jpg';
    }
    if (!suffix.startsWith('.')) {
      suffix = '.$suffix';
    }
    if (!_allowed.contains(suffix)) {
      suffix = '.jpg';
    }
    await _deleteNamed(fileName);
    final token = _token(fileName, suffix);
    final data = Uint8List.fromList(bytes);
    _cache[token] = data;
    await _preferences!.setString(token, base64Encode(data));
    return token;
  }

  Future<void> clearPersonal() async {
    await load();
    final keys = _cache.keys.where((key) => key.startsWith(_keyPrefix)).toList();
    for (final key in keys) {
      _cache.remove(key);
      await _preferences!.remove(key);
    }
  }

  Future<void> _deleteNamed(String fileName) async {
    final matches = _cache.keys
        .where((key) {
          final name = key.substring(_keyPrefix.length);
          final dot = name.lastIndexOf('.');
          final base = dot < 0 ? name : name.substring(0, dot);
          return base == fileName;
        })
        .toList();
    for (final key in matches) {
      _cache.remove(key);
      await _preferences!.remove(key);
    }
  }

  static const _allowed = {'.jpg', '.jpeg', '.png', '.webp', '.heic', '.gif'};
}
