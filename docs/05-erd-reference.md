# ERD 참조

> 데이터 설계 **v1.1.5** · Percona PostgreSQL 17.10.2 + PostGIS 3.5.7
>
> 실행 가능한 스키마 원본은 [`12-db-schema.dbml`](12-db-schema.dbml), 설계 판단과 인덱스는 [`04-data-design.md`](04-data-design.md) 에 있다.

## 1. 테이블 요약 (29개)

### 계정

| 테이블 | 주요 컬럼 / 항목 | 설명 | 관련 요구사항 |
|---|---|---|---|
| users | id(uuid), provider(GOOGLE), provider_user_id, email, nickname(20), profile_image_url, bio(200), locale, role(USER/ADMIN), status(ACTIVE/SUSPENDED/WITHDRAWN), upload_blocked_until, push_like_enabled, push_follow_enabled, push_badge_enabled, badge_count, follower_count, following_count, post_count, withdrawn_at, purge_scheduled_at, restore_key | 구글 OAuth 단일. 자격증명 컬럼과 회원 등급제는 두지 않는다 — role은 등급이 아니라 관리자 권한 구분이다. upload_blocked_until은 신고 누적 시 24시간 업로드 정지 해제 시각. 식별자는 uuid 다 — 구글 OAuth 기반이라 순번을 노출하지 않고, 구현된 V1__auth_schema.sql 이 uuid 로 만든다 (v1.1.4 정정). | AUTH-001, AUTH-014, USER-003, USER-011, USER-015, USER-023, PST-032 |
| user_devices | device_id, user_id, fcm_token, platform, app_version | 앱 시작마다 갱신. 발송 실패 시 토큰을 비운다. | USER-007, NTF-010 |
| refresh_tokens | token_hash, user_id, device_id, expires_at, revoked_at | 원문이 아니라 해시만 저장. 1회용 회전. | AUTH-008, AUTH-009 |
| account_deletion_logs | log_id(PK), user_id, reason, content_action(KEEP_ANONYMIZED/DELETE_ALL), deleted_at, purged_at | 탈퇴 감사 기록. | USER-015, USER-019 |

### 소셜

| 테이블 | 주요 컬럼 / 항목 | 설명 | 관련 요구사항 |
|---|---|---|---|
| follows | follower_id, following_id, created_at · PK(follower_id, following_id) | 복합 PK가 중복을 막아 멱등을 보장한다. 역방향 인덱스 필요. | SOC-002, SOC-007 |

### 장소

| 테이블 | 주요 컬럼 / 항목 | 설명 | 관련 요구사항 |
|---|---|---|---|
| regions | area_code(PK), name_ko, name_en, representative_image_url, default_event_verify_radius_m | 17개 시도 마스터. 시도 코드는 비연속(1~8, 31~39). 라벨 좌표는 두지 않고 대표 이미지를 선택 대상으로 쓴다. area_code를 단독 PK로 둬야 다른 8개 테이블의 area_code 외래키가 성립한다. | PLC-001, MAP-006, PLC-022 |
| sigungu | area_code, sigungu_code, name_ko, name_en · PK(area_code, sigungu_code) | areaCode 오퍼레이션으로 적재하는 시군구 마스터. v1.1.3에서 regions에서 분리했다. | PLC-002, PLC-020 |
| places | place_id, place_type(OFFICIAL/USER), content_id, content_type_id, title, addr1, geom, verify_radius_m, area_code, sigungu_code, has_coordinate, post_count, visit_count, view_count, created_by, status(ACTIVE/HIDDEN/DELETED) | mapx=경도, mapy=위도로 geom 구성. GIST 공간 인덱스 필수. 관광지 500m·사용자 장소 100m 기본 인증 반경. view_count는 Redis 집계 후 주기 반영. status 는 장소 숨김 상태를 담는다 (PLC-023, v1.1.4 추가). | PLC-003, PLC-005, PLC-014, PLC-020, PLC-022 |
| place_details | place_id, language_code, overview, tel, homepage, use_time, rest_date · PK(place_id, language_code) | 장문 컬럼 분리. 목록 응답에서 제외한다. 언어별로 한 행이며 최초 조회 시점에 그 언어를 채운다. | PLC-006, SYS-012, SYS-018 |

### 게시글

