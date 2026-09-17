import 'background_pack.dart';

class PaidContentLocked implements Exception {
  const PaidContentLocked();

  @override
  String toString() =>
      '유료 배경은 스토어 결제와 서버 확인 후에만 열 수 있어요.';
}

/// 유료 콘텐츠 권한.
///
/// 클라이언트에 저장된 구매 여부만으로 유료 팩을 열지 않는다.
/// 서버 검증이 연결되기 전에는 무료 팩만 허용한다.
class EntitlementVerifier {
  const EntitlementVerifier();

  Future<bool> canAccess(BackgroundPack pack) async {
    return pack.isFree;
  }
}
