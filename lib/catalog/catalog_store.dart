import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'background_pack.dart';

/// 운영자 배경팩 로컬 카탈로그.
/// 이후 서버 URL만 바꾸면 앱이 같은 모델을 내려받을 수 있게 둔다.
class CatalogStore extends ChangeNotifier {
  CatalogStore({this.preferences});

  static const storageKey = 'memoring.catalog.v1';
  static const categories = ['꽃', '하늘', '계절', '기타'];

  SharedPreferences? preferences;
  List<BackgroundPack> packs = [];

  Future<void> load() async {
    preferences ??= await SharedPreferences.getInstance();
    final raw = preferences!.getString(storageKey);
    if (raw == null || raw.isEmpty) {
      packs = [];
      notifyListeners();
      return;
    }
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      packs = [];
      notifyListeners();
      return;
    }
    packs = _packsFrom(decoded);
    notifyListeners();
  }

  Future<void> applyRemote(Map<String, dynamic> body) async {
    packs = _packsFrom(body);
    await _persist();
  }

  List<BackgroundPack> _packsFrom(Map decoded) {
    final list = decoded['packs'];
    if (list is! List) {
      return [];
    }
    return list
        .whereType<Map>()
        .map(
          (item) => BackgroundPack.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  Future<void> _persist() async {
    preferences ??= await SharedPreferences.getInstance();
    await preferences!.setString(
      storageKey,
      jsonEncode({
        'packs': packs.map((item) => item.toJson()).toList(),
      }),
    );
    notifyListeners();
  }

  List<BackgroundPack> get publishedPacks {
    return packs.where((item) => item.isPublished).toList();
  }

  BackgroundPack? packById(String id) {
    for (final pack in packs) {
      if (pack.id == id) {
        return pack;
      }
    }
    return null;
  }

  Future<BackgroundPack> createPack() async {
    final pack = BackgroundPack(
      id: _newId(),
      name: '새 배경팩',
      description: '',
      category: '꽃',
      isFree: true,
      isPublished: false,
      images: const [],
      updatedAt: DateTime.now(),
    );
    packs = [...packs, pack];
    await _persist();
    return pack;
  }

  Future<void> upsertPack(BackgroundPack pack) async {
    final next = pack.copyWith(updatedAt: DateTime.now());
    final exists = packs.any((item) => item.id == next.id);
    if (exists) {
      packs = [
        for (final item in packs)
          if (item.id == next.id) next else item,
      ];
    } else {
      packs = [...packs, next];
    }
    await _persist();
  }

  Future<void> deletePack(String id) async {
    packs = packs.where((item) => item.id != id).toList();
    await _persist();
  }

  Future<BackgroundPack> addImages({
    required String packId,
    required List<({Uint8List bytes, String name, String mimeType})> files,
  }) async {
    final pack = packById(packId);
    if (pack == null) {
      throw StateError('팩을 찾을 수 없습니다.');
    }
    var index = pack.images.length;
    final added = [
      ...pack.images,
      for (final file in files)
        BackgroundAsset(
          id: _newId(),
          fileName: file.name,
          mimeType: file.mimeType,
          base64Data: base64Encode(file.bytes),
          sortIndex: index++,
        ),
    ];
    final next = pack.copyWith(images: added);
    await upsertPack(next);
    return next;
  }

  String _newId() {
    return '${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(1 << 20)}';
  }
}
