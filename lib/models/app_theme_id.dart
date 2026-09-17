enum AppThemeId {
  rose,
  sage,
  oat,
  night;

  String get storageName => name;

  String get label => switch (this) {
    AppThemeId.rose => '로즈',
    AppThemeId.sage => '세이지',
    AppThemeId.oat => '오트',
    AppThemeId.night => '나이트',
  };

  static AppThemeId fromStorage(String value) {
    return AppThemeId.values.firstWhere(
      (item) => item.storageName == value,
      orElse: () => AppThemeId.rose,
    );
  }
}
