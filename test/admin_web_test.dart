import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memoring/admin/admin_app.dart';
import 'package:memoring/admin/admin_auth.dart';
import 'package:memoring/catalog/catalog_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('admin background manager can create a pack locally', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1400, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final prefs = await SharedPreferences.getInstance();
    final auth = AdminAuth(preferences: prefs);
    await auth.load();
    final catalog = CatalogStore(preferences: prefs);
    await catalog.load();

    await tester.pumpWidget(AdminApp(auth: auth, catalog: catalog));
    await tester.pumpAndSettle();

    expect(find.text('Memoring 관리자 센터'), findsWidgets);
    await tester.enterText(find.byType(TextField), 'local-dev');
    await tester.tap(find.text('비밀번호 저장 후 입장'));
    await tester.pumpAndSettle();

    expect(find.text('배경 관리'), findsWidgets);
    await tester.tap(find.text('새 팩'));
    await tester.pumpAndSettle();
    expect(find.text('이미지 등록'), findsOneWidget);
    expect(find.text('이미지별 설정'), findsOneWidget);
    await tester.ensureVisible(find.text('변경사항 저장'));
    await tester.pumpAndSettle();
    expect(find.text('유료 상품 ID'), findsOneWidget);
    expect(find.text('공개 상태'), findsOneWidget);
    expect(find.text('변경사항 저장'), findsOneWidget);
  });
}
