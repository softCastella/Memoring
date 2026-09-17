import 'package:flutter/widgets.dart';
import 'package:home_widget/home_widget.dart';

import '../models/date_key.dart';
import '../state/app_controller.dart';

@pragma('vm:entry-point')
Future<void> homeWidgetBackground(Uri? uri) async {
  WidgetsFlutterBinding.ensureInitialized();
  if (uri?.host != 'toggle') {
    return;
  }
  final id = uri?.queryParameters['id'];
  if (id == null || id.isEmpty) {
    return;
  }
  final controller = await AppController.bootstrap();
  controller.selectDate(DateKey.today());
  final exists = controller.items.any((item) => item.id == id);
  if (!exists) {
    return;
  }
  await controller.toggleComplete(id);
}

Future<void> registerHomeWidgetCallback() async {
  try {
    await HomeWidget.registerInteractivityCallback(homeWidgetBackground);
  } catch (_) {
    // 웹/데스크톱/테스트에서는 플러그인이 없을 수 있다.
  }
}
