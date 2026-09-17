import 'package:shared_preferences/shared_preferences.dart';

/// 관리자 인증. 비밀번호는 소스에 넣지 않는다.
///
/// * `--dart-define=ADMIN_PASSWORD=...` 가 있으면 그 값을 사용한다.
/// * 없으면 이 브라우저/기기에만 저장되는 개발용 로컬 비밀번호를 쓴다.
/// 실제 운영 인증·서버 검증은 이후 단계에서 연결한다.
class AdminAuth {
  AdminAuth({this.preferences});

  static const _storageKey = 'memoring.admin.local_password';
  static const definedPassword = String.fromEnvironment('ADMIN_PASSWORD');

  SharedPreferences? preferences;
  bool unlocked = false;

  bool get hasDefinedPassword => definedPassword.isNotEmpty;

  Future<void> load() async {
    preferences ??= await SharedPreferences.getInstance();
  }

  bool get hasLocalPassword {
    return (preferences?.getString(_storageKey) ?? '').isNotEmpty;
  }

  bool get needsSetup => !hasDefinedPassword && !hasLocalPassword;

  Future<String> unlock(String password) async {
    await load();
    if (password.trim().isEmpty) {
      return '비밀번호를 입력해 주세요.';
    }
    if (hasDefinedPassword) {
      if (password == definedPassword) {
        unlocked = true;
        return '';
      }
      return '비밀번호가 올바르지 않습니다.';
    }
    final stored = preferences!.getString(_storageKey);
    if (stored == null || stored.isEmpty) {
      await preferences!.setString(_storageKey, password);
      unlocked = true;
      return '';
    }
    if (stored == password) {
      unlocked = true;
      return '';
    }
    return '비밀번호가 올바르지 않습니다.';
  }

  void lock() {
    unlocked = false;
  }
}
