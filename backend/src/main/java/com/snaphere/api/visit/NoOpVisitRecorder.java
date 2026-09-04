package com.snaphere.api.visit;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

import java.time.OffsetDateTime;
import java.util.UUID;

/**
 * {@code visits} 테이블이 생기기 전까지 쓰는 구현. 기록하지 않고 로그만 남긴다.
 *
 * <p><b>실제 구현을 추가할 때 이 파일을 지운다.</b> 조건부 등록을 걸지 않았으므로 구현이
 * 하나 더 생기면 애플리케이션이 뜨지 않고 중복 빈을 알려 준다 — 임시 코드가 조용히 남는 것보다 낫다.
 * 같은 이유로 건너뛸 때 조용히 성공하지 않고 WARN 을 찍는다.
 */
@Component
public class NoOpVisitRecorder implements VisitRecorder {

    private static final Logger log = LoggerFactory.getLogger(NoOpVisitRecorder.class);

    @Override
    public boolean recordIfEligible(UUID userId, long placeId, boolean countsForVisit, OffsetDateTime at) {
        if (countsForVisit) {
            log.warn("방문 기록 대상이지만 visits 테이블이 없어 건너뛴다. userId={} placeId={} at={} (VST-001)",
                    userId, placeId, at);
        }
        return false;
    }
}
