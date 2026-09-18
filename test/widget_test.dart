import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memoring/app.dart';
import 'package:memoring/screens/decorate_screen.dart';
import 'package:memoring/screens/item_editor_sheet.dart';
import 'package:memoring/state/app_controller.dart';
import 'package:memoring/widgets/soft_bottom_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late Directory root;
  late AppController controller;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    root = await Directory.systemTemp.createTemp('memoring_widget_');
    controller = await AppController.bootstrap(namespace: root.path);
  });

  tearDown(() async {
    if (await root.exists()) {
      await root.delete(recursive: true);
    }
  });

  Finder editorField() {
    return find.descendant(
      of: find.byType(ItemEditorSheet),
      matching: find.byType(TextField),
    );
  }

  testWidgets('adds, completes, edits and deletes an item from today screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(MemoringApp(controller: controller));
    await tester.pumpAndSettle();

    expect(find.text('오늘의 여백'), findsOneWidget);
    expect(find.text('아직 약속이 없어요. 아래 버튼으로 오늘의 할 일을 남겨 보세요.'), findsOneWidget);

    await tester.tap(find.text('할 일 추가'));
    await tester.pumpAndSettle();
    await tester.enterText(editorField(), '물 마시기');
    final addButton = find.descendant(
      of: find.byType(ItemEditorSheet),
      matching: find.widgetWithText(FilledButton, '추가'),
    );
    await tester.ensureVisible(addButton);
    await tester.tap(addButton);
    await tester.pumpAndSettle();

    expect(find.text('물 마시기'), findsOneWidget);
    expect(controller.items, hasLength(1));
    expect(controller.countForDate(controller.selectedDate).total, 1);
    expect(find.byKey(const Key('today-count')), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const Key('today-count'))).data,
      '0 / 1',
    );

    await tester.tap(find.text('물 마시기'));
    await tester.pumpAndSettle();
    await tester.enterText(editorField(), '따뜻한 차');
    await tester.tap(find.widgetWithText(FilledButton, '저장'));
    await tester.pumpAndSettle();
    expect(find.text('따뜻한 차'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('완료'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<Text>(find.byKey(const Key('today-count'))).data,
      '1 / 1',
    );

    await tester.tap(find.text('따뜻한 차'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('삭제'));
    await tester.pumpAndSettle();
    expect(find.text('아직 약속이 없어요. 아래 버튼으로 오늘의 할 일을 남겨 보세요.'), findsOneWidget);
  });

  testWidgets('keeps layout usable on a small screen', (tester) async {
    tester.view.physicalSize = const Size(640, 1136);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(MemoringApp(controller: controller));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('할 일 추가'), findsOneWidget);
    expect(find.text('오늘'), findsWidgets);
    await tester.tap(find.text('기록'));
    await tester.pumpAndSettle();
    expect(find.text('지금, 내 마음은'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);

    tester.view.viewInsets = const FakeViewPadding(bottom: 280);
    addTearDown(tester.view.resetViewInsets);
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.byType(TextField), findsOneWidget);

    await tester.tap(find.text('설정'));
    await tester.pumpAndSettle();
    expect(find.text('앱 꾸미기'), findsOneWidget);
    await tester.tap(find.text('앱 꾸미기'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('꾸미기'), findsWidgets);
    await tester.scrollUntilVisible(
      find.text('로즈'),
      240,
      scrollable: find
          .descendant(
            of: find.byType(DecorateScreen),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(find.text('로즈'), findsOneWidget);
    expect(find.text('세이지'), findsOneWidget);
  });

  testWidgets('opens background store from settings', (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(MemoringApp(controller: controller));
    await tester.pumpAndSettle();
    await tester.tap(find.text('스토어'));
    await tester.pumpAndSettle();
    expect(
      find.text('공개된 배경팩이 아직 없어요. 관리자에서 팩을 공개하면 여기에 나타나요.'),
      findsWidgets,
    );

    final pack = await controller.catalog.createPack();
    await controller.catalog.upsertPack(
      pack.copyWith(name: '봄날의 꽃', isPublished: true, isFree: true),
    );
    await tester.pumpAndSettle();
    expect(find.text('봄날의 꽃'), findsOneWidget);
  });

  testWidgets('shows image titles in the store pack gallery', (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final png = Uint8List.fromList(
      base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
      ),
    );
    final pack = await controller.catalog.createPack();
    await controller.catalog.addImages(
      packId: pack.id,
      files: [(bytes: png, name: 'one.png', mimeType: 'image/png')],
    );
    final stored = controller.catalog.packById(pack.id)!;
    await controller.catalog.upsertPack(
      stored.copyWith(
        name: '봄날의 꽃',
        isPublished: true,
        isFree: true,
        images: [stored.images.single.copyWith(title: '첫번째 꽃')],
      ),
    );

    await tester.pumpWidget(MemoringApp(controller: controller));
    await tester.pumpAndSettle();
    await tester.tap(find.text('스토어'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('봄날의 꽃'));
    await tester.pumpAndSettle();
    expect(find.text('첫번째 꽃'), findsWidgets);
  });

  testWidgets('adds a memo from the memo tab', (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(MemoringApp(controller: controller));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(SoftBottomBar),
        matching: find.text('메모'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('아직 메모가 없어요. 마음에 남는 한 줄을 적어 보세요.'), findsOneWidget);

    await tester.tap(find.text('메모 추가'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '장보기');
    await tester.enterText(find.byType(TextField).last, '우유랑 식빵');
    await tester.tap(find.widgetWithText(FilledButton, '저장'));
    await tester.pumpAndSettle();

    expect(find.text('장보기'), findsOneWidget);
    expect(find.text('우유랑 식빵'), findsOneWidget);
    expect(controller.memos, hasLength(1));
    expect(controller.widgetMemo?.title, '장보기');
  });
}
