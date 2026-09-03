package com.snaphere.api.post.dto;

import com.snaphere.api.post.entity.PostTagEntity;
import com.snaphere.api.post.entity.TagEntity;

/**
 * 명세: 3. 응답 스키마 &gt; TagSummary
 *
 * @param locked    행사 고정 태그. 앱은 이 태그의 삭제 버튼을 감춘다 (EVT-018)
 * @param suggested 추천을 채택한 태그인지 (CMU-029)
 */
public record TagSummaryResponse(
        String tagId,
        String name,
        String themeCode,
        long usageCount,
        boolean locked,
        boolean suggested
) {
    public static TagSummaryResponse from(TagEntity tag, PostTagEntity link) {
        return new TagSummaryResponse(
                String.valueOf(tag.getTagId()),
                tag.getName(),
                tag.getThemeCode(),
                tag.getUsageCount(),
                link != null && link.isLocked(),
                link != null && link.isSuggested());
    }
}