| 테이블 | 주요 컬럼 / 항목 | 설명 | 관련 요구사항 |
|---|---|---|---|
| posts | post_id, user_id, place_id(NOT NULL), event_id(NULL), content, original_language_code, tier(HIGH/MEDIUM/LOW), lat, lng, taken_at, source(CAMERA/ALBUM), area_code, like_count, comment_count, view_count, status | 장소는 필수. tier는 서버가 판정한다. 원문과 언어 코드를 보존해 번역 결과를 후속 확장할 수 있게 한다. | PST-002, PST-006, PST-016, PST-022, SYS-010 |
| post_images | post_image_id, post_id, image_key, thumbnail_url, aspect_ratio, sort_order, image_hash | 최대 4장. 비율은 메이슨리가 카드 높이를 잡는 데 쓴다. | PST-002, PST-021 |
| tier_logs | tier_log_id(PK), post_id, tier, source, taken_at, has_taken_coordinate, distance_m, applied_radius_m, threshold_high_minutes, threshold_medium_days, decided_reason, decided_at | 판정 시점의 입력값과 적용 기준(반경·10분·30일)을 스냅샷으로 남기는 감사 로그. 기준이 바뀌어도 과거 판정을 재현할 수 있다. | PST-028, PST-047, PST-049 |

### 커뮤니티

| 테이블 | 주요 컬럼 / 항목 | 설명 | 관련 요구사항 |
|---|---|---|---|
| comments | comment_id, post_id, user_id, parent_id, content, like_count, status | 대댓글 깊이 1단계. 자식은 한 번에 모아 조회. | CMU-014, CMU-015 |
| likes | user_id, target_type(POST/COMMENT), target_id · PK(user_id, target_type, target_id) | 좋아요. 복합 PK로 중복을 막는다. | PST-040, CMU-018 |
| bookmarks | user_id, target_type(POST/PLACE), target_id | 여러 종류를 담아 외래키를 걸 수 없다. 앱에서 대상 존재를 검증. | CMU-023, CMU-024 |
| tags | tag_id, name, normalized_name(UNIQUE), theme_code, usage_count | 해시태그 마스터. 소문자 변환 + 공백 제거로 정규화. 사용자 태그의 theme_code를 K-컬처 테마 랭킹에 쓴다. | CMU-025, CMU-031, RNK-005 |
| post_tags | post_id, tag_id, is_locked, is_suggested · PK(post_id, tag_id) | 고정(행사)·추천 채택·사용자 직접 입력 태그를 구분한다. 최소 1개 최대 10개. | PST-004, CMU-026, CMU-029, CMU-032, EVT-018 |

### 이벤트

| 테이블 | 주요 컬럼 / 항목 | 설명 | 관련 요구사항 |
|---|---|---|---|
| events | event_id, content_id, title, overview, area_code, place_id, start_date, end_date, thumbnail_url, fixed_tags(JSON), badge_id, participant_count, source, verify_radius_m(NULL=지역 기본값) | 행사 데이터 + 고정 태그 + 뱃지 연결. 반경 적용 순서: 이벤트별 값 → regions 기본값 → 2,000m. | EVT-001, EVT-017, EVT-023, PLC-022 |

### 뱃지

| 테이블 | 주요 컬럼 / 항목 | 설명 | 관련 요구사항 |
|---|---|---|---|
| badges | badge_id, code, type(EVENT/AREA/COMPLETION/RECORD), name_ko, name_en, description, icon_url, condition_json, event_id, area_code, is_obtainable, available_from, available_to | 획득 조건을 데이터로 관리한다. 수집 진행률 분모는 현재 is_obtainable=true인 뱃지 수다. | BDG-007, BDG-009, BDG-010 |
| user_badges | user_id, badge_id, earned_at, source_post_id · UNIQUE(user_id, badge_id) | 중복 지급 방지의 핵심. | BDG-006 |

### 방문

| 테이블 | 주요 컬럼 / 항목 | 설명 | 관련 요구사항 |
|---|---|---|---|
| visits | visit_id, user_id, place_id, post_id, visited_on · UNIQUE(user_id, place_id, visited_on) | 같은 날 같은 장소는 1회. 높음·보통만 기록. | VST-001, VST-002 |

### 집계

