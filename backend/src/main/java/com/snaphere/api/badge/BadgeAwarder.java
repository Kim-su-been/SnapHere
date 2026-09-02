package com.snaphere.api.badge;

import java.util.List;
import java.util.UUID;

/**
 * 게시글 등록으로 획득되는 뱃지 판정 포트. (BDG-005, BDG-006)
 *
 * <p>반경 밖 게시글도 게시는 성공하고 뱃지만 주지 않는다 (API 명세 API-PST-003 비고).
 * 그래서 뱃지 판정 결과가 게시글 생성 실패로 이어지는 일은 없다.
 *
 * <p><b>{@code badges}·{@code user_badges} 테이블은 아직 없다.</b> 뱃지 도메인(BDG)은 다른
 * 담당 범위여서 지금은 {@link NoOpBadgeAwarder} 가 빈 목록을 준다.
 */
public interface BadgeAwarder {

    /**
     * @param eligibleForBadge 등급이 뱃지 대상인가 ({@code TrustTier.eligibleForBadge()})
     * @return 이번 게시글로 새로 획득한 뱃지. 없으면 빈 목록
     */
    List<AwardedBadge> awardForPost(UUID userId, long postId, long placeId, Long eventId,
                                    boolean eligibleForBadge);
}
