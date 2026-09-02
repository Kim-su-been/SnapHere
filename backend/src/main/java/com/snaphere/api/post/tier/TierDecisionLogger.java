package com.snaphere.api.post.tier;

import java.util.UUID;

/**
 * 판정 근거를 남긴다. (PST-028)
 *
 * <p>심사에서 "위치를 어떻게 검증했는가"의 근거로 쓰이고, 등급 안내 화면(PST-047)이 읽는다.
 *
 * <p>입력({@link TierInput})과 결과({@link TierDecision})를 함께 받는다. 결과에는 판정에 쓰인
 * 촬영 시각·사진 출처가 남지 않는데 {@code tier_logs} 는 그 둘까지 스냅샷으로 보관해야 한다 —
 * 기준이 바뀐 뒤에도 과거 판정을 재현하려면 입력이 있어야 한다.
 *
 * @param postId 확정된 게시글 판정이면 게시글 ID, 업로드 전 미리보기(API-PST-002)면 null
 */
public interface TierDecisionLogger {

    void record(Long postId, UUID userId, long placeId, Long eventId,
                TierInput input, TierDecision decision);
}
