import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memoring/app.dart';
import 'package:memoring/screens/decorate_screen.dart';
import 'package:memoring/screens/item_editor_sheet.dart';
import 'package:memoring/state/app_controller.dart';

void main() {
  late Directory root;
  late AppController controller;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('memoring_widget_');
    controller = await AppController.bootstrap(root);
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
    await tester.drag(find.byType(DecorateScreen), const Offset(0, -420));
    await tester.pumpAndSettle();
    expect(find.text('로즈'), findsOneWidget);
    expect(find.text('세이지'), findsOneWidget);
  });
}
