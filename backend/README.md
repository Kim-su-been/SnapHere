# SnapHere API (backend)

Spring Boot 3.5 · Java 21 · Gradle (Kotlin DSL) 기반 백엔드 API 서버.

명세는 저장소 문서를 정본으로 삼는다.

| 문서 | 위치 |
| --- | --- |
| 요구사항 명세서 | `docs/01-requirements-spec.md` |
| 기능 명세서 | `docs/02-feature-spec.md` |
| API 명세서 | `docs/03-api-spec.md` |
| ERD 참조 | `docs/05-erd-reference.md` |
| 명세 변경 이력 | `docs/08-spec-changelog.md` |
| 커밋·브랜치 규칙 | `docs/commit-convention.md` |
| 스프레드시트 원본 | `docs/specs/` |

## 처음 받은 뒤 한 번

Gradle 래퍼는 저장소에 넣지 않았다. 각자 한 번 만든다.

```bash
cd backend
gradle wrapper --gradle-version 8.14
```

이후로는 래퍼로 실행한다.

```bash
./gradlew build      # 컴파일 + 테스트
./gradlew bootRun    # 로컬 실행 (기본 8080)
```

Gradle 이 없으면 Docker 로도 된다.

```bash
docker run --rm -v "$(pwd):/app" -v snaphere-gradle:/home/gradle/.gradle -w /app \
  gradle:8.14-jdk21 gradle build --no-daemon
```

## 폴더 구조

```text
backend/src/main/java/com/snaphere/api/
├── SnapHereApplication.java
├── common/
│   ├── error/      # 에러 코드 체계와 전역 예외 처리 (SYS-002)
│   ├── security/   # 현재 로그인 사용자 조회 (AUTH-011)
│   └── web/        # 공통 응답 봉투·커서 페이징·요청 추적 (SYS-001, SYS-003, SYS-016)
├── auth/           # 구글 로그인·JWT·리프레시 토큰 회전 (AUTH-001~011, AUTH-014)
├── media/          # 업로드 URL 발급 (PST-013~015)
├── place/          # 장소·이벤트 조회 포트 (PLC-*, EVT-*)
└── post/           # 게시글 — 현재는 등급 판정만 (PST-022~028)
```

## 실행 전 필요한 값

PostgreSQL 16 데이터베이스와 아래 환경 변수가 필요하다. `SNAPHERE_JWT_SECRET` 은 32바이트 이상
무작위 값으로 설정하고, 모바일 앱의 Google OAuth 클라이언트 ID 를 쓴다.

```text
DB_URL=jdbc:postgresql://localhost:5432/snaphere
DB_USERNAME=snaphere
DB_PASSWORD=...
GOOGLE_OAUTH_CLIENT_ID=...
SNAPHERE_JWT_SECRET=...
SNAPHERE_TERMS_VERSION=2026-08-01
```

S3 를 쓸 때만 추가한다. 자격증명은 설정 파일에 두지 않고 SDK 기본 체인을 사용한다.

```text
MEDIA_PROVIDER=s3
MEDIA_S3_BUCKET=snaphere-media
MEDIA_S3_REGION=ap-northeast-2
MEDIA_PUBLIC_BASE_URL=https://cdn.example.com
```

## 지금 구현된 것

### 공통

| 클래스 | 역할 | 요구사항 |
| --- | --- | --- |
| `common.web.ApiResponse` | 성공·실패 공통 응답 봉투 | `SYS-001` |
| `common.web.CursorPage` | 커서 페이징 응답 | `SYS-003`, `SYS-004`, `CMU-010` |
| `common.web.TraceIdFilter` | `X-Trace-Id` 수용·생성, MDC 주입 | `SYS-016` |
| `common.error.ErrorCode` | 코드 기반 에러 분기 | `SYS-002` |
| `common.error.ErrorBody` | 실패 봉투 본문 (`violations`, `retryAfterSec`) | `SYS-002` |
| `common.error.GlobalExceptionHandler` | 모든 예외를 실패 봉투로 변환 | `SYS-001`, `SYS-002` |

### 엔드포인트

