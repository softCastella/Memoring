import 'dart:io';

import 'package:path/path.dart' as p;

class BackgroundFileStore {
  BackgroundFileStore(this.root);

  final Directory root;

  Directory get personalDir =>
      Directory('${root.path}/backgrounds/personal');

  Future<String> persistPersonal(File source, {String fileName = 'current'}) async {
    await personalDir.create(recursive: true);
    var ext = p.extension(source.path).toLowerCase();
    if (!_allowed.contains(ext)) {
      ext = '.jpg';
    }
    await _deleteNamed(fileName);
    final dest = File('${personalDir.path}/$fileName$ext');
    await source.copy(dest.path);
    return dest.path;
  }

  Future<void> clearPersonal() async {
    if (!await personalDir.exists()) {
      return;
    }
    await for (final entity in personalDir.list()) {
      if (entity is File) {
        await entity.delete();
      }
    }
  }

  Future<void> _deleteNamed(String fileName) async {
    if (!await personalDir.exists()) {
      return;
    }
    await for (final entity in personalDir.list()) {
      if (entity is File && p.basenameWithoutExtension(entity.path) == fileName) {
        await entity.delete();
      }
    }
  }

  static const _allowed = {'.jpg', '.jpeg', '.png', '.webp', '.heic', '.gif'};
}
