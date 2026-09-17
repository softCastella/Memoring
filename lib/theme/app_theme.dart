import 'package:flutter/material.dart';

import '../models/appearance_settings.dart';
import 'app_palette.dart';

class ThemeScope extends InheritedWidget {
  const ThemeScope({
    super.key,
    required this.palette,
    required this.appearance,
    required super.child,
  });

  final AppPalette palette;
  final AppearanceSettings appearance;

  static ThemeScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ThemeScope>();
    assert(scope != null, 'ThemeScope not found');
    return scope!;
  }

  Color get cardColor {
    if (!appearance.hasPersonalBackground) {
      return palette.surface;
    }
    final opacity = appearance.cardOpacity.clamp(0.62, 1.0);
    return palette.surface.withValues(alpha: opacity);
  }

  @override
  bool updateShouldNotify(ThemeScope oldWidget) {
    return palette != oldWidget.palette || appearance != oldWidget.appearance;
  }
}

ThemeData buildThemeData(AppPalette palette) {
  final brightness = palette.isDark ? Brightness.dark : Brightness.light;
  final textTheme = _textTheme(palette);

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    fontFamily: 'GowunBatang',
    scaffoldBackgroundColor: Colors.transparent,
    colorScheme: ColorScheme(
      brightness: brightness,
      primary: palette.accent,
      onPrimary: palette.onAccent,
      secondary: palette.accentSoft,
      onSecondary: palette.text,
      error: const Color(0xFFB46868),
      onError: Colors.white,
      surface: palette.surface,
      onSurface: palette.text,
    ),
    textTheme: textTheme,
    iconTheme: IconThemeData(color: palette.text, size: 22),
    dividerColor: palette.divider,
    splashFactory: InkRipple.splashFactory,
    appBarTheme: AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: palette.text,
      titleTextStyle: textTheme.titleMedium,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: palette.accent,
      foregroundColor: palette.onAccent,
      elevation: 0,
      focusElevation: 0,
      hoverElevation: 0,
      highlightElevation: 0,
      shape: const CircleBorder(),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: palette.surface.withValues(alpha: 0.96),
      elevation: 0,
      height: 68,
      indicatorColor: palette.accentSoft,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return textTheme.labelLarge?.copyWith(
          color: selected ? palette.accent : palette.textMuted,
          fontWeight: FontWeight.w600,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          color: selected ? palette.accent : palette.textMuted,
          size: 22,
        );
      }),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: palette.accent,
      inactiveTrackColor: palette.accentSoft,
      thumbColor: palette.accent,
      overlayColor: palette.accent.withValues(alpha: 0.12),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: palette.background.withValues(alpha: palette.isDark ? 0.4 : 0.7),
      hintStyle: textTheme.bodyMedium?.copyWith(color: palette.textMuted),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: palette.divider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: palette.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: palette.accent, width: 1.4),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: palette.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: palette.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
    ),
    datePickerTheme: DatePickerThemeData(
      backgroundColor: palette.surface,
      headerForegroundColor: palette.text,
      dayForegroundColor: WidgetStatePropertyAll(palette.text),
      todayForegroundColor: WidgetStatePropertyAll(palette.accent),
      todayBorder: BorderSide(color: palette.accent),
    ),
  );
}

TextTheme _textTheme(AppPalette palette) {
  TextStyle base({
    required double size,
    FontWeight weight = FontWeight.w400,
    Color? color,
    double height = 1.4,
  }) {
    return TextStyle(
      fontFamily: 'GowunBatang',
      fontSize: size,
      fontWeight: weight,
      color: color ?? palette.text,
      height: height,
      letterSpacing: 0,
    );
  }

  return TextTheme(
    displaySmall: base(size: 32, weight: FontWeight.w700, height: 1.3),
    headlineSmall: base(size: 22, weight: FontWeight.w700),
    titleLarge: base(size: 20, weight: FontWeight.w700),
    titleMedium: base(size: 17, weight: FontWeight.w700),
    titleSmall: base(size: 15, weight: FontWeight.w700),
    bodyLarge: base(size: 16, height: 1.5),
    bodyMedium: base(size: 15, height: 1.5),
    bodySmall: base(size: 13, color: palette.textMuted, height: 1.45),
    labelLarge: base(size: 14, weight: FontWeight.w700),
    labelMedium: base(size: 12, color: palette.textMuted),
  );
}
