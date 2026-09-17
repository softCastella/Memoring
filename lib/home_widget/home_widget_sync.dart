import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:home_widget/home_widget.dart';

import '../models/date_key.dart';
import '../models/item_category.dart';
import '../models/widget_snapshot.dart';

/// Android 홈 위젯에 오늘 스냅샷을 전달한다.
/// 웹/데스크톱/테스트에서는 아무 것도 하지 않는다.
class HomeWidgetSync {
  static const androidSmall = 'MemoringSmallWidgetReceiver';
  static const androidMedium = 'MemoringMediumWidgetReceiver';
  static const androidPackage = 'com.memoring.memoring';

  Future<void> publish(WidgetSnapshot snapshot) async {
    if (!_supported) {
      return;
    }
    try {
      final date = DateKey.parse(snapshot.date);
      await HomeWidget.saveWidgetData<String>(
        'date_label',
        DateKey.widgetLabel(date),
      );
      await HomeWidget.saveWidgetData<String>(
        'count_label',
        '${snapshot.completed} / ${snapshot.total}',
      );
      await HomeWidget.saveWidgetData<int>('completed', snapshot.completed);
      await HomeWidget.saveWidgetData<int>('total', snapshot.total);
      await HomeWidget.saveWidgetData<int>(
        'progress',
        snapshot.total == 0
            ? 0
            : ((snapshot.completed / snapshot.total) * 100).round(),
      );
      await HomeWidget.saveWidgetData<bool>('empty', snapshot.total == 0);

      final visible = snapshot.items.take(4).toList();
      await HomeWidget.saveWidgetData<int>('item_count', visible.length);
      for (var i = 0; i < 4; i++) {
        if (i < visible.length) {
          final item = visible[i];
          await HomeWidget.saveWidgetData<String>('item_${i}_id', item.id);
          await HomeWidget.saveWidgetData<String>('item_${i}_title', item.title);
          await HomeWidget.saveWidgetData<bool>('item_${i}_done', item.done);
          await HomeWidget.saveWidgetData<String>(
            'item_${i}_category',
            ItemCategory.fromStorage(item.category).label,
          );
        } else {
          await HomeWidget.saveWidgetData<String>('item_${i}_id', '');
          await HomeWidget.saveWidgetData<String>('item_${i}_title', '');
          await HomeWidget.saveWidgetData<bool>('item_${i}_done', false);
          await HomeWidget.saveWidgetData<String>('item_${i}_category', '');
        }
      }

      await HomeWidget.updateWidget(
        name: androidSmall,
        androidName: androidSmall,
        qualifiedAndroidName: '$androidPackage.$androidSmall',
      );
      await HomeWidget.updateWidget(
        name: androidMedium,
        androidName: androidMedium,
        qualifiedAndroidName: '$androidPackage.$androidMedium',
      );
    } catch (error) {
      debugPrint('Home widget update skipped: $error');
    }
  }

  bool get _supported {
    if (kIsWeb) {
      return false;
    }
    try {
      WidgetsBinding.instance;
    } catch (_) {
      return false;
    }
    return defaultTargetPlatform == TargetPlatform.android;
  }
}
