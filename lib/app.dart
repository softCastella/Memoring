import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'config/app_config.dart';
import 'screens/home_shell.dart';
import 'state/app_controller.dart';
import 'theme/app_palette.dart';
import 'theme/app_theme.dart';
import 'widgets/themed_background.dart';

class MemoringApp extends StatelessWidget {
  const MemoringApp({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final palette = AppPalette.of(controller.appearance.themeId);
        return ThemeScope(
          palette: palette,
          appearance: controller.appearance,
          child: MaterialApp(
            title: AppConfig.appName,
            debugShowCheckedModeBanner: false,
            locale: const Locale('ko', 'KR'),
            supportedLocales: const [Locale('ko', 'KR'), Locale('en')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            theme: buildThemeData(palette),
            builder: (context, child) {
              return AnnotatedRegion<SystemUiOverlayStyle>(
                value: SystemUiOverlayStyle(
                  statusBarColor: Colors.transparent,
                  statusBarIconBrightness: palette.isDark
                      ? Brightness.light
                      : Brightness.dark,
                  systemNavigationBarColor: palette.surface,
                  systemNavigationBarIconBrightness: palette.isDark
                      ? Brightness.light
                      : Brightness.dark,
                ),
                child: ThemedBackground(
                  palette: palette,
                  appearance: controller.appearance,
                  child: child ?? const SizedBox.shrink(),
                ),
              );
            },
            home: controller.ready
                ? HomeShell(controller: controller)
                : _BootScreen(
                    error: controller.loadError,
                    onRetry: controller.load,
                  ),
          ),
        );
      },
    );
  }
}

class _BootScreen extends StatelessWidget {
  const _BootScreen({required this.error, required this.onRetry});

  final String? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final palette = ThemeScope.of(context).palette;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: error == null
            ? Text(AppConfig.appName, style: textTheme.headlineSmall)
            : Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '기록을 불러오지 못했어요',
                      style: textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: onRetry,
                      child: Text(
                        '다시 시도',
                        style: textTheme.labelLarge?.copyWith(
                          color: palette.accent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
