import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'background_pack.dart';
import 'catalog_client.dart';

/// 운영자 배경팩 로컬 카탈로그.
/// 테스트 서버가 있으면 공개 팩을 앱과 공유한다.
class CatalogStore extends ChangeNotifier {
  CatalogStore({this.preferences, this.client}) {
    current = this;
  }

  static CatalogStore? current;

  static const storageKey = 'memoring.catalog.v1';
  static const categories = ['꽃', '하늘', '계절', '기타'];

  SharedPreferences? preferences;
  CatalogClient? client;
  List<BackgroundPack> packs = [];
  String? lastSyncError;

  Map<String, dynamic> _body() => {
    'packs': packs.map((item) => item.toJson()).toList(),
  };

  Future<void> load() async {
    preferences ??= await SharedPreferences.getInstance();
    final raw = preferences!.getString(storageKey);
    if (raw == null || raw.isEmpty) {
      packs = [];
    } else {
      final decoded = jsonDecode(raw);
      packs = decoded is Map ? _packsFrom(decoded) : [];
    }
    notifyListeners();
    await syncFromServer();
  }

  Future<void> syncFromServer() async {
    final remoteClient = client;
    if (remoteClient == null) {
      return;
    }
    lastSyncError = null;
    final remote = await remoteClient.pull();
    if (remote == null) {
      lastSyncError =
          remoteClient.lastError ?? '카탈로그 서버에 연결하지 못했어요.';
      notifyListeners();
      return;
    }
    final remotePacks = _packsFrom(remote);
    if (remotePacks.isNotEmpty) {
      packs = remotePacks;
      await _persistLocalOnly();
      notifyListeners();
      return;
    }
    if (packs.isNotEmpty) {
      await remoteClient.push(_body());
    }
  }

  Future<void> applyRemote(Map<String, dynamic> body) async {
    final next = _packsFrom(body);
    if (next.isEmpty && packs.isNotEmpty) {
      return;
    }
    packs = next;
    await _persistLocalOnly();
    notifyListeners();
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
    await _persistLocalOnly();
    notifyListeners();
    if (packs.isEmpty) {
      return;
    }
    await client?.push(_body());
  }

  Future<void> _persistLocalOnly() async {
    preferences ??= await SharedPreferences.getInstance();
    try {
      await preferences!.setString(storageKey, jsonEncode(_metadataBody()));
    } catch (_) {}
  }

  Map<String, dynamic> _metadataBody() => {
    'packs': [
      for (final pack in packs)
        pack
            .copyWith(
              images: [
                for (final image in pack.images)
                  image.copyWith(base64Data: ''),
              ],
            )
            .toJson(),
    ],
  };

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

  BackgroundAsset? assetByCatalogId(String? catalogBackgroundId) {
    if (catalogBackgroundId == null || catalogBackgroundId.isEmpty) {
      return null;
    }
    final slash = catalogBackgroundId.indexOf('/');
    if (slash <= 0 || slash >= catalogBackgroundId.length - 1) {
      return null;
    }
    final pack = packById(catalogBackgroundId.substring(0, slash));
    if (pack == null) {
      return null;
    }
    final assetId = catalogBackgroundId.substring(slash + 1);
    for (final asset in pack.images) {
      if (asset.id == assetId) {
        return asset;
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
          title: BackgroundAsset.titleFromFileName(file.name),
          isFree: true,
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
