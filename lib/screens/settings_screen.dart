import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../state/app_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.controller,
    required this.onOpenDecorate,
  });

  final AppController controller;
  final VoidCallback onOpenDecorate;

  @override
  Widget build(BuildContext context) {
    final palette = ThemeScope.of(context).palette;
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
      children: [
        Text('설정', style: textTheme.displaySmall),
        const SizedBox(height: 8),
        Text(
          '표시 이름은 앱 설정값에서 바꿀 수 있어요.',
          style: textTheme.bodyMedium?.copyWith(color: palette.textMuted),
        ),
        const SizedBox(height: 22),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('앱 이름', style: textTheme.labelMedium),
              const SizedBox(height: 4),
              Text(AppConfig.appName, style: textTheme.titleMedium),
            ],
          ),
        ),
        const SizedBox(height: 10),
        AppCard(
          onTap: onOpenDecorate,
          child: Text('앱 꾸미기', style: textTheme.titleSmall),
        ),
        const SizedBox(height: 10),
        AppCard(
          child: Text(
            '할 일, 루틴, 마음 기록, 꾸미기 설정은 이 기기에만 저장됩니다. 네트워크 없이도 사용할 수 있어요.',
            style: textTheme.bodyMedium,
          ),
        ),
        const SizedBox(height: 10),
        AppCard(
          onTap: () => controller.restoreDefaultAppearance(),
          child: Text(
            '기본 디자인으로 복원',
            style: textTheme.titleSmall?.copyWith(color: palette.accent),
          ),
        ),
        const SizedBox(height: 22),
        Text(
          '배경 스토어와 홈 화면 위젯은 다음 단계에서 연결할 예정이에요.',
          style: textTheme.bodySmall,
        ),
      ],
    );
  }
}
