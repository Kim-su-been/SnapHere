package com.snaphere.api.feed;

import com.snaphere.api.common.web.ApiResponse;
import com.snaphere.api.common.web.CursorPage;
import com.snaphere.api.common.web.TraceIdFilter;
import com.snaphere.api.post.dto.PostSummaryResponse;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/**
 * API-CMU-003 — 최근 피드.
 *
 * <p>기능 명세: 1.1 피드 &gt; 최근 피드
 * <p>요구사항: CMU-003, CMU-010
 *
 * <p>인기 피드(API-CMU-001)와 팔로잉 피드(API-CMU-002)은 아직 없다. 인기 피드는 팔로잉 가중치가
 * 필요하고(CMU-009) 팔로잉 피드는 {@code follows} 테이블이 필요해서, 둘 다 SOC 도메인이 생긴 뒤에
 * 이 컨트롤러에 붙인다 — 경로 접두어를 지금 잡아 두는 편이 나중에 옮기는 것보다 싸다.
 *
 * <p>지도·탐색의 게시글 목록(API-PST-004)과 역할이 다르다. 이쪽은 필터 없는 시간순이고,
 * 그쪽은 지역·장소·태그·기간 필터가 붙는다.
 */
@RestController
@RequestMapping("/api/v1/feeds")
public class FeedController {

    private final FeedService feedService;

    public FeedController(FeedService feedService) {
        this.feedService = feedService;
    }

    @GetMapping("/recent")
    public ResponseEntity<ApiResponse<CursorPage<PostSummaryResponse>>> recent(
            @RequestParam(required = false) String cursor,
            @RequestParam(required = false) Integer size,
            HttpServletRequest httpRequest) {

        CursorPage<PostSummaryResponse> page = feedService.recent(cursor, size);

        return ResponseEntity.ok(ApiResponse.ok(page,
                TraceIdFilter.currentTraceId(httpRequest)));
    }
}
