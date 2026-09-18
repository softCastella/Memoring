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
    required this.onOpenStore,
    required this.onOpenMyBackgrounds,
  });

  final AppController controller;
  final VoidCallback onOpenDecorate;
  final VoidCallback onOpenStore;
  final VoidCallback onOpenMyBackgrounds;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
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
          onTap: onOpenStore,
          child: Text('배경 스토어', style: textTheme.titleSmall),
        ),
        const SizedBox(height: 10),
        AppCard(
          onTap: onOpenMyBackgrounds,
          child: Text('내 배경', style: textTheme.titleSmall),
        ),
        const SizedBox(height: 10),
        AppCard(
          child: Text(
            '할 일, 루틴, 마음 기록, 메모, 꾸미기 설정은 이 기기에만 저장됩니다. 네트워크 없이도 사용할 수 있어요.',
            style: textTheme.bodyMedium,
          ),
        ),
        const SizedBox(height: 10),
        AppCard(
          onTap: controller.appearance.hasPersonalBackground
              ? () => controller.restoreDefaultBackground()
              : null,
          child: Text(
            '기본 배경으로 되돌리기',
            style: textTheme.titleSmall?.copyWith(color: palette.accent),
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
          '홈 화면 위젯은 Android 홈 화면에서 추가할 수 있어요. 체크리스트와 메모 위젯을 따로 올릴 수 있습니다. 유료 배경은 스토어 결제와 서버 확인 후에만 열립니다.',
          style: textTheme.bodySmall,
        ),
      ],
        );
      },
    );
  }
}
