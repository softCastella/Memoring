import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../theme/app_palette.dart';

/// 기동 스플래시. 로고가 페이드인된 뒤 사르르 사라지며 앱 화면을 드러낸다.
class LaunchSplashOverlay extends StatefulWidget {
  const LaunchSplashOverlay({super.key, required this.child});

  final Widget child;

  @override
  State<LaunchSplashOverlay> createState() => _LaunchSplashOverlayState();
}

class _LaunchSplashOverlayState extends State<LaunchSplashOverlay>
    with SingleTickerProviderStateMixin {
  static const _duration = Duration(milliseconds: 2400);
  late final AnimationController _controller;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    if (AppConfig.skipLaunchSplash) {
      _done = true;
      return;
    }
    _controller = AnimationController(vsync: this, duration: _duration)
      ..addListener(() => setState(() {}))
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          setState(() => _done = true);
        }
      })
      ..forward();
  }

  @override
  void dispose() {
    if (!AppConfig.skipLaunchSplash) {
      _controller.dispose();
    }
    super.dispose();
  }

  double get _t => AppConfig.skipLaunchSplash ? 1 : _controller.value;

  double get _contentOpacity {
    if (_t <= 0.32) {
      return Curves.easeOut.transform(_t / 0.32);
    }
    return 1;
  }

  double get _coverOpacity {
    if (_t < 0.62) {
      return 1;
    }
    return 1 - Curves.easeInOut.transform((_t - 0.62) / 0.38);
  }

  @override
  Widget build(BuildContext context) {
    if (_done) {
      return widget.child;
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        IgnorePointer(
          child: Opacity(
            opacity: _coverOpacity.clamp(0, 1),
            child: ColoredBox(
              color: AppPalette.rose.background,
              child: Opacity(
                opacity: _contentOpacity.clamp(0, 1),
                child: const LaunchSplashView(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class LaunchSplashView extends StatelessWidget {
  const LaunchSplashView({super.key});

  @override
  Widget build(BuildContext context) {
    const palette = AppPalette.rose;
    return ColoredBox(
      color: palette.background,
      child: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            const MemoringMark(size: 220),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
              child: Text(
                AppConfig.copyrightLine,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'GowunBatang',
                  fontSize: 12,
                  color: palette.textMuted,
                  height: 1.4,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MemoringMark extends StatelessWidget {
  const MemoringMark({super.key, this.size = 220});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      AppConfig.logoAsset,
      width: size,
      filterQuality: FilterQuality.high,
      fit: BoxFit.contain,
    );
  }
}
