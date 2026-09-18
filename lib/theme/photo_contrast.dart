import 'dart:typed_data';
import 'dart:ui';

import '../models/appearance_settings.dart';
import '../widgets/themed_background.dart';
import 'app_palette.dart';

const photoBrightnessThreshold = 0.45;

double luminanceFromRgba(Uint8List rgba) {
  if (rgba.length < 4) {
    return 0;
  }
  var sum = 0.0;
  var count = 0;
  for (var i = 0; i + 3 < rgba.length; i += 4) {
    final r = rgba[i] / 255;
    final g = rgba[i + 1] / 255;
    final b = rgba[i + 2] / 255;
    sum += 0.2126 * r + 0.7152 * g + 0.0722 * b;
    count += 1;
  }
  return count == 0 ? 0 : sum / count;
}

bool isBrightPhoto(double luminance) => luminance >= photoBrightnessThreshold;

class PhotoContrast {
  PhotoContrast._();

  static final Map<String, bool> _cache = {};

  static String keyFor(AppearanceSettings appearance) {
    return '${appearance.personalBackgroundPath ?? ''}|${appearance.catalogBackgroundId ?? ''}';
  }

  static bool? cached(AppearanceSettings appearance) {
    if (!appearance.hasPersonalBackground) {
      return null;
    }
    return _cache[keyFor(appearance)];
  }

  static AppPalette paletteFor(
    AppearanceSettings appearance, {
    bool? photoIsBright,
  }) {
    final base = AppPalette.of(appearance.themeId);
    if (!appearance.hasPersonalBackground) {
      return base;
    }
    return base.contrastedForPhoto(photoIsBright ?? cached(appearance) ?? true);
  }

  static Future<bool?> remember(
    AppearanceSettings appearance,
    Uint8List? bytes,
  ) async {
    if (!appearance.hasPersonalBackground || bytes == null || bytes.isEmpty) {
      return null;
    }
    final key = keyFor(appearance);
    final cachedValue = _cache[key];
    if (cachedValue != null) {
      return cachedValue;
    }
    final luminance = await averageLuminance(bytes);
    final bright = isBrightPhoto(luminance ?? 1);
    _cache[key] = bright;
    return bright;
  }

  static Future<double?> averageLuminance(Uint8List bytes) async {
    try {
      final codec = await instantiateImageCodec(
        bytes,
        targetWidth: 48,
        targetHeight: 48,
      );
      final frame = await codec.getNextFrame();
      final image = frame.image;
      final data = await image.toByteData(format: ImageByteFormat.rawRgba);
      image.dispose();
      if (data == null) {
        return null;
      }
      return luminanceFromRgba(data.buffer.asUint8List());
    } catch (_) {
      return null;
    }
  }
}
