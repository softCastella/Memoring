import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:home_widget/home_widget.dart';

import '../models/date_key.dart';
import '../models/memo.dart';
import '../models/widget_snapshot.dart';

/// Android 홈 위젯에 페이지별 오늘 스냅샷을 전달한다.
/// 웹/데스크톱/테스트에서는 아무 것도 하지 않는다.
class HomeWidgetSync {
  static const androidSmall = 'MemoringSmallWidgetReceiver';
  static const androidMedium = 'MemoringMediumWidgetReceiver';
  static const androidMemo = 'MemoringMemoWidgetReceiver';
  static const androidPackage = 'com.memoring.memoring';

  Future<void> publish(
    List<WidgetSnapshot> snapshots, {
    Memo? memo,
  }) async {
    if (!_supported) {
      return;
    }
    try {
      if (snapshots.isNotEmpty) {
        final dateLabel = DateKey.widgetLabel(
          DateKey.parse(snapshots.first.date),
        );
        await HomeWidget.saveWidgetData<String>(
          'pages_json',
          jsonEncode([
            for (final snapshot in snapshots)
              {'id': snapshot.pageId, 'name': snapshot.pageName},
          ]),
        );
        for (final snapshot in snapshots) {
          await HomeWidget.saveWidgetData<String>(
            'snapshot_${snapshot.pageId}',
            jsonEncode(snapshot.toWidgetPayload(dateLabel)),
          );
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
      }
      await HomeWidget.saveWidgetData<String>(
        'memo_json',
        jsonEncode(_memoPayload(memo)),
      );
      await HomeWidget.updateWidget(
        name: androidMemo,
        androidName: androidMemo,
        qualifiedAndroidName: '$androidPackage.$androidMemo',
      );
    } catch (error) {
      debugPrint('Home widget update skipped: $error');
    }
  }

  Map<String, dynamic> _memoPayload(Memo? memo) {
    if (memo == null || memo.isBlank) {
      return {'empty': true, 'title': '', 'body': ''};
    }
    return {
      'empty': false,
      'title': memo.title.trim().isEmpty ? '메모' : memo.title.trim(),
      'body': memo.body.trim().isEmpty ? memo.title.trim() : memo.body.trim(),
    };
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
