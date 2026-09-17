import 'local_json_store.dart';

class BackgroundLibrary {
  BackgroundLibrary(this._store);

  final LocalJsonStore _store;

  Set<String> downloadedPackIds = {};
  Set<String> favoritePackIds = {};
  String? appliedPackId;
  String? appliedAssetId;

  Future<void> load() async {
    final json = await _store.readMap('background_library');
    downloadedPackIds = _stringSet(json['downloadedPackIds']);
    favoritePackIds = _stringSet(json['favoritePackIds']);
    appliedPackId = json['appliedPackId'] as String?;
    appliedAssetId = json['appliedAssetId'] as String?;
  }

  bool isDownloaded(String packId) => downloadedPackIds.contains(packId);

  bool isFavorite(String packId) => favoritePackIds.contains(packId);

  bool isApplied({required String packId, required String assetId}) {
    return appliedPackId == packId && appliedAssetId == assetId;
  }

  Future<void> markDownloaded(String packId) async {
    downloadedPackIds = {...downloadedPackIds, packId};
    await _persist();
  }

  Future<void> toggleFavorite(String packId) async {
    if (favoritePackIds.contains(packId)) {
      favoritePackIds = favoritePackIds.where((id) => id != packId).toSet();
    } else {
      favoritePackIds = {...favoritePackIds, packId};
    }
    await _persist();
  }

  Future<void> markApplied({
    required String packId,
    required String assetId,
  }) async {
    appliedPackId = packId;
    appliedAssetId = assetId;
    downloadedPackIds = {...downloadedPackIds, packId};
    await _persist();
  }

  Future<void> clearApplied() async {
    appliedPackId = null;
    appliedAssetId = null;
    await _persist();
  }

  Future<void> _persist() {
    return _store.writeMap('background_library', {
      'downloadedPackIds': downloadedPackIds.toList(),
      'favoritePackIds': favoritePackIds.toList(),
      'appliedPackId': appliedPackId,
      'appliedAssetId': appliedAssetId,
    });
  }

  Set<String> _stringSet(Object? raw) {
    if (raw is! List) {
      return {};
    }
    return raw.whereType<String>().toSet();
  }
}
