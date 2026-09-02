package com.snaphere.api.post.dto;

import com.snaphere.api.post.entity.PostImageEntity;

import java.math.BigDecimal;

/**
 * 명세: 3. 응답 스키마 &gt; PostImage
 *
 * <p>{@code thumbnailUrl} 은 후처리 배치(JOB-003)가 채우기 전까지 비어 있어, 그동안은 원본 주소를
 * 대신 준다. 앱이 null 을 받아 빈 카드를 그리는 것보다 낫다 (PST-019).
 */
public record PostImageResponse(
        String postImageId,
        String imageUrl,
        String thumbnailUrl,
        BigDecimal aspectRatio,
        int sortOrder
) {
    /** 후처리 전 기본 비율. 세로형 사진이 흔해 4:5 를 쓴다 (PST-021). */
    public static final BigDecimal DEFAULT_ASPECT_RATIO = new BigDecimal("0.8000");

    public static PostImageResponse from(PostImageEntity image, String imageUrl) {
        String thumbnail = image.getThumbnailUrl() == null ? imageUrl : image.getThumbnailUrl();
        BigDecimal ratio = image.getAspectRatio() == null ? DEFAULT_ASPECT_RATIO : image.getAspectRatio();
        return new PostImageResponse(
                String.valueOf(image.getPostImageId()), imageUrl, thumbnail, ratio, image.getSortOrder());
    }
}
