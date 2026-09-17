import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class LocalJsonStore {
  LocalJsonStore({required this.namespace, this._preferences});

  final String namespace;
  SharedPreferences? _preferences;

  Future<void> ensureReady() async {
    _preferences ??= await SharedPreferences.getInstance();
  }

  String _key(String name) => 'memoring.json.$namespace.$name';

  Future<Map<String, dynamic>> readMap(String name) async {
    await ensureReady();
    final raw = _preferences!.getString(_key(name));
    if (raw == null || raw.trim().isEmpty) {
      return <String, dynamic>{};
    }
    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    if (decoded is Map) {
      return decoded.map((key, value) => MapEntry(key.toString(), value));
    }
    return <String, dynamic>{};
  }

  Future<void> writeMap(String name, Map<String, dynamic> value) async {
    await ensureReady();
    await _preferences!.setString(_key(name), jsonEncode(value));
  }
}
