package com.snaphere.api.post.dto;

import com.snaphere.api.place.entity.PlaceEntity;

/**
 * 명세: 3. 응답 스키마 &gt; PlaceSummary
 *
 * <p>{@code distanceM}·{@code isVerifiable} 은 주변 검색에서만 채우는 계산 필드라 게시글 응답에서는
 * 넣지 않는다.
 */
public record PlaceSummaryResponse(
        String placeId,
        String placeType,
        String title,
        String addr1,
        Double lat,
        Double lng,
        int postCount,
        int visitCount
) {
    public static PlaceSummaryResponse from(PlaceEntity place) {
        return new PlaceSummaryResponse(
                String.valueOf(place.getPlaceId()),
                place.getPlaceType().name(),
                place.getTitle(),
                place.getAddr1(),
                place.getLat(),
                place.getLng(),
                place.getPostCount(),
                place.getVisitCount());
    }
}
