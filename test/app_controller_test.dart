import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:memoring/models/app_theme_id.dart';
import 'package:memoring/models/date_key.dart';
import 'package:memoring/models/item_category.dart';
import 'package:memoring/state/app_controller.dart';

void main() {
  late Directory root;
  late AppController controller;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('memoring_controller_');
    controller = await AppController.bootstrap(root);
  });

  tearDown(() async {
    if (await root.exists()) {
      await root.delete(recursive: true);
    }
  });

  test('starts empty with rose theme and no photo', () {
    expect(controller.items, isEmpty);
    expect(controller.moods, isEmpty);
    expect(controller.appearance.themeId, AppThemeId.rose);
    expect(controller.appearance.hasPersonalBackground, isFalse);
  });

  test('adds, edits, completes and deletes a dated item', () async {
    final today = DateKey.today();
    await controller.addItem(
      title: '물 마시기',
      category: ItemCategory.todo,
      date: today,
    );
    expect(controller.visibleItems.single.title, '물 마시기');
    expect(controller.countForDate(today).completed, 0);
    expect(controller.countForDate(today).total, 1);

    final id = controller.visibleItems.single.id;
    await controller.updateItem(
      id: id,
      title: '차 마시기',
      category: ItemCategory.study,
      date: today,
    );
    expect(controller.visibleItems.single.title, '차 마시기');
    expect(controller.visibleItems.single.category, ItemCategory.study);

    await controller.toggleComplete(id);
    expect(controller.isCompleted(controller.visibleItems.single), isTrue);
    expect(controller.countForDate(today).completed, 1);

    await controller.toggleComplete(id);
    expect(controller.isCompleted(controller.visibleItems.single), isFalse);

    await controller.deleteItem(id);
    expect(controller.visibleItems, isEmpty);
  });

  test('keeps todo items on their own dates', () async {
    final today = DateKey.today();
    final yesterday = DateKey.addDays(today, -1);
    await controller.addItem(
      title: '오늘 할 일',
      category: ItemCategory.todo,
      date: today,
    );
    await controller.addItem(
      title: '어제 할 일',
      category: ItemCategory.todo,
      date: yesterday,
    );

    expect(
      controller.itemsForDate(today).map((item) => item.title),
      ['오늘 할 일'],
    );
    expect(
      controller.itemsForDate(yesterday).map((item) => item.title),
      ['어제 할 일'],
    );
  });

  test('stores routine completion per date without overwriting', () async {
    final today = DateKey.today();
    final tomorrow = DateKey.addDays(today, 1);
    final item = await controller.addItem(
      title: '스트레칭',
      category: ItemCategory.routine,
      date: today,
    );

    await controller.toggleComplete(item.id);
    expect(controller.isCompleted(item, DateKey.from(today)), isTrue);

    controller.selectDate(tomorrow);
    expect(controller.isCompleted(item, DateKey.from(tomorrow)), isFalse);
    expect(controller.visibleItems.single.title, '스트레칭');

    await controller.toggleComplete(item.id);
    expect(controller.isCompleted(item, DateKey.from(tomorrow)), isTrue);

    controller.selectDate(today);
    expect(controller.isCompleted(item, DateKey.from(today)), isTrue);
    expect(controller.countForDate(today).completed, 1);
    expect(controller.countForDate(tomorrow).completed, 1);
  });

  test('persists tasks, moods and theme across reload', () async {
    final today = DateKey.today();
    final item = await controller.addItem(
      title: '기록 유지',
      category: ItemCategory.routine,
      date: today,
    );
    await controller.toggleComplete(item.id);
    await controller.saveMood(mood: 4, note: '따뜻한 하루');
    await controller.setTheme(AppThemeId.sage);

    final reloaded = await AppController.bootstrap(root);
    expect(reloaded.items.single.title, '기록 유지');
    expect(
      reloaded.isCompleted(reloaded.items.single, DateKey.from(today)),
      isTrue,
    );
    expect(reloaded.moodFor(today).mood, 4);
    expect(reloaded.moodFor(today).note, '따뜻한 하루');
    expect(reloaded.appearance.themeId, AppThemeId.sage);
  });

  test('restores default appearance and persists copied background', () async {
    final source = File('${root.path}/picked.png');
    await source.writeAsBytes(_tinyPng);
    final draftPath = await controller.persistPickedBackground(source);
    expect(File(draftPath).existsSync(), isTrue);

    await controller.applyAppearance(
      controller.appearance.copyWith(
        themeId: AppThemeId.night,
        personalBackgroundPath: draftPath,
        scale: 1.2,
        offsetX: 0.3,
        blur: 4,
        cardOpacity: 0.8,
      ),
    );

    expect(controller.appearance.themeId, AppThemeId.night);
    expect(controller.appearance.hasPersonalBackground, isTrue);
    expect(
      controller.appearance.personalBackgroundPath,
      contains('current'),
    );
    expect(File(controller.appearance.personalBackgroundPath!).existsSync(), isTrue);

    final reloaded = await AppController.bootstrap(root);
    expect(reloaded.appearance.themeId, AppThemeId.night);
    expect(File(reloaded.appearance.personalBackgroundPath!).existsSync(), isTrue);

    await reloaded.restoreDefaultAppearance();
    expect(reloaded.appearance.themeId, AppThemeId.rose);
    expect(reloaded.appearance.hasPersonalBackground, isFalse);
    expect(reloaded.appearance.scale, 1.0);
    expect(reloaded.appearance.cardOpacity, 1.0);
  });
}

final Uint8List _tinyPng = Uint8List.fromList(
  base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
  ),
);
