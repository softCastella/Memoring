import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'catalog/catalog_bridge.dart';
import 'config/app_config.dart';
import 'models/appearance_settings.dart';
import 'screens/home_shell.dart';
import 'state/app_controller.dart';
import 'theme/app_palette.dart';
import 'theme/app_theme.dart';
import 'widgets/themed_background.dart';

class MemoringApp extends StatefulWidget {
  const MemoringApp({super.key, required this.controller});

  final AppController controller;

  @override
  State<MemoringApp> createState() => _MemoringAppState();
}

class _MemoringAppState extends State<MemoringApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      startCatalogBridge(onCatalog: widget.controller.catalog.applyRemote);
    });
  }

  AppController get controller => widget.controller;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      locale: const Locale('ko', 'KR'),
      supportedLocales: const [Locale('ko', 'KR'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: buildThemeData(AppPalette.rose),
      builder: (context, child) {
        return _WebPhoneShell(
          child: _AppearanceFrame(
            controller: controller,
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
      home: _AppHome(controller: controller),
    );
  }
}

class _AppHome extends StatefulWidget {
  const _AppHome({required this.controller});

  final AppController controller;

  @override
  State<_AppHome> createState() => _AppHomeState();
}

class _AppHomeState extends State<_AppHome> {
  late bool _ready;
  late String? _error;

  AppController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _ready = controller.ready;
    _error = controller.loadError;
    controller.addListener(_onController);
  }

  @override
  void didUpdateWidget(covariant _AppHome oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onController);
      widget.controller.addListener(_onController);
      _ready = widget.controller.ready;
      _error = widget.controller.loadError;
    }
  }

  @override
  void dispose() {
    controller.removeListener(_onController);
    super.dispose();
  }

  void _onController() {
    final ready = controller.ready;
    final error = controller.loadError;
    if (ready != _ready || error != _error) {
      setState(() {
        _ready = ready;
        _error = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return _BootScreen(error: _error, onRetry: controller.load);
    }
    return HomeShell(controller: controller);
  }
}

class _WebPhoneShell extends StatelessWidget {
  const _WebPhoneShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) {
      return child;
    }
    return ColoredBox(
      color: const Color(0xFF2F2926),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: child,
        ),
      ),
    );
  }
}

class _AppearanceFrame extends StatefulWidget {
  const _AppearanceFrame({
    required this.controller,
    required this.child,
  });

  final AppController controller;
  final Widget child;

  @override
  State<_AppearanceFrame> createState() => _AppearanceFrameState();
}

class _AppearanceFrameState extends State<_AppearanceFrame> {
  late AppearanceSettings _appearance;

  AppController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _appearance = controller.appearance;
    controller.addListener(_onController);
  }

  @override
  void didUpdateWidget(covariant _AppearanceFrame oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onController);
      widget.controller.addListener(_onController);
      _appearance = widget.controller.appearance;
    }
  }

  @override
  void dispose() {
    controller.removeListener(_onController);
    super.dispose();
  }

  void _onController() {
    if (!identical(controller.appearance, _appearance)) {
      setState(() => _appearance = controller.appearance);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(_appearance.themeId);
    return ThemeScope(
      palette: palette,
      appearance: _appearance,
      child: Theme(
        data: buildThemeData(palette),
        child: AnnotatedRegion<SystemUiOverlayStyle>(
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
            appearance: _appearance,
            child: widget.child,
          ),
        ),
      ),
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
