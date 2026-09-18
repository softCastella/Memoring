import 'package:flutter/material.dart';

import '../models/app_theme_id.dart';

class AppPalette {
  const AppPalette({
    required this.id,
    required this.background,
    required this.surface,
    required this.text,
    required this.textMuted,
    required this.accent,
    required this.accentSoft,
    required this.checkBorder,
    required this.onAccent,
    required this.divider,
    required this.completedText,
    required this.highlight,
    required this.isDark,
  });

  final AppThemeId id;
  final Color background;
  final Color surface;
  final Color text;
  final Color textMuted;
  final Color accent;
  final Color accentSoft;
  final Color checkBorder;
  final Color onAccent;
  final Color divider;
  final Color completedText;
  final Color highlight;
  final bool isDark;

  static AppPalette of(AppThemeId id) {
    return switch (id) {
      AppThemeId.rose => rose,
      AppThemeId.sage => sage,
      AppThemeId.oat => oat,
      AppThemeId.night => night,
    };
  }

  static const rose = AppPalette(
    id: AppThemeId.rose,
    background: Color(0xFFF7F3EE),
    surface: Color(0xFFFBF8F4),
    text: Color(0xFF5A463E),
    textMuted: Color(0xFFB4A296),
    accent: Color(0xFFC9A4A6),
    accentSoft: Color(0xFFF0E4E1),
    checkBorder: Color(0xFFE2D6CE),
    onAccent: Color(0xFFFFFBF8),
    divider: Color(0xFFEDE6E0),
    completedText: Color(0xFF8D7A72),
    highlight: Color(0xFFF3E6E3),
    isDark: false,
  );

  static const sage = AppPalette(
    id: AppThemeId.sage,
    background: Color(0xFFF3F4EF),
    surface: Color(0xFFFBFCF9),
    text: Color(0xFF3E4940),
    textMuted: Color(0xFF8A9588),
    accent: Color(0xFF8A9A84),
    accentSoft: Color(0xFFD8E2D4),
    checkBorder: Color(0xFFC5CFC0),
    onAccent: Color(0xFFF7FBF6),
    divider: Color(0xFFDCE3D8),
    completedText: Color(0xFF8A9588),
    highlight: Color(0xFFE4EBE3),
    isDark: false,
  );

  static const oat = AppPalette(
    id: AppThemeId.oat,
    background: Color(0xFFF6F1E7),
    surface: Color(0xFFFFFBF4),
    text: Color(0xFF5C4C3C),
    textMuted: Color(0xFFA39482),
    accent: Color(0xFFC4A574),
    accentSoft: Color(0xFFE9DCC8),
    checkBorder: Color(0xFFD8CBB8),
    onAccent: Color(0xFFFFFBF6),
    divider: Color(0xFFE7DCCB),
    completedText: Color(0xFFA89480),
    highlight: Color(0xFFF0E8DC),
    isDark: false,
  );

  static const night = AppPalette(
    id: AppThemeId.night,
    background: Color(0xFF1F1B1A),
    surface: Color(0xFF2C2624),
    text: Color(0xFFF2E8DF),
    textMuted: Color(0xFFB5A69A),
    accent: Color(0xFFD4A5A5),
    accentSoft: Color(0xFF4A3A3A),
    checkBorder: Color(0xFF6B5C56),
    onAccent: Color(0xFF2A2220),
    divider: Color(0xFF3F3734),
    completedText: Color(0xFF9A8B82),
    highlight: Color(0xFF3A3030),
    isDark: true,
  );

  /// 사진 배경이 밝으면 글자를 어둡게, 어두우면 글자를 밝게 맞춘다.
  AppPalette contrastedForPhoto(bool? photoIsBright) {
    if (photoIsBright == null) {
      return this;
    }
    if (photoIsBright) {
      return AppPalette(
        id: id,
        background: background,
        surface: surface,
        text: const Color(0xFF241A16),
        textMuted: const Color(0xFF3F312B),
        accent: accent,
        accentSoft: accentSoft,
        checkBorder: checkBorder,
        onAccent: onAccent,
        divider: divider,
        completedText: const Color(0xFF4A3A34),
        highlight: highlight,
        isDark: false,
      );
    }
    return AppPalette(
      id: id,
      background: background,
      surface: surface,
      text: const Color(0xFFF6EEE6),
      textMuted: const Color(0xFFE2D2C4),
      accent: accent,
      accentSoft: accentSoft,
      checkBorder: checkBorder,
      onAccent: onAccent,
      divider: divider,
      completedText: const Color(0xFFD4C4B6),
      highlight: highlight,
      isDark: true,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is AppPalette &&
        other.id == id &&
        other.background == background &&
        other.surface == surface &&
        other.text == text &&
        other.textMuted == textMuted &&
        other.accent == accent &&
        other.accentSoft == accentSoft &&
        other.checkBorder == checkBorder &&
        other.onAccent == onAccent &&
        other.divider == divider &&
        other.completedText == completedText &&
        other.highlight == highlight &&
        other.isDark == isDark;
  }

  @override
  int get hashCode => Object.hash(
    id,
    background,
    surface,
    text,
    textMuted,
    accent,
    accentSoft,
    checkBorder,
    onAccent,
    divider,
    completedText,
    highlight,
    isDark,
  );
}
