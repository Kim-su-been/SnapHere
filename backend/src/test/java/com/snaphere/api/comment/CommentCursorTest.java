package com.snaphere.api.comment;

import com.snaphere.api.common.error.ApiException;
import com.snaphere.api.common.error.ErrorCode;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.time.OffsetDateTime;
import java.time.ZoneOffset;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * 댓글 목록 커서 — CMU-013, CMU-010
 */
class CommentCursorTest {

    @Test
    @DisplayName("두 정렬 키가 왕복해도 그대로 살아 있다")
    void roundTrip() {
        OffsetDateTime at = OffsetDateTime.of(2026, 9, 3, 12, 0, 0, 0, ZoneOffset.UTC);
        CommentCursor decoded = CommentCursor.decode(new CommentCursor(at, 42L).encode());

        assertThat(decoded.commentId()).isEqualTo(42L);
        assertThat(decoded.createdAt().toInstant()).isEqualTo(at.toInstant());
    }

    @Test
    @DisplayName("커서가 없으면 null — 첫 페이지다")
    void absent() {
        assertThat(CommentCursor.decode(null)).isNull();
        assertThat(CommentCursor.decode("   ")).isNull();
    }

    @Test
    @DisplayName("깨진 커서는 500 이 아니라 400 이다")
    void malformed() {
        assertThatThrownBy(() -> CommentCursor.decode("!!!not-base64!!!"))
                .isInstanceOf(ApiException.class)
                .satisfies(t -> assertThat(((ApiException) t).errorCode())
                        .isEqualTo(ErrorCode.COMMON_400));
    }
}
