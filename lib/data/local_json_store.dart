import 'dart:convert';
import 'dart:io';

class LocalJsonStore {
  LocalJsonStore(this.root);

  final Directory root;

  Directory get _dataDir => Directory('${root.path}/data');

  File _file(String name) => File('${_dataDir.path}/$name.json');

  Future<Map<String, dynamic>> readMap(String name) async {
    final file = _file(name);
    if (!await file.exists()) {
      return <String, dynamic>{};
    }
    final content = await file.readAsString();
    if (content.trim().isEmpty) {
      return <String, dynamic>{};
    }
    final decoded = jsonDecode(content);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    if (decoded is Map) {
      return decoded.map((key, value) => MapEntry(key.toString(), value));
    }
    return <String, dynamic>{};
  }

  Future<void> writeMap(String name, Map<String, dynamic> value) async {
    await _dataDir.create(recursive: true);
    final file = _file(name);
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsString(const JsonEncoder.withIndent('  ').convert(value));
    if (await file.exists()) {
      await file.delete();
    }
    await tmp.rename(file.path);
  }
}