| 테이블 | 주요 컬럼 / 항목 | 설명 | 관련 요구사항 |
|---|---|---|---|
| heatmap_cells | cell_id(PK), grid_level, lat_index, lng_index, lat, lng, period(LAST_1H/LAST_24H/WEEKLY/MONTHLY), post_count, visit_count, user_count, top_place_id, sample_post_ids, sample_thumbnail_urls, last_posted_at, calculated_at · UNIQUE(period, grid_level, lat_index, lng_index) | 미리 집계하고 조회는 읽기만. 실시간은 1분, 그 외 10분 주기. 후보 ID·썸네일 URL 배열은 같은 순서로 최대 10개 저장한다. visit_count는 VST 구현 전까지 0이다. | MAP-008~025 |
| region_stats | area_code, period(heatmap_period 공유), post_count, contributor_count, representative_post_id, calculated_at · PK(area_code, period) | 지역 레이어 버블과 대표 게시글용. | MAP-005, MAP-006 |
| place_rankings | ranking_id(PK), place_id, area_code, period(DAILY/WEEKLY/MONTHLY/ALL), theme, score, rank_no, previous_rank, calculated_at · UNIQUE(place_id, period, theme) | 조회는 이 테이블만 읽는다. theme은 공식 콘텐츠 유형과 정규화된 사용자 태그에서 계산한다. 동점 시 보조 정렬 키 필요. | RNK-005, RNK-007, RNK-008 |
| post_rankings | post_id, period(HOURS_24/WEEKLY/MONTHLY/ALL), score, rank_no, calculated_at · PK(post_id, period) | 기간별 인기 게시글·인기 피드는 이 테이블만 읽는다(조회 시 계산 금지). 팔로잉 가중치는 사용자별이라 이 score를 기준값으로 두고 조회 시 보정한다. | PST-035, CMU-002, CMU-007, CMU-008, CMU-009 |

### 알림

| 테이블 | 주요 컬럼 / 항목 | 설명 | 관련 요구사항 |
|---|---|---|---|
| notifications | notification_id, recipient_id, actor_id, type(POST_LIKE/FOLLOW/BADGE_EARNED/SYSTEM), target_type(POST/USER/BADGE/NONE), target_id, message_key, message_params, is_read · UNIQUE(recipient_id, actor_id, type, target_type, target_id) | 서버는 완성 문장을 만들지 않는다. 알림 3종은 Could Have 범위. 90일 지난 읽은 알림은 배치 삭제. | NTF-001~003, NTF-008, NTF-009, NTF-011, NTF-014 |

### 운영

| 테이블 | 주요 컬럼 / 항목 | 설명 | 관련 요구사항 |
|---|---|---|---|
| reports | report_id, reporter_id, target_type, target_id, reason, status, detail, action(KEEP/HIDE/DELETE), reviewed_at, created_at | 동일 대상 중복 신고 불가. action·reviewed_at 은 운영자 검토 결과를 담는다. status 와 짝이 맞아야 하므로 DB CHECK 로 묶는다 (SYS-017, v1.1.4 추가). | PST-043, PST-044 |
| sync_logs | sync_id, job_type, area_code, content_type_id, result(SUCCESS/FAIL/PARTIAL), count, message, created_at | 조합 단위 트랜잭션 분리 결과 기록. | PLC-009 |
| search_logs | log_id(PK), keyword, area_code, searched_at | 인기 검색어 집계용. 최근 검색어(SCH-011)·최근 본 장소(VST-006) 저장소는 미정 — 앱 로컬·Redis·별도 테이블. | SCH-010, SCH-011 |


## 2. 엔터티 상세 (29개)

### 계정

| 테이블 | PK | FK | Unique | 주요 컬럼 | 삭제·보존 | 관련 요구사항 | 설계 메모 |  |
|---|---|---|---|---|---|---|---|---|
| users | id (uuid) | - | (provider, provider_user_id) | provider, provider_user_id, email, nickname(20), profile_image_url, bio(200), locale, role, status, upload_blocked_until, push_like_enabled, push_follow_enabled, push_badge_enabled, terms_agreed_at, badge_count, follower_count, following_count, post_count, withdrawn_at, purge_scheduled_at, restore_key | 논리 | AUTH-001, AUTH-014, USER-001~023, PST-032 | DBML v1.1.3 정합. terms_agreed_at만 보강(USER-006 근거, DBML 미포함) PK 는 uuid — 구현된 V1__auth_schema.sql 기준 (v1.1.4 정정). |  |
| user_devices | device_id | user_id→users.user_id | (user_id, device_id) | fcm_token, platform, app_version | 물리 | USER-007, NTF-010 | 사용자별 복수 기기 |  |
| refresh_tokens | token_hash | user_id→users, device_id→user_devices | token_hash | expires_at, revoked_at | 물리 | AUTH-007~009 | 원문 미저장 |  |
| account_deletion_logs | log_id | user_id→users.user_id | - | reason, content_action, purged_at | 감사 보존 | USER-015, USER-019 | DBML v1.1.3 정합 — 대리키 PK |  |

