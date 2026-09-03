package com.snaphere.api.badge;

import java.time.OffsetDateTime;

/**
 * 새로 획득한 뱃지. 명세: 3. 응답 스키마 &gt; BadgeSummary
 *
 * <p>이름·설명은 담지 않는다. 서버는 완성 문장을 만들지 않고 앱이 {@code nameKey} 로
 * 다국어를 조립한다 (SYS-010, SYS-011).
 */
public record AwardedBadge(
        long badgeId,
        String type,
        String nameKey,
        String iconUrl,
        OffsetDateTime earnedAt
) {
}
