package com.snaphere.api.comment;

import com.snaphere.api.common.error.ApiException;
import com.snaphere.api.common.error.ErrorCode;

import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.util.Base64;
import java.util.Map;

/**
 * 최상위 댓글 목록 커서. (CMU-013, CMU-010)
 *
 * <p>{@code createdAt} 과 {@code commentId} 두 키를 담는다 — 같은 순간에 달린 댓글이 두 페이지에
 * 나오거나 사라지지 않게 하려면 2차 키가 필요하다.
 *
 * <p>대댓글에는 커서가 없다. 부모마다 자식을 전부 준다 (명세: CommentThread.replies) — 깊이가
 * 1단계로 고정돼 있어 한 스레드의 자식 수가 폭발하지 않는다는 전제다 (CMU-015).
 *
 * <p>게시글 커서와 형식이 같지만 클래스를 따로 둔다. {@link com.snaphere.api.post.PostCursor} 를
 * 재사용하면 게시글 정렬 키가 바뀔 때 댓글 페이징이 같이 깨진다.
 */
public record CommentCursor(OffsetDateTime createdAt, long commentId) {

    private static final String SEPARATOR = ":";

    public String encode() {
        String raw = createdAt.toInstant().toEpochMilli() + SEPARATOR + commentId;
        return Base64.getUrlEncoder().withoutPadding()
                .encodeToString(raw.getBytes(StandardCharsets.UTF_8));
    }

    /** @return 커서가 없으면 null. 형식이 깨졌으면 {@code COMMON_400} */
    public static CommentCursor decode(String encoded) {
        if (encoded == null || encoded.isBlank()) {
            return null;
        }
        try {
            String raw = new String(Base64.getUrlDecoder().decode(encoded), StandardCharsets.UTF_8);
            int separator = raw.indexOf(SEPARATOR);
            if (separator < 0) {
                throw new IllegalArgumentException(raw);
            }
            long epochMilli = Long.parseLong(raw.substring(0, separator));
            long commentId = Long.parseLong(raw.substring(separator + 1));
            return new CommentCursor(
                    OffsetDateTime.ofInstant(Instant.ofEpochMilli(epochMilli), ZoneOffset.UTC),
                    commentId);
        } catch (IllegalArgumentException malformed) {
            throw new ApiException(ErrorCode.COMMON_400, Map.of("field", "cursor"));
        }
    }
}