| API ID | 메서드 · 경로 | 기능 명세 | 요구사항 |
| --- | --- | --- | --- |
| `API-AUTH-001`~`005` | `/api/v1/auth/*` | 9.1 로그인 · 9.2 온보딩 | `AUTH-001`~`AUTH-011`, `AUTH-014` |
| `API-PST-001` | `POST /api/v1/media/presigned-urls` | 2.3 사진·캡션·태그 > 업로드 실행 | `PST-013`~`PST-015`, `USER-004`, `SYS-020` |
| `API-PST-002` | `POST /api/v1/posts/tier-preview` | 2.2 위치 확인 > 등급 미리보기 | `PST-022`~`PST-028`, `PST-046`~`PST-049` |

### 위치 신뢰 등급 (`PST-022`~`PST-026`)

판정 기준은 세 가지뿐이고 순서가 정해져 있다. `post.tier.TierPolicy` 한 곳에만 규칙이 있으며,
미리보기(`API-PST-002`)와 게시글 등록(`API-PST-003`)이 같은 클래스를 쓴다.

| 등급 | 조건 | 랭킹 가중치 | 뱃지 | 방문 기록 | 히트맵 |
| --- | --- | --- | --- | --- | --- |
| `HIGH` 높음 | 카메라 촬영 후 10분 이내 + 인증 반경 안 | 3.0 | ✅ | ✅ | ✅ |
| `MEDIUM` 보통 | 촬영 후 30일 이내 + 인증 반경 안 | 1.8 | ✅ | ✅ | ✅ |
| `LOW` 낮음 | 촬영 좌표 없음 / 반경 밖 / 30일 경과 | 0.5 | ❌ | ❌ | ❌ |

낮음도 게시와 랭킹 반영은 허용한다. 0점을 주면 EXIF 가 없는 기기 사용자가 전부 배제된다 (`PST-025`).

**인증 반경 우선순위** (`PLC-022`, `EVT-023`) — 이벤트별 값 → 그 지역 기본값 → 2,000m.
일반 게시글은 장소에 설정된 값(관광지 500m / 사용자 장소 100m)을 쓴다.

## 로컬에서 호출해 보기

`Authorization: Bearer {accessToken}` 로 호출한다. 토큰은 `POST /api/v1/auth/google` 로 받는다.

```bash
# 업로드 URL 발급
curl -X POST http://localhost:8080/api/v1/media/presigned-urls \
  -H 'Content-Type: application/json' -H "Authorization: Bearer $TOKEN" \
  -d '{"purpose":"POST_IMAGE","files":[{"mimeType":"image/jpeg","sizeBytes":1048576}]}'

# 카메라로 방금 찍고 반경 안 -> HIGH
curl -X POST http://localhost:8080/api/v1/posts/tier-preview \
  -H 'Content-Type: application/json' -H "Authorization: Bearer $TOKEN" \
  -d '{"placeId":1,"source":"CAMERA","takenAt":"2026-09-02T12:00:00+09:00","lat":37.5796,"lng":126.9770}'

# 촬영 좌표가 없으면 -> LOW (improvementHints 로 올리는 방법을 알려준다)
curl -X POST http://localhost:8080/api/v1/posts/tier-preview \
  -H 'Content-Type: application/json' -H "Authorization: Bearer $TOKEN" \
  -d '{"placeId":1,"source":"ALBUM"}'
```

`snaphere.stub-data=true` 일 때 `placeId` 1 = 관광지(경복궁 좌표, 반경 500m), 2 = 사용자 장소(반경 100m),
3 = 좌표 없는 장소, 4 = 축제 장소. `eventId` 1 = 지역 기본값(2,500m), 2 = 이벤트별 값(3,000m).

## 아직 없는 것

- 게시글 도메인 나머지 (`PST-001`~`PST-012`, `PST-016`~`PST-021`, `PST-029`~`PST-045`) — `docs/commit-convention.md` 의 분할 계획 참고
- 장소·이벤트 테이블. 지금은 `place/stub/StubPlaceData` 의 고정 데이터를 읽는다
- 판정 근거 저장. 지금은 로그로만 남고 `tier_logs` 테이블이 생기면 `TierDecisionLogger` 구현을 교체한다 (`PST-028`)
