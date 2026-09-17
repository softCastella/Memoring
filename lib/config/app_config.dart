/// 앱 표시 이름과 1차 동작 스위치.
///
/// 네이티브 런처 이름은 AndroidManifest / Info.plist 에서도 맞춰 바꾼다.
class AppConfig {
  static const String appName = 'Memoring';

  /// true 이면 빈 저장소에 미리보기용 샘플을 넣는다.
  /// 실제 사용자 데이터와 섞이지 않도록 기본값은 false.
  static const bool useSampleData = false;
}