### 소셜

| 테이블 | PK | FK | Unique | 주요 컬럼 | 삭제·보존 | 관련 요구사항 | 설계 메모 |  |
|---|---|---|---|---|---|---|---|---|
| follows | (follower_id, following_id) | follower_id→users, following_id→users | PK 자체 | created_at | 물리 | SOC-001~009 | 자기 자신 CHECK 차단 |  |

### 장소

| 테이블 | PK | FK | Unique | 주요 컬럼 | 삭제·보존 | 관련 요구사항 | 설계 메모 |  |
|---|---|---|---|---|---|---|---|---|
| regions | area_code | - | PK 자체 | name_ko, name_en, representative_image_url, default_event_verify_radius_m | 기준정보 | PLC-001~002, MAP-006 | 17개 시도 마스터. area_code를 단독 PK로 둬야 다른 8개 테이블의 area_code FK가 성립한다 (DBML v1.1.3) |  |
| sigungu | (area_code, sigungu_code) | area_code→regions.area_code | PK 자체 | name_ko, name_en | 기준정보 | PLC-002, PLC-020 | areaCode 오퍼레이션으로 적재하는 시군구 마스터 (DBML v1.1.3) |  |
| places | place_id | area_code→regions, (area_code, sigungu_code)→sigungu, created_by→users | (content_id, content_type_id) | place_type, content_id, content_type_id, title, addr1, geom, verify_radius_m, area_code, sigungu_code, has_coordinate, post_count, visit_count, view_count, status | 논리 | PLC-003~023, PLC-014 | 공간 GiST 인덱스 필수. status만 보강(PLC-023 장소 숨김 근거, DBML 미포함) |  |
| place_details | (place_id, language_code) | place_id→places.place_id | PK 자체 | language_code, overview, tel, homepage, use_time, rest_date | 종속 | PLC-006, SYS-012, SYS-018 | 언어별 1행. 요청 언어 상세가 없으면 그 시점에 지연 적재 |  |

### 게시글

| 테이블 | PK | FK | Unique | 주요 컬럼 | 삭제·보존 | 관련 요구사항 | 설계 메모 |  |
|---|---|---|---|---|---|---|---|---|
| posts | post_id | user_id→users, place_id→places, event_id→events, area_code→regions | - | content, original_language_code, tier, lat, lng, taken_at, source, area_code, like_count, comment_count, view_count, status, created_at, updated_at, deleted_at | 논리 | PST-001~049, SYS-010 | created_at 등 공통 타임스탬프 보강 |  |
| post_images | post_image_id | post_id→posts.post_id | (post_id, sort_order), (post_id, image_hash) | image_key, thumbnail_url, aspect_ratio, sort_order, image_hash | 물리 | PST-013~021, PST-031 | 게시글당 1~4장 |  |
| tier_logs | tier_log_id | post_id→posts.post_id | - | tier, source, taken_at, has_taken_coordinate, distance_m, applied_radius_m, threshold_high_minutes, threshold_medium_days, decided_reason, decided_at | 감사 보존 | PST-022~028 | 판정 근거 감사 로그(1:N). 인덱스 (post_id, decided_at). 현재 등급은 posts.tier, 이유는 최신 1행 (DBML v1.1.3) |  |

### 커뮤니티

