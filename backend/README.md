# SnapHere API

Spring Boot 3.5, Java 21, PostgreSQL/PostGIS, Redis 기반 API 서버입니다. PLC-001~PLC-023에 필요한 지역·장소 동기화, 장소 조회/생성/저장/신고, 관리자 운영 API와 Google 로그인을 구현합니다.

## 로컬 실행

루트의 `.env.sample`을 참고해 환경 변수를 설정한 뒤 DB와 Redis를 실행합니다.

```bash
docker compose up -d postgres redis
cd backend
./gradlew bootRun
```

Windows에서는 `gradlew.bat`을 사용합니다. 기본 API 주소는 `http://localhost:8080/api/v1`입니다.

필수 외부 연동 값:

- `TOUR_API_SERVICE_KEY`: 한국관광공사 TourAPI 서비스 키
- `GOOGLE_OAUTH_CLIENT_ID`: Google 로그인 OAuth 클라이언트 ID
- `GOOGLE_MAPS_API_KEY`: 사용자 장소의 대한민국 범위 및 시도·시군구 판정을 위한 Geocoding API 키
- 운영 환경의 `JWT_PRIVATE_KEY`, `JWT_PUBLIC_KEY`: PEM 형식 RSA 키. 로컬에서 비어 있으면 시작 시 임시 키를 생성합니다.

## 주요 엔드포인트

- 인증: `POST /api/v1/auth/google`, `/auth/onboarding`, `/auth/refresh`, `/auth/logout`
- 지역/장소: `GET /api/v1/regions`, `/regions/{areaCode}/sigungu`, `/places`, `/places/nearby`, `/places/{placeId}`
- 사용자 장소: `POST /api/v1/places`
- 저장/신고: `PUT|DELETE /api/v1/places/{placeId}/bookmark`, `GET /api/v1/me/bookmarks`, `POST /api/v1/places/{placeId}/reports`
- 운영: `POST /api/v1/admin/batches/PLACE_SYNC`, `GET /api/v1/admin/batches/{runId}`, `/admin/sync-logs`, `POST /api/v1/admin/places/{placeId}/moderation`

장소 상세 응답에는 대표 이미지, 조회수, 랭킹, 주변 장소와 최신 게시글 최대 12개가 포함됩니다. 조회수는 Redis에 누적한 뒤 DB로 반영하며 Redis 장애 시 DB 증가로 대체합니다.

## 검증

```bash
./gradlew test
```

PostGIS 스키마 통합 테스트는 Docker가 사용 가능한 환경에서 Testcontainers로 실행됩니다.
