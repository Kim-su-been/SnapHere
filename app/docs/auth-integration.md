# Android 인증 API 연결 계약

디버그 빌드는 기본적으로 가짜 Google 계정과 메모리 기반 백엔드를 사용한다. 릴리스 빌드는 실제 구현을 선택하므로 API 설정이 없으면 명확한 설정 오류를 표시한다. 운영 빌드는 다음 값을 전달한다.

```powershell
flutter run --dart-define=USE_FAKE_AUTH=false `
  --dart-define=API_BASE_URL=https://api.example.com `
  --dart-define=GOOGLE_SERVER_CLIENT_ID=000000000000-example.apps.googleusercontent.com
```

Google Cloud/Firebase 콘솔에는 Android application ID `com.snaphere.snap_here`, 릴리스 SHA-1/SHA-256, Web OAuth client를 등록해야 한다. 백엔드는 앱에서 받은 Google ID 토큰의 서명, `aud`, `iss`, `exp`를 검증한 뒤 자체 access/refresh token을 발급한다.

## REST 엔드포인트

### `POST /v1/auth/google`

요청:

```json
{ "idToken": "google-openid-id-token" }
```

### `POST /v1/auth/refresh`

```json
{ "refreshToken": "refresh-token" }
```

### `POST /v1/profile`

`Authorization: Bearer <accessToken>` 헤더와 함께 전송한다.

```json
{
  "nickname": "여행토끼",
  "bio": "소개글 또는 null",
  "profileImagePath": null,
  "consents": {
    "termsVersion": "2026-09-01",
    "privacyVersion": "2026-09-01",
    "marketingVersion": null,
    "marketingAccepted": false,
    "acceptedAt": "2026-09-01T00:00:00.000Z"
  }
}
```

Google 로그인, 토큰 갱신, 프로필 저장 응답은 모두 다음 세션 형식을 사용한다.

```json
{
  "accessToken": "access-token",
  "refreshToken": "refresh-token",
  "isGuest": false,
  "user": {
    "id": "user-id",
    "email": "user@example.com",
    "displayName": "Google 표시 이름",
    "photoUrl": null,
    "nickname": null,
    "bio": null,
    "needsProfileSetup": true
  }
}
```

기존 회원은 `needsProfileSetup: false`, 신규 회원은 `true`를 반환한다.

### `POST /v1/auth/logout`

`Authorization: Bearer <accessToken>`을 사용하며 성공 시 `204` 또는 2xx를 반환한다.

### `DELETE /v1/account`

`Authorization: Bearer <accessToken>`을 사용한다. 계정, 법령상 보존 의무가 없는 개인정보, 이용자 게시물을 삭제한 뒤 `204` 또는 2xx를 반환한다. 앱은 성공 응답 후 Google 연결과 로컬 세션을 정리한다.

### `GET /v1/legal/{type}`

`type`은 `terms`, `privacy-consent`, `privacy-policy`, `marketing` 중 하나다.

```json
{
  "title": "서비스 이용약관",
  "version": "2026-09-01",
  "effectiveDate": "2026-09-01T00:00:00Z",
  "sections": [
    { "heading": "제1조 목적", "body": "검토 완료된 실제 문서 내용" }
  ]
}
```

출시 전에 운영 주체, 연락처, 개인정보 처리 위탁·국외 이전, 보유 기간, 계정 삭제 절차를 반영한 검토 완료 문서를 반환해야 한다. 현재 가짜 Repository의 `mock-1.0` 문서는 UI 개발용이며 출시 문서가 아니다.

## 교체 경계

- 화면: `presentation/`
- 인증 흐름과 세션 상태: `application/auth_controller.dart`
- 서버 계약: `domain/auth_repository.dart`
- 실제 HTTP 구현: `data/api_auth_repository.dart`
- 가짜 데이터: `data/fake_auth_repository.dart`
- 암호화 세션 저장: `data/session_store.dart`

백엔드가 위 계약을 구현하면 화면 코드는 변경하지 않는다.