| 테이블 | PK | FK | Unique | 주요 컬럼 | 삭제·보존 | 관련 요구사항 | 설계 메모 |  |
|---|---|---|---|---|---|---|---|---|
| comments | comment_id | post_id→posts, user_id→users, parent_id→comments | - | content, like_count, status, created_at, updated_at | 논리 | CMU-012~017 | parent는 최상위 댓글만 |  |
| likes | (user_id, target_type, target_id) | user_id→users; target는 논리 FK | PK 자체 | created_at | 물리 | PST-040, CMU-018 | POST/COMMENT 다형 대상 |  |
| bookmarks | (user_id, target_type, target_id) | user_id→users; target는 논리 FK | PK 자체 | created_at | 물리 | PLC-015, CMU-023~024 | POST/PLACE 다형 대상 |  |
| tags | tag_id | - | normalized_name | name, normalized_name, theme_code, usage_count | 물리 | CMU-025~031, RNK-005 | 사용자 K-컬처 태그 원천 |  |
| post_tags | (post_id, tag_id) | post_id→posts, tag_id→tags | PK 자체 | is_locked, is_suggested, created_at | 물리 | PST-004, CMU-029~032 | 원본의 tags/post_tags를 물리 2개로 분리 |  |

### 이벤트

| 테이블 | PK | FK | Unique | 주요 컬럼 | 삭제·보존 | 관련 요구사항 | 설계 메모 |  |
|---|---|---|---|---|---|---|---|---|
| events | event_id | area_code→regions, place_id→places | content_id | content_id, title, overview, area_code, start_date, end_date, thumbnail_url, fixed_tags, participant_count, source, verify_radius_m, created_at | 논리 | EVT-001~023 | 반경 적용 순서: events.verify_radius_m → regions.default_event_verify_radius_m → 2,000m. created_at은 EVT-008 신규 판정 기준 |  |

### 뱃지

| 테이블 | PK | FK | Unique | 주요 컬럼 | 삭제·보존 | 관련 요구사항 | 설계 메모 |  |
|---|---|---|---|---|---|---|---|---|
| badges | badge_id | event_id→events, area_code→regions | code, event_id(조건부) | type, name_ko, name_en, description, icon_url, condition_json, is_obtainable, available_from, available_to | 물리 | BDG-001~013 | 이벤트 뱃지는 events 1:0..1 |  |
| user_badges | (user_id, badge_id) | user_id→users, badge_id→badges, source_post_id→posts | PK 자체 | earned_at | 물리 | BDG-005~006, BDG-009 | 중복 지급 방지 |  |

### 방문

| 테이블 | PK | FK | Unique | 주요 컬럼 | 삭제·보존 | 관련 요구사항 | 설계 메모 |  |
|---|---|---|---|---|---|---|---|---|
| visits | visit_id | user_id→users, place_id→places, post_id→posts | (user_id, place_id, visited_on) | visited_on | 물리 | VST-001~005 | 높음·보통만 기록 |  |

### 집계

| 테이블 | PK | FK | Unique | 주요 컬럼 | 삭제·보존 | 관련 요구사항 | 설계 메모 |  |
|---|---|---|---|---|---|---|---|---|
| heatmap_cells | cell_id | top_place_id→places; sample_post_ids는 논리 참조 | (period, grid_level, lat_index, lng_index) | grid_level, lat_index, lng_index, lat, lng, period, post_count, visit_count, user_count, top_place_id, sample_post_ids, sample_thumbnail_urls, last_posted_at, calculated_at | 집계 | MAP-008~025 | intensity는 저장하지 않고 조회 시 maxCount로 로그 정규화한다. 후보 두 배열은 같은 인덱스로 대응한다. |  |
| region_stats | (area_code, period) | area_code→regions, representative_post_id→posts | PK 자체 | post_count, contributor_count, representative_post_id, calculated_at | 집계 | MAP-005~006 | 지역 레이어 버블과 대표 게시글. period는 heatmap_period 공유 |  |
| place_rankings | ranking_id | place_id→places, area_code→regions | (place_id, period, theme) | area_code, period, theme, score, rank_no, previous_rank, calculated_at | 집계 | RNK-001~010 | 조회는 이 테이블만 읽는다. 조회 인덱스 (area_code, period, theme, rank_no) (DBML v1.1.3) |  |
| post_rankings | (post_id, period) | post_id→posts.post_id | (period, rank_no) | score, rank_no, calculated_at | 집계 | PST-035, CMU-002, CMU-008~009 | 기간별 인기 게시글은 이 테이블만 읽는다. 조회 시 계산 금지 (JOB-013) |  |

### 알림

