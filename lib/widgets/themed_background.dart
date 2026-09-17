import 'dart:ui';

import 'package:flutter/material.dart';

import '../data/background_file_store.dart';
import '../models/appearance_settings.dart';
import '../theme/app_palette.dart';

class ThemedBackground extends StatelessWidget {
  const ThemedBackground({
    super.key,
    required this.palette,
    required this.appearance,
    required this.child,
  });

  final AppPalette palette;
  final AppearanceSettings appearance;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: palette.background),
        if (appearance.hasPersonalBackground)
          _PhotoLayer(palette: palette, appearance: appearance),
        child,
      ],
    );
  }
}

class _PhotoLayer extends StatelessWidget {
  const _PhotoLayer({required this.palette, required this.appearance});

  final AppPalette palette;
  final AppearanceSettings appearance;

  @override
  Widget build(BuildContext context) {
    final bytes = BackgroundFileStore.current?.readSync(
      appearance.personalBackgroundPath!,
    );
    if (bytes == null) {
      return const SizedBox.shrink();
    }
    Widget image = Image.memory(
      bytes,
      fit: BoxFit.cover,
      alignment: Alignment(appearance.offsetX, appearance.offsetY),
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (context, error, stackTrace) {
        return const SizedBox.shrink();
      },
    );

    if (appearance.scale != 1.0) {
      image = Transform.scale(scale: appearance.scale, child: image);
    }
    if (appearance.blur > 0.2) {
      image = ImageFiltered(
        imageFilter: ImageFilter.blur(
          sigmaX: appearance.blur,
          sigmaY: appearance.blur,
        ),
        child: image,
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRect(child: image),
        ColoredBox(color: palette.background.withValues(alpha: 0.18)),
      ],
    );
  }
}
