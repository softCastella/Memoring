/// 앱 표시 이름과 1차 동작 스위치.
///
/// 네이티브 런처 이름은 AndroidManifest / Info.plist 에서도 맞춰 바꾼다.
class AppConfig {
  static const String appName = 'Memoring';
  static const String copyrightLine =
      '© 2026 Tyche Loop. All rights reserved.';
  static const String logoAsset = 'asset/Logo_Memoring.png';

  /// 위젯 테스트에서 기동 스플래시를 건너뛴다.
  static const bool skipLaunchSplash = bool.fromEnvironment('FLUTTER_TEST');

  /// true 이면 빈 저장소에 미리보기용 샘플을 넣는다.
  /// 실제 사용자 데이터와 섞이지 않도록 기본값은 false.
  /// 미리보기: `--dart-define=USE_SAMPLE_DATA=true`
  static const bool useSampleData = bool.fromEnvironment('USE_SAMPLE_DATA');

  /// 로컬 관리자 웹. 앱 스토어는 여기 공개 팩을 가져온다.
  static const String adminOrigin = String.fromEnvironment(
    'ADMIN_ORIGIN',
    defaultValue: 'http://localhost:8081',
  );

  /// 로컬 테스트 카탈로그. 관리자와 앱 스토어가 이 주소를 공유한다.
  /// 폰에서 PC를 보려면 `--dart-define=CATALOG_URL=http://PC주소:8090`
  /// USB 연결 시 `adb reverse tcp:8090 tcp:8090` 이면 localhost로도 된다.
  static const String catalogUrl = String.fromEnvironment(
    'CATALOG_URL',
    defaultValue: 'http://localhost:8090',
  );

  /// 쉼표로 나눈 추가 주소. 폰이 localhost에 실패하면 여기로 다시 시도한다.
  static const String catalogFallbacks = String.fromEnvironment(
    'CATALOG_FALLBACKS',
    defaultValue: 'http://192.168.0.41:8090',
  );
}
