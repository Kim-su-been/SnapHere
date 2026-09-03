package com.snaphere.api.place.stub;

import com.snaphere.api.place.PlaceSnapshot;
import com.snaphere.api.place.PlaceSnapshotReader;
import com.snaphere.api.place.PlaceType;
import com.snaphere.api.place.RegionRadiusReader;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.util.LinkedHashMap;
import java.util.Map;
import java.util.Optional;

/**
 * DB 없이 등급 판정을 시험하기 위한 장소·지역 고정 데이터.
 *
 * <p>{@code snaphere.stub-data=true} 일 때만 등록된다. 기본값은 이제 {@code false} 이고,
 * 그때는 {@code JpaPlaceSnapshotReader}·{@code JpaRegionRadiusReader} 가 {@code places}·
 * {@code regions} 테이블을 읽는다.
 *
 * <p>PostgreSQL 을 띄우지 않고 앱과 판정 흐름만 맞춰 볼 때 켠다. TourAPI 적재(PLC-003)가
 * 자동화되면 지울 수 있다.
 */
@Configuration
@ConditionalOnProperty(prefix = "snaphere", name = "stub-data", havingValue = "true")
public class StubPlaceData {

    private static final Map<Long, PlaceSnapshot> PLACES = new LinkedHashMap<>();
    private static final Map<Integer, Integer> REGION_EVENT_RADIUS = new LinkedHashMap<>();

    static {
        // 관광지 — 기본 반경 500m (PST-027)
        PLACES.put(1L, new PlaceSnapshot(1L, PlaceType.OFFICIAL, 37.579617, 126.977041, true, 500, 1));
        // 사용자 등록 장소 — 기본 반경 100m (PST-027)
        PLACES.put(2L, new PlaceSnapshot(2L, PlaceType.USER, 37.556000, 126.923500, true, 100, 1));
        // 좌표 없는 장소 — 판정 제외 대상 (PLC-007)
        PLACES.put(3L, new PlaceSnapshot(3L, PlaceType.OFFICIAL, null, null, false, 500, 37));
        // 축제 장소 (전북)
        PLACES.put(4L, new PlaceSnapshot(4L, PlaceType.OFFICIAL, 35.791700, 127.425300, true, 500, 37));

        // 전북은 지역 기본값을 2,500m 로 재정의해 둔 상태 (PLC-022)
        REGION_EVENT_RADIUS.put(37, 2_500);
    }

    @Bean
    public PlaceSnapshotReader stubPlaceSnapshotReader() {
        return placeId -> Optional.ofNullable(PLACES.get(placeId));
    }

    @Bean
    public RegionRadiusReader stubRegionRadiusReader() {
        return areaCode -> Optional.ofNullable(REGION_EVENT_RADIUS.get(areaCode));
    }
}
