package com.snaphere.api.post.dto;

import com.snaphere.api.post.tier.TierDecision;
import com.snaphere.api.post.tier.TierImprovementHint;
import com.snaphere.api.post.tier.TrustTier;

import java.util.List;
import java.util.Map;

/**
 * 등급 판정 결과 응답.
 * 명세: 3. 응답 스키마 &gt; TierResult
 *
 * <p>서버는 완성 문장을 만들지 않는다. 앱이 {@code reasonCode}·{@code reasonParams} 로
 * 다국어 문구를 조립한다 (SYS-010, PST-047).
 */
public record TierResultResponse(
        String tier,
        String tierMessageKey,
        double rankingWeight,
        boolean eligibleForBadge,
        boolean countsForVisit,
        boolean countsForHeatmap,
        Integer distanceM,
        int verifyRadiusM,
        boolean withinRadius,
        Long daysSinceTaken,
        String reasonCode,
        Map<String, Object> reasonParams,
        List<String> improvementHints
) {
    /**
     * 판정 근거 없이 등급만 담는다.
     *
     * <p>{@code tier_logs} 행이 없는 게시글에 쓴다 — 로그 적재가 실패했거나 스텁 구성으로
     * 돌린 게시글이다. 등급은 {@code posts.tier} 에 있으므로 화면이 배지는 그릴 수 있고,
     * 이유 문구만 비게 된다.
     */
    public static TierResultResponse tierOnly(TrustTier tier) {
        return new TierResultResponse(
                tier.name(), tier.messageKey(), tier.rankingWeight(),
                tier.eligibleForBadge(), tier.countsForVisit(), tier.countsForHeatmap(),
                null, 0, false, null, null, Map.of(), List.of());
    }

    public static TierResultResponse from(TierDecision d) {
        Map<String, Object> params = new java.util.LinkedHashMap<>();
        params.put("radiusM", d.appliedRadiusM());
        if (d.distanceM() != null) {
            params.put("distanceM", d.distanceM());
        }
        if (d.daysSinceTaken() != null) {
            params.put("days", d.daysSinceTaken());
        }
        params.put("highWithinMinutes", d.thresholds().highWithinMinutes());
        params.put("mediumWithinDays", d.thresholds().mediumWithinDays());

        return new TierResultResponse(
                d.tier().name(),
                d.tier().messageKey(),
                d.tier().rankingWeight(),
                d.tier().eligibleForBadge(),
                d.tier().countsForVisit(),
                d.tier().countsForHeatmap(),
                d.distanceM(),
                d.appliedRadiusM(),
                d.withinRadius(),
                d.daysSinceTaken(),
                d.reason().messageKey(),
                Map.copyOf(params),
                d.improvementHints().stream().map(TierImprovementHint::messageKey).toList());
    }
}
