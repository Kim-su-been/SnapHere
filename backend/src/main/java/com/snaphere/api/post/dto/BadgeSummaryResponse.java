package com.snaphere.api.post.dto;

import com.snaphere.api.badge.AwardedBadge;

import java.time.OffsetDateTime;

/**
 * 명세: 3. 응답 스키마 &gt; BadgeSummary — 게시글 생성으로 새로 획득한 뱃지만 담는다.
 *
 * <p>이름·설명 문장은 서버가 만들지 않는다. 앱이 {@code nameKey} 로 다국어를 조립한다 (SYS-010).
 * 그래서 명세의 {@code name}·{@code description} 대신 키를 준다 — 조회 API(BDG)가 들어오면
 * 그쪽 응답과 맞춘다.
 */
public record BadgeSummaryResponse(
        String badgeId,
        String type,
        String nameKey,
        String iconUrl,
        boolean earned,
        OffsetDateTime earnedAt
) {
    public static BadgeSummaryResponse from(AwardedBadge badge) {
        return new BadgeSummaryResponse(
                String.valueOf(badge.badgeId()), badge.type(), badge.nameKey(),
                badge.iconUrl(), true, badge.earnedAt());
    }
}
