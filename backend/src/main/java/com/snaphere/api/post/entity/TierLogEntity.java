package com.snaphere.api.post.entity;

import com.snaphere.api.post.tier.PhotoSource;
import com.snaphere.api.post.tier.TierDecision;
import com.snaphere.api.post.tier.TierInput;
import com.snaphere.api.post.tier.TrustTier;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

import java.time.OffsetDateTime;

/**
 * 등급 판정 근거 감사 로그. (PST-028)
 *
 * <p>{@code posts} 에 합치지 않는다. 판정 기준(반경·10분·30일)이 바뀌어도 과거 판정을 재현할 수
 * 있어야 하므로 판정 시점의 <em>입력값과 기준값</em>을 스냅샷으로 남긴다. 현재 등급은
 * {@code posts.tier}, 판정 이유는 이 테이블의 최신 1행이다.
 *
 * <p>등급 안내 화면(PST-047)이 이 행을 읽고, 심사에서는 "위치를 어떻게 검증했는가"의 근거가 된다.
 */
@Entity
@Table(name = "tier_logs")
public class TierLogEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "tier_log_id")
    private Long tierLogId;

    @Column(name = "post_id", nullable = false)
    private Long postId;

    @Enumerated(EnumType.STRING)
    @Column(name = "tier", nullable = false, length = 10)
    private TrustTier tier;

    @Enumerated(EnumType.STRING)
    @Column(name = "source", length = 20)
    private PhotoSource source;

    @Column(name = "taken_at")
    private OffsetDateTime takenAt;

    @Column(name = "has_taken_coordinate", nullable = false)
    private boolean hasTakenCoordinate;

    /** 촬영 좌표가 없으면 null. 그 자체가 낮음 판정 근거다. (PST-025) */
    @Column(name = "distance_m")
    private Integer distanceM;

    @Column(name = "applied_radius_m", nullable = false)
    private int appliedRadiusM;

    @Column(name = "threshold_high_minutes", nullable = false)
    private int thresholdHighMinutes;

    @Column(name = "threshold_medium_days", nullable = false)
    private int thresholdMediumDays;

    /** {@code TierReason} enum 이름. 문장은 앱이 만든다 (SYS-011). */
    @Column(name = "decided_reason", nullable = false, length = 50)
    private String decidedReason;

    @Column(name = "decided_at", nullable = false)
    private OffsetDateTime decidedAt;

    protected TierLogEntity() {
    }

    /**
     * 판정 입력과 결과를 그대로 옮긴다. 값을 다시 계산하지 않는다 — 그러면 스냅샷이 아니다.
     */
    public static TierLogEntity from(Long postId, TierInput input, TierDecision decision) {
        TierLogEntity log = new TierLogEntity();
        log.postId = postId;
        log.tier = decision.tier();
        log.source = input.source();
        log.takenAt = input.takenAt();
        log.hasTakenCoordinate = decision.hasTakenCoordinate();
        log.distanceM = decision.distanceM();
        log.appliedRadiusM = decision.appliedRadiusM();
        log.thresholdHighMinutes = decision.thresholds().highWithinMinutes();
        log.thresholdMediumDays = decision.thresholds().mediumWithinDays();
        log.decidedReason = decision.reason().name();
        log.decidedAt = decision.decidedAt();
        return log;
    }

    public Long getTierLogId() {
        return tierLogId;
    }

    public Long getPostId() {
        return postId;
    }

    public TrustTier getTier() {
        return tier;
    }

    public String getDecidedReason() {
        return decidedReason;
    }

    public OffsetDateTime getDecidedAt() {
        return decidedAt;
    }

    public Integer getDistanceM() {
        return distanceM;
    }

    public int getAppliedRadiusM() {
        return appliedRadiusM;
    }
}
