/// 앱 표시 이름과 1차 동작 스위치.
///
/// 네이티브 런처 이름은 AndroidManifest / Info.plist 에서도 맞춰 바꾼다.
class AppConfig {
  static const String appName = 'Memoring';

  /// true 이면 빈 저장소에 미리보기용 샘플을 넣는다.
  /// 실제 사용자 데이터와 섞이지 않도록 기본값은 false.
  /// 미리보기: `--dart-define=USE_SAMPLE_DATA=true`
  static const bool useSampleData = bool.fromEnvironment('USE_SAMPLE_DATA');

  /// 로컬 관리자 웹. 앱 스토어는 여기 공개 팩을 가져온다.
  static const String adminOrigin = String.fromEnvironment(
    'ADMIN_ORIGIN',
    defaultValue: 'http://localhost:8081',
  );

  /// 앱 웹 주소. 관리자 브릿지가 카탈로그를 보낼 대상.
  static const String appOrigin = String.fromEnvironment(
    'APP_ORIGIN',
    defaultValue: 'http://localhost:8084',
  );
}
