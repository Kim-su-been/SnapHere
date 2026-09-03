package com.snaphere.api.post;

import com.snaphere.api.common.error.ApiException;
import com.snaphere.api.common.error.ErrorCode;

import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.util.Base64;
import java.util.Map;

/**
 * 목록 커서. (SYS-004)
 *
 * <p>정렬 키 두 개를 담는다 — {@code createdAt} 과 {@code postId}. 시각만 담으면 같은 밀리초에
 * 만들어진 게시글이 두 페이지에 나오거나 한 페이지에서 사라진다.
 *
 * <p><b>클라이언트가 해석하지 않는 불투명 문자열이다.</b> Base64 로 감싸는 것은 암호화가 아니라
 * "이 값을 읽지 마라"는 신호다. 앱이 커서를 파싱해 페이지를 건너뛰기 시작하면 서버가 정렬 방식을
 * 바꿀 수 없게 된다.
 *
 * <p>위조를 막지는 않는다. 커서를 조작해도 자기 페이징만 어긋나고 남의 데이터가 보이지는 않는다 —
 * 목록 자체가 공개 범위이기 때문이다. 서명은 그 값에 비해 비용이 크다.
 */
public record PostCursor(OffsetDateTime createdAt, long postId) {

    private static final String SEPARATOR = ":";

    public String encode() {
        String raw = createdAt.toInstant().toEpochMilli() + SEPARATOR + postId;
        return Base64.getUrlEncoder().withoutPadding()
                .encodeToString(raw.getBytes(StandardCharsets.UTF_8));
    }

    /** @return 커서가 없으면 null. 형식이 깨졌으면 {@code COMMON_400} */
    public static PostCursor decode(String encoded) {
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
            long postId = Long.parseLong(raw.substring(separator + 1));
            return new PostCursor(
                    OffsetDateTime.ofInstant(Instant.ofEpochMilli(epochMilli), ZoneOffset.UTC),
                    postId);
        } catch (IllegalArgumentException malformed) {
            throw new ApiException(ErrorCode.COMMON_400, Map.of("field", "cursor"));
        }
    }
}
