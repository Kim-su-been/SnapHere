package com.snaphere.api.post;

import com.snaphere.api.common.security.CurrentUser;
import com.snaphere.api.common.security.CurrentUserProvider;
import com.snaphere.api.common.web.ApiResponse;
import com.snaphere.api.common.web.TraceIdFilter;
import com.snaphere.api.post.dto.PostDetailResponse;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Optional;
import java.util.UUID;

/**
 * API-PST-006 — 게시글 상세 조회.
 *
 * <p>기능 명세: 5.1 본문
 * <p>요구사항: PST-033, PST-042, SOC-013
 *
 * <p>{@code GET /api/v1/**} 는 SecurityConfig 에서 permitAll 이라 토큰 없이 들어온다.
 * 그래서 {@code require} 가 아니라 {@code optional} 을 쓴다 — {@code require} 를 쓰면
 * 비회원 조회가 401 이 된다 (PST-033).
 */
@RestController
@RequestMapping("/api/v1/posts")
public class PostQueryController {

    private final PostQueryService postQueryService;
    private final CurrentUserProvider currentUserProvider;

    public PostQueryController(PostQueryService postQueryService,
                               CurrentUserProvider currentUserProvider) {
        this.postQueryService = postQueryService;
        this.currentUserProvider = currentUserProvider;
    }

    @GetMapping("/{postId}")
    public ResponseEntity<ApiResponse<PostDetailResponse>> detail(
            @PathVariable long postId,
            HttpServletRequest httpRequest) {

        Optional<UUID> viewerId = currentUserProvider.optional(httpRequest)
                .map(CurrentUser::userId);
        PostDetailResponse detail = postQueryService.detail(postId, viewerId);

        return ResponseEntity.ok(ApiResponse.ok(detail,
                TraceIdFilter.currentTraceId(httpRequest)));
    }
}
