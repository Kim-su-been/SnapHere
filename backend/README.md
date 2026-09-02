# SnapHere API (backend)

Spring Boot 3.5 · Java 21 · Gradle (Kotlin DSL) 기반 백엔드 API 서버.

명세는 저장소 문서를 정본으로 삼는다.

| 문서 | 위치 |
| --- | --- |
| 요구사항 · 기능 명세서 v1.1.3 | `docs/specs/snaphere-requirements-spec-v1.1.3.xlsx` |
| API 명세서 · ERD v1.1.3 | `docs/specs/snaphere-api-spec-v1.1.3.xlsx` |
| 데이터 설계 (DBML) v1.1.3 | `docs/db-schema.dbml` |
| 명세 변경 이력 | `docs/spec-changelog.md` |
| 커밋·브랜치 규칙 | `docs/commit-convention.md` |

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

## 폴더 구조

```text
backend/
└── src/main/java/com/snaphere/api/
    ├── SnapHereApplication.java
    └── common/
        ├── error/     # 에러 코드 체계와 전역 예외 처리 (SYS-002)
        └── web/       # 공통 응답 봉투·커서 페이징·요청 추적 (SYS-001, SYS-003, SYS-016)
```

도메인 패키지는 기능을 붙일 때 `com.snaphere.api.post` 처럼 추가한다.

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
| `API-PST-001` | `POST /api/v1/media/presigned-urls` | 2.3 사진·캡션·태그 > 업로드 실행 | `PST-013`~`PST-015`, `USER-004`, `SYS-020` |

## 로컬에서 업로드 URL 발급 해보기

인증(`AUTH-001`)이 아직 없어서 임시로 `X-Debug-User-Id` 헤더를 로그인 사용자로 취급한다.
**인증이 들어오면 `DevHeaderCurrentUserProvider` 는 삭제한다.**

```bash
curl -X POST http://localhost:8080/api/v1/media/presigned-urls \
  -H 'Content-Type: application/json' \
  -H 'X-Debug-User-Id: 1' \
  -d '{"purpose":"POST_IMAGE","files":[{"mimeType":"image/jpeg","sizeBytes":1048576}]}'
```

`snaphere.media.provider` 가 `stub` 이면 실제 S3 없이 형태만 같은 주소를 돌려준다.
S3를 쓰려면 환경변수로 바꾼다. 자격증명은 설정 파일에 적지 않고 SDK 기본 체인을 쓴다.

```bash
MEDIA_PROVIDER=s3 MEDIA_S3_BUCKET=snaphere-media MEDIA_S3_REGION=ap-northeast-2 ./gradlew bootRun
```

## 아직 없는 것

- DB 연결 (PostgreSQL 16 + PostGIS 3) · JPA · 마이그레이션
- 인증 (`AUTH-*`) — 구글 ID Token 검증, JWT 발급. 지금은 `X-Debug-User-Id` 임시 통로
- 게시글 도메인 나머지 (`PST-001`~`PST-012`, `PST-016`~`PST-049`) — `docs/commit-convention.md`의 분할 계획 참고
