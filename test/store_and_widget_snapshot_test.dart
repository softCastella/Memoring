import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:memoring/catalog/entitlement.dart';
import 'package:memoring/data/local_json_store.dart';
import 'package:memoring/models/date_key.dart';
import 'package:memoring/models/item_category.dart';
import 'package:memoring/state/app_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late Directory root;
  late AppController controller;

  final png = Uint8List.fromList(
    base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
    ),
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    root = await Directory.systemTemp.createTemp('memoring_store_');
    controller = await AppController.bootstrap(namespace: root.path);
  });

  tearDown(() async {
    if (await root.exists()) {
      await root.delete(recursive: true);
    }
  });

  test('shows only published packs in the store', () async {
    final hidden = await controller.catalog.createPack();
    await controller.catalog.upsertPack(hidden.copyWith(name: '숨김'));
    final visible = await controller.catalog.createPack();
    await controller.catalog.upsertPack(
      visible.copyWith(name: '봄날의 꽃', isPublished: true, isFree: true),
    );

    expect(controller.storePacks.map((item) => item.name), ['봄날의 꽃']);
  });

  test('applies a free pack and refuses paid packs without server checks', () async {
    final free = await controller.catalog.createPack();
    await controller.catalog.addImages(
      packId: free.id,
      files: [(bytes: png, name: 'one.png', mimeType: 'image/png')],
    );
    await controller.catalog.upsertPack(
      controller.catalog.packById(free.id)!.copyWith(
        name: '무료 하늘',
        isPublished: true,
        isFree: true,
      ),
    );

    final freePack = controller.catalog.packById(free.id)!;
    expect(await controller.canAccessPack(freePack), isTrue);
    await controller.applyCatalogBackground(
      pack: freePack,
      asset: freePack.images.single,
    );
    expect(controller.appearance.hasPersonalBackground, isTrue);
    expect(controller.library.isDownloaded(freePack.id), isTrue);
    expect(controller.library.appliedPackId, freePack.id);

    final paid = await controller.catalog.createPack();
    await controller.catalog.addImages(
      packId: paid.id,
      files: [(bytes: png, name: 'paid.png', mimeType: 'image/png')],
    );
    await controller.catalog.upsertPack(
      controller.catalog.packById(paid.id)!.copyWith(
        isPublished: true,
        isFree: false,
        storeProductId: 'background_spring',
      ),
    );
    final paidPack = controller.catalog.packById(paid.id)!;
    expect(await controller.canAccessPack(paidPack), isFalse);
    await expectLater(
      controller.downloadPack(paidPack),
      throwsA(isA<PaidContentLocked>()),
    );
    await expectLater(
      controller.applyCatalogBackground(
        pack: paidPack,
        asset: paidPack.images.single,
      ),
      throwsA(isA<PaidContentLocked>()),
    );
    expect(controller.library.isDownloaded(paidPack.id), isFalse);
  });

  test('writes today snapshot for home widgets', () async {
    await controller.addItem(
      title: '물 마시기',
      category: ItemCategory.todo,
      date: DateKey.today(),
    );
    final store = LocalJsonStore(namespace: root.path);
    await store.ensureReady();
    final body = await store.readMap('widget_snapshot');
    expect(body['total'], 1);
    expect(body['completed'], 0);
    expect((body['items'] as List).single['title'], '물 마시기');
  });
}
