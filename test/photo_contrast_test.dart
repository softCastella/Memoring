import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memoring/models/app_theme_id.dart';
import 'package:memoring/models/appearance_settings.dart';
import 'package:memoring/theme/app_palette.dart';
import 'package:memoring/theme/photo_contrast.dart';

void main() {
  test('white pixels count as a bright photo', () {
    final rgba = Uint8List.fromList([
      255, 255, 255, 255,
      250, 248, 240, 255,
    ]);
    final luminance = luminanceFromRgba(rgba);
    expect(luminance, greaterThan(0.9));
    expect(isBrightPhoto(luminance), isTrue);
  });

  test('black pixels count as a dark photo', () {
    final rgba = Uint8List.fromList([
      8, 6, 4, 255,
      12, 10, 9, 255,
    ]);
    final luminance = luminanceFromRgba(rgba);
    expect(luminance, lessThan(0.1));
    expect(isBrightPhoto(luminance), isFalse);
  });

  test('bright photos darken rose text so titles stay readable', () {
    final adapted = AppPalette.rose.contrastedForPhoto(true);
    expect(adapted.text.computeLuminance(), lessThan(AppPalette.rose.text.computeLuminance()));
    expect(
      adapted.textMuted.computeLuminance(),
      lessThan(AppPalette.rose.textMuted.computeLuminance()),
    );
    expect(adapted.isDark, isFalse);
    expect(adapted.accent, AppPalette.rose.accent);
  });

  test('dark photos lighten night text so titles stay readable', () {
    final adapted = AppPalette.night.contrastedForPhoto(false);
    expect(adapted.text.computeLuminance(), greaterThan(0.7));
    expect(adapted.isDark, isTrue);
  });

  test('photo-aware palette assumes bright until measured', () {
    const appearance = AppearanceSettings(
      themeId: AppThemeId.night,
      catalogBackgroundId: 'pack/sky',
    );
    final palette = PhotoContrast.paletteFor(appearance);
    expect(palette.text.computeLuminance(), lessThan(0.2));
    expect(palette.isDark, isFalse);
  });
}
