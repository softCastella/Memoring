# Memoring 진행 기록

## 현재 상태
1차 앱(오늘/기록/꾸미기/로컬 저장)과 운영자용 **로컬 배경 관리 웹**까지 구현했습니다.
기본 테마는 사진 없는 로즈 시안(웜 아이보리, 브라운 글자, 더스티 로즈)입니다.

## 구현된 것
- Flutter Android 우선 앱. 앱 이름은 `lib/config/app_config.dart`의 `AppConfig.appName`
- 오늘: 주간 날짜 줄, 분류 탭, 항목 CRUD/완료, 날짜별 루틴 완료
- 기록: 지침·차분·평온·설렘·기쁨, 한 줄 메모, 저장, 지난 기록
- 꾸미기: 로즈/세이지/오트/나이트, 개인 배경, 미리보기 후 적용, 기본 복원
- 설정: 꾸미기 진입, 기본 디자인 복원
- 로컬 JSON 저장. 첫 실행 데이터는 비어 있음
- 관리자 웹 `lib/admin_main.dart`: 배경팩 생성/수정, 이미지 등록, 순서, 무료·유료(스토어 상품 ID), 비공개·공개
- 관리자 비밀번호는 코드에 없음. 개발 모드에서 브라우저/기기에만 저장하거나 `--dart-define=ADMIN_PASSWORD=`

## 실행
앱:

```bash
flutter run
```

Android SDK cmdline-tools가 없으면 Chrome/Windows 기기만 잡힐 수 있습니다.

관리자 배경 관리:

```bash
flutter run -d chrome -t lib/admin_main.dart
```

## 아직 안 한 것
- 실제 Android 홈 화면 위젯 (앱 안 미리보기 ≠ 홈 위젯)
- 앱 안 배경 스토어 / 내 배경 / 결제 / 구매 복원
- 외부 서버, 공개 배포된 관리자 웹, 운영 인증
- 사용자 개인 할 일·감정 조회 (의도적으로 없음)

## 다음 단계에 필요한 외부 설정
- Android cmdline-tools / 에뮬레이터 또는 실기기
- 홈 위젯: Android Glance 또는 home_widget + 네이티브 작업
- 배경 스토어: 호스팅, 구매 검증 서버, Play 상품 ID
- 관리자 웹 운영 배포 시 실제 인증과 이미지 스토리지

## 검증
`flutter analyze`, `flutter test`로 확인합니다. 갤러리 선택·실제 기기 키보드는 에뮬레이터가 없어 이 환경에서 실행하지 못했습니다.
