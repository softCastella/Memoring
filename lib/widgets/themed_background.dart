import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../catalog/catalog_store.dart';
import '../data/background_file_store.dart';
import '../models/appearance_settings.dart';
import '../theme/app_palette.dart';

Uint8List? appearancePhotoBytes(AppearanceSettings appearance) {
  final path = appearance.personalBackgroundPath;
  if (path != null && path.isNotEmpty) {
    final cached = BackgroundFileStore.current?.readSync(path);
    if (cached != null) {
      return cached;
    }
  }
  return _catalogBytes(appearance.catalogBackgroundId);
}

Uint8List? _catalogBytes(String? catalogBackgroundId) {
  if (catalogBackgroundId == null || catalogBackgroundId.isEmpty) {
    return null;
  }
  final slash = catalogBackgroundId.indexOf('/');
  if (slash <= 0 || slash >= catalogBackgroundId.length - 1) {
    return null;
  }
  final pack = CatalogStore.current?.packById(
    catalogBackgroundId.substring(0, slash),
  );
  if (pack == null) {
    return null;
  }
  final assetId = catalogBackgroundId.substring(slash + 1);
  for (final asset in pack.images) {
    if (asset.id != assetId || asset.base64Data.isEmpty) {
      continue;
    }
    try {
      return Uint8List.fromList(base64Decode(asset.base64Data));
    } catch (_) {
      return null;
    }
  }
  return null;
}

String appearanceImageTitle(AppearanceSettings appearance) {
  return CatalogStore.current
          ?.assetByCatalogId(appearance.catalogBackgroundId)
          ?.displayTitle ??
      '';
}

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
    final bytes = appearancePhotoBytes(appearance);
    if (bytes == null) {
      return const SizedBox.shrink();
    }
    Widget image = Image.memory(
      bytes,
      fit: BoxFit.cover,
      alignment: Alignment(appearance.offsetX, appearance.offsetY),
      width: double.infinity,
      height: double.infinity,
      gaplessPlayback: true,
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
