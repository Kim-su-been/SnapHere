# Android 인증 API 연결

앱은 기본적으로 실제 로컬 API를 사용한다. 가짜 인증 화면이 필요한 UI 테스트나 데모 실행에서는 `--dart-define=USE_FAKE_AUTH=true`를 전달한다.

```powershell
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080 `
  --dart-define=GOOGLE_SERVER_CLIENT_ID=000000000000-example.apps.googleusercontent.com
```

Android 에뮬레이터에서 호스트 PC의 백엔드에 접근할 때는 `10.0.2.2`를 사용한다. Windows·iOS 시뮬레이터 등에서 생략하면 기본값은 `http://localhost:8080`이다.

## 현재 백엔드 계약

- `POST /api/v1/auth/google`: `idToken`, 앱이 안전 저장소에 생성한 `deviceId`, `platform`을 보낸다.
- `POST /api/v1/auth/refresh`: `refreshToken`, 동일한 `deviceId`를 보내 토큰을 회전한다.
- `POST /api/v1/auth/onboarding`: Bearer 토큰과 `nickname`, `termsVersion`, `locale`을 보낸다.
- `POST /api/v1/auth/logout`: 현재 기기의 세션을 종료한다.
- `GET /api/v1/me`: 로그인 사용자의 공개 프로필과 통계를 조회한다.
- `POST /api/v1/me/deletion`: `contentAction`을 `KEEP_ANONYMIZED` 또는 `DELETE_ALL`로 보내 30일 유예 탈퇴를 요청한다.

서버의 인증 응답은 공통 `ApiResponse.data` 안에 `tokens`, `user`, `onboardingRequired`를 담는다. 앱의 `ApiAuthRepository`가 이를 로컬 `AuthSession`으로 변환하고 `flutter_secure_storage`에 저장한다.

현재 백엔드에는 법적 문서 조회 API가 없으므로 약관 화면은 개발용 `FakeLegalDocumentRepository`를 계속 사용한다. 출시 전에는 운영 주체, 연락처, 처리 위탁·국외 이전, 보유 기간과 탈퇴 절차를 반영한 검토 완료 문서 공급 경로가 필요하다.

## 교체 경계

- 화면: `presentation/`
- 인증 흐름과 세션 상태: `application/auth_controller.dart`
- 서버 계약: `domain/auth_repository.dart`
- 실제 HTTP 구현: `data/api_auth_repository.dart`
- 암호화 세션·기기 ID 저장: `data/session_store.dart`, `flutter_secure_storage`
