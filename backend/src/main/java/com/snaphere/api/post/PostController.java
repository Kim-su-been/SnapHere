package com.snaphere.api.post;

import com.snaphere.api.common.security.CurrentUser;
import com.snaphere.api.common.security.CurrentUserProvider;
import com.snaphere.api.common.web.ApiResponse;
import com.snaphere.api.common.web.TraceIdFilter;
import com.snaphere.api.post.dto.CreatePostRequest;
import com.snaphere.api.post.dto.CreatePostResponse;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * API-PST-003 — 게시글 생성.
 *
 * <p>기능 명세: 2.3 사진·캡션·태그 &gt; 게시글 등록
 * <p>요구사항: PST-001 ~ PST-004, PST-016 ~ PST-018, PST-021
 *
 * <p>등급 미리보기(API-PST-002)는 {@link PostTierController} 에 있다. 같은 경로 접두어를 쓰지만
 * 미리보기는 아무것도 만들지 않는 조회성 호출이라 분리해 둔다.
 */
@RestController
@RequestMapping("/api/v1/posts")
public class PostController {

    private final PostCreateService postCreateService;
    private final CurrentUserProvider currentUserProvider;

    public PostController(PostCreateService postCreateService,
                          CurrentUserProvider currentUserProvider) {
        this.postCreateService = postCreateService;
        this.currentUserProvider = currentUserProvider;
    }

    @PostMapping
    public ResponseEntity<ApiResponse<CreatePostResponse>> create(
            @Valid @RequestBody CreatePostRequest request,
            HttpServletRequest httpRequest) {

        CurrentUser user = currentUserProvider.require(httpRequest);
        CreatePostResponse created = postCreateService.create(user.userId(), request);

        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.ok(created, TraceIdFilter.currentTraceId(httpRequest)));
    }
}
