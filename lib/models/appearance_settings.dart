import 'app_theme_id.dart';

class AppearanceSettings {
  const AppearanceSettings({
    required this.themeId,
    this.personalBackgroundPath,
    this.catalogBackgroundId,
    this.scale = 1.0,
    this.offsetX = 0.0,
    this.offsetY = 0.0,
    this.blur = 0.0,
    this.cardOpacity = 1.0,
  });

  factory AppearanceSettings.defaults() =>
      const AppearanceSettings(themeId: AppThemeId.rose);

  final AppThemeId themeId;

  /// 앱 문서 폴더에 복사된 개인 배경. 갤러리 임시 경로를 쓰지 않는다.
  final String? personalBackgroundPath;

  /// 이후 배경 스토어 팩 연동용. 1차에서는 사용하지 않는다.
  final String? catalogBackgroundId;

  final double scale;
  final double offsetX;
  final double offsetY;
  final double blur;
  final double cardOpacity;

  bool get hasPersonalBackground =>
      (personalBackgroundPath != null && personalBackgroundPath!.isNotEmpty) ||
      (catalogBackgroundId != null && catalogBackgroundId!.isNotEmpty);

  AppearanceSettings copyWith({
    AppThemeId? themeId,
    String? personalBackgroundPath,
    String? catalogBackgroundId,
    double? scale,
    double? offsetX,
    double? offsetY,
    double? blur,
    double? cardOpacity,
    bool clearPersonalBackground = false,
    bool clearCatalogBackground = false,
  }) {
    return AppearanceSettings(
      themeId: themeId ?? this.themeId,
      personalBackgroundPath: clearPersonalBackground
          ? null
          : personalBackgroundPath ?? this.personalBackgroundPath,
      catalogBackgroundId: clearCatalogBackground
          ? null
          : catalogBackgroundId ?? this.catalogBackgroundId,
      scale: scale ?? this.scale,
      offsetX: offsetX ?? this.offsetX,
      offsetY: offsetY ?? this.offsetY,
      blur: blur ?? this.blur,
      cardOpacity: cardOpacity ?? this.cardOpacity,
    );
  }

  Map<String, dynamic> toJson() => {
    'themeId': themeId.storageName,
    'personalBackgroundPath': personalBackgroundPath,
    'catalogBackgroundId': catalogBackgroundId,
    'scale': scale,
    'offsetX': offsetX,
    'offsetY': offsetY,
    'blur': blur,
    'cardOpacity': cardOpacity,
  };

  factory AppearanceSettings.fromJson(Map<String, dynamic> json) {
    return AppearanceSettings(
      themeId: AppThemeId.fromStorage(json['themeId'] as String? ?? 'rose'),
      personalBackgroundPath: json['personalBackgroundPath'] as String?,
      catalogBackgroundId: json['catalogBackgroundId'] as String?,
      scale: (json['scale'] as num?)?.toDouble() ?? 1.0,
      offsetX: (json['offsetX'] as num?)?.toDouble() ?? 0.0,
      offsetY: (json['offsetY'] as num?)?.toDouble() ?? 0.0,
      blur: (json['blur'] as num?)?.toDouble() ?? 0.0,
      cardOpacity: (json['cardOpacity'] as num?)?.toDouble() ?? 1.0,
    );
  }
}