| 테이블 | PK | FK | Unique | 주요 컬럼 | 삭제·보존 | 관련 요구사항 | 설계 메모 |  |
|---|---|---|---|---|---|---|---|---|
| notifications | notification_id | recipient_id→users, actor_id→users; target는 논리 FK | (recipient_id, actor_id, type, target_type, target_id) | type, target_type, target_id, message_key, message_params, is_read, created_at | 물리 | NTF-001~014 | 중복 방지는 5컬럼 UNIQUE (DBML v1.1.3) |  |

### 운영

| 테이블 | PK | FK | Unique | 주요 컬럼 | 삭제·보존 | 관련 요구사항 | 설계 메모 |  |
|---|---|---|---|---|---|---|---|---|
| reports | report_id | reporter_id→users; target는 논리 FK | (reporter_id, target_type, target_id) | reason, detail, status, action, reviewed_at | 논리 | PST-043~045, SYS-017 | 다형 대상. detail·action·reviewed_at은 보강(SYS-017 운영 검토 근거, DBML 미포함) |  |
| sync_logs | sync_id | area_code→regions | - | job_type, area_code, content_type_id, result, count, message, created_at | 감사 보존 | PLC-009, SYS-015 | 조합 단위 트랜잭션 분리 결과. result는 SUCCESS/FAIL/PARTIAL |  |
| search_logs | log_id | area_code→regions | - | keyword, area_code, searched_at | 기간 보존 | SCH-010~011 | 인기 검색어 집계용. 최근 검색어(SCH-011) 저장소는 미정 — DBML 미결정 10 |  |


## 3. 관계 (49개)

> `Logical` 은 다형·배열 참조라 DB 외래키를 걸 수 없고 애플리케이션에서 대상 존재를 검증한다.

