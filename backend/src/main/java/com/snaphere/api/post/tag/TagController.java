package com.snaphere.api.post.tag;

import com.snaphere.api.common.web.ApiResponse;
import com.snaphere.api.common.web.CursorPage;
import com.snaphere.api.common.web.TraceIdFilter;
import com.snaphere.api.post.dto.PostSummaryResponse;
import com.snaphere.api.post.dto.TagSummaryResponse;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.http.CacheControl;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.time.Duration;
import java.util.List;

/**
 * API-CMU-012 · API-CMU-013 — 인기 태그·태그 게시글.
 *
 * <p>기능 명세: 1.2 검색 &gt; 태그 검색
 * <p>요구사항: CMU-030, CMU-031, SCH-007
 */
@RestController
@RequestMapping("/api/v1/tags")
public class TagController {

    /** 명세의 캐시 10m. 인기 태그는 몇 분 늦어도 되는 값이고 매 요청 집계는 비싸다. */
    private static final Duration CACHE_TTL = Duration.ofMinutes(10);

    private final TagQueryService tagQueryService;

    public TagController(TagQueryService tagQueryService) {
        this.tagQueryService = tagQueryService;
    }

    @GetMapping("/popular")
    public ResponseEntity<ApiResponse<List<TagSummaryResponse>>> popular(
            @RequestParam(required = false) Integer areaCode,
            @RequestParam(required = false) Integer limit,
            HttpServletRequest httpRequest) {

        List<TagSummaryResponse> tags = tagQueryService.popular(areaCode, limit);

        return ResponseEntity.ok()
                .cacheControl(CacheControl.maxAge(CACHE_TTL).cachePublic())
                .body(ApiResponse.ok(tags, TraceIdFilter.currentTraceId(httpRequest)));
    }

    /**
     * 태그가 붙은 공개 게시글. (CMU-030)
     *
     * <p>인기 태그와 달리 캐시를 두지 않는다. 태그를 눌러 들어온 목록은 방금 올린 내 글이 보여야
     * 하는 자리다.
     */
    @GetMapping("/{tagId}/posts")
    public ResponseEntity<ApiResponse<CursorPage<PostSummaryResponse>>> posts(
            @PathVariable long tagId,
            @RequestParam(required = false) String cursor,
            @RequestParam(required = false) Integer size,
            HttpServletRequest httpRequest) {

        CursorPage<PostSummaryResponse> page = tagQueryService.postsByTag(tagId, cursor, size);

        return ResponseEntity.ok(ApiResponse.ok(page,
                TraceIdFilter.currentTraceId(httpRequest)));
    }
}
