import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:memoring/catalog/catalog_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late CatalogStore store;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    store = CatalogStore(preferences: prefs);
    await store.load();
  });

  test('creates, updates and reloads a background pack', () async {
    final pack = await store.createPack();
    expect(store.packs, hasLength(1));
    expect(pack.isPublished, isFalse);
    expect(pack.isFree, isTrue);

    await store.upsertPack(
      pack.copyWith(
        name: '봄날의 꽃',
        isFree: false,
        isPublished: true,
        storeProductId: 'background_spring_flowers',
      ),
    );
    expect(store.packs.single.name, '봄날의 꽃');
    expect(store.packs.single.storeProductId, 'background_spring_flowers');

    final png = Uint8List.fromList([
      137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, 73, 72, 68, 82,
    ]);
    await store.addImages(
      packId: pack.id,
      files: [(bytes: png, name: 'one.png', mimeType: 'image/png')],
    );
    expect(store.packs.single.imageCount, 1);

    final reloaded = CatalogStore(
      preferences: await SharedPreferences.getInstance(),
    );
    await reloaded.load();
    expect(reloaded.packs.single.name, '봄날의 꽃');
    expect(reloaded.packs.single.imageCount, 1);
    expect(reloaded.packs.single.isPublished, isTrue);
  });

  test('applyRemote replaces local packs from admin payload', () async {
    await store.createPack();
    await store.applyRemote({
      'packs': [
        {
          'id': 'remote-1',
          'name': '무료 하늘',
          'description': '',
          'category': '하늘',
          'isFree': true,
          'isPublished': true,
          'images': [],
          'updatedAt': DateTime.now().toIso8601String(),
        },
      ],
    });
    expect(store.publishedPacks.single.name, '무료 하늘');
  });
}