| REL ID | 부모 | 자식 | 관계 | FK·참조 | 삭제 정책 | 제약 유형 | 설명 |
|---|---|---|---|---|---|---|---|
| REL-001 | users | user_devices | 1:N | user_devices.user_id | CASCADE | Physical | 회원 탈퇴 시 기기 제거 |
| REL-002 | users | refresh_tokens | 1:N | refresh_tokens.user_id | CASCADE | Physical | 전체 로그아웃 시 일괄 revoke |
| REL-003 | user_devices | refresh_tokens | 1:N | refresh_tokens.device_id | CASCADE | Physical | 기기별 세션 |
| REL-004 | users | account_deletion_logs | 1:N | account_deletion_logs.user_id | RESTRICT/익명화 | Physical | 감사 기록 보존 정책 확인 |
| REL-005 | users | follows | 1:N | follows.follower_id | CASCADE | Physical | 팔로우 주체 |
| REL-006 | users | follows | 1:N | follows.following_id | CASCADE | Physical | 팔로우 대상 |
| REL-007 | regions | places | 1:N | places.area_code | RESTRICT | Physical | 행정구역 |
| REL-008 | users | places | 1:N | places.created_by | SET NULL | Physical | 사용자 장소 |
| REL-009 | places | place_details | 1:0..1 | place_details.place_id | CASCADE | Physical | 지연 적재 상세 |
| REL-010 | users | posts | 1:N | posts.user_id | RESTRICT/익명화 | Physical | 게시글 작성자 |
| REL-011 | places | posts | 1:N | posts.place_id | RESTRICT | Physical | 장소 필수 |
| REL-012 | events | posts | 1:N | posts.event_id | SET NULL | Physical | 이벤트 참여 게시글 |
| REL-013 | regions | posts | 1:N | posts.area_code | RESTRICT | Physical | 서버 산출 지역 |
| REL-014 | posts | post_images | 1:N | post_images.post_id | CASCADE(30일 지연) | Physical | 최대 4장 |
| REL-015 | posts | tier_logs | 1:N | tier_logs.post_id | RESTRICT | Physical | 판정 감사 |
| REL-016 | posts | comments | 1:N | comments.post_id | CASCADE/정책 | Physical | 댓글 |
| REL-017 | users | comments | 1:N | comments.user_id | RESTRICT/익명화 | Physical | 댓글 작성자 |
| REL-018 | comments | comments | 1:N | comments.parent_id | SET NULL | Physical | 깊이 1 |
| REL-019 | users | likes | 1:N | likes.user_id | CASCADE | Physical | 좋아요 주체 |
| REL-020 | posts/comments | likes | 1:N | target_type+target_id | 애플리케이션 | Logical | 다형 대상, DB FK 불가 |
| REL-021 | users | bookmarks | 1:N | bookmarks.user_id | CASCADE | Physical | 저장 주체 |
| REL-022 | posts/places | bookmarks | 1:N | target_type+target_id | 애플리케이션 | Logical | 대상 존재 검증 |
| REL-023 | posts | post_tags | 1:N | post_tags.post_id | CASCADE | Physical | 태그 연결 |
| REL-024 | tags | post_tags | 1:N | post_tags.tag_id | RESTRICT | Physical | 태그 사전 |
| REL-025 | regions | events | 1:N | events.area_code | RESTRICT | Physical | 이벤트 지역 |
| REL-026 | places | events | 1:N | events.place_id | RESTRICT | Physical | 이벤트 장소 |
| REL-027 | events | badges | 1:0..1 | badges.event_id | SET NULL | Physical | 순환 FK 방지를 위해 badges가 소유 |
| REL-028 | regions | badges | 1:N | badges.area_code | SET NULL | Physical | 지역 뱃지 |
| REL-029 | users | user_badges | 1:N | user_badges.user_id | CASCADE | Physical | 사용자 수집 |
| REL-030 | badges | user_badges | 1:N | user_badges.badge_id | RESTRICT | Physical | 뱃지 획득 |
| REL-031 | posts | user_badges | 1:N | user_badges.source_post_id | SET NULL | Physical | 지급 근거 |
| REL-032 | users | visits | 1:N | visits.user_id | CASCADE | Physical | 방문 사용자 |
| REL-033 | places | visits | 1:N | visits.place_id | RESTRICT | Physical | 방문 장소 |
| REL-034 | posts | visits | 1:0..1 | visits.post_id | SET NULL | Physical | 방문 발생 게시글 |
| REL-035 | places | heatmap_cells | 1:N | heatmap_cells.top_place_id | SET NULL | Physical | 셀 대표 장소 |
| REL-036 | posts | heatmap_cells | N:M | sample_post_ids | 애플리케이션 | Logical | 최대 10개 배열, FK 없음 |
| REL-037 | regions | region_stats | 1:N | region_stats.area_code | CASCADE | Physical | 기간별 지역 집계 |
| REL-038 | places | place_rankings | 1:N | place_rankings.place_id | CASCADE | Physical | 기간·테마별 랭킹 |
| REL-039 | regions | place_rankings | 1:N | place_rankings.area_code | CASCADE | Physical | 지역 랭킹 |
| REL-040 | users | notifications | 1:N | notifications.recipient_id | CASCADE | Physical | 수신자 |
| REL-041 | users | notifications | 1:N | notifications.actor_id | SET NULL | Physical | 행위자 |
| REL-042 | posts/users/badges | notifications | 1:N | target_type+target_id | 애플리케이션 | Logical | 알림 이동 대상 |
| REL-043 | users | reports | 1:N | reports.reporter_id | RESTRICT | Physical | 신고자 |
| REL-044 | posts/places/comments/users | reports | 1:N | target_type+target_id | 애플리케이션 | Logical | 신고 대상 |
| REL-045 | users | search_logs | 1:N | search_logs.user_id | CASCADE | Physical | 최근 검색 |
| REL-046 | regions | search_logs | 1:N | search_logs.area_code | SET NULL | Physical | 지역별 인기 검색 |
| REL-047 | regions | sigungu | 1:N | sigungu.area_code | CASCADE | Physical | 시도 → 시군구 마스터 |
| REL-048 | sigungu | places | 1:N | places.(area_code, sigungu_code) | SET NULL | Logical | 복합 참조 — 다이어그램 선은 생략 |
| REL-049 | posts | post_rankings | 1:0..N | post_rankings.post_id | CASCADE | Physical | 기간별 게시글 인기 집계 |

---

원본 스프레드시트: [`specs/snaphere-requirements-spec-v1.1.5.xlsx`](specs/snaphere-requirements-spec-v1.1.5.xlsx) · [`specs/snaphere-api-spec-v1.1.5.xlsx`](specs/snaphere-api-spec-v1.1.5.xlsx)
변경 이력: [`08-spec-changelog.md`](08-spec-changelog.md)
