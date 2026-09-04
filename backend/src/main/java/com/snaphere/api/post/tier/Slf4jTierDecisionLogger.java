package com.snaphere.api.post.tier;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

import java.util.UUID;

/**
 * 판정 근거를 애플리케이션 로그에 남긴다.
 *
 * <p>{@code tier_logs} 테이블이 생긴 뒤에도 남는다. 업로드 전 미리보기(API-PST-002)는 게시글이
 * 아직 없어 그 테이블에 적재할 수 없으므로, 미리보기 판정은 이 구현이 받는다
 * ({@code JpaTierDecisionLogger} 가 postId 가 null 이면 여기로 넘긴다).
 */
@Component
public class Slf4jTierDecisionLogger implements TierDecisionLogger {

    private static final Logger log = LoggerFactory.getLogger("tier-decision");

    @Override
    public void record(Long postId, UUID userId, long placeId, Long eventId,
                       TierInput input, TierDecision decision) {
        log.info("tier={} reason={} postId={} userId={} placeId={} eventId={} "
                        + "source={} takenAt={} hasCoord={} distanceM={} radiusM={} daysSinceTaken={} "
                        + "thresholdHighMin={} thresholdMediumDays={} decidedAt={}",
                decision.tier(), decision.reason(), postId, userId, placeId, eventId,
                input.source(), input.takenAt(),
                decision.hasTakenCoordinate(), decision.distanceM(), decision.appliedRadiusM(),
                decision.daysSinceTaken(),
                decision.thresholds().highWithinMinutes(), decision.thresholds().mediumWithinDays(),
                decision.decidedAt());
    }
}
