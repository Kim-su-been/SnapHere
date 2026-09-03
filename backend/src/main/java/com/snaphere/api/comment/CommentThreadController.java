package com.snaphere.api.comment;

import com.snaphere.api.comment.dto.CommentResponse;
import com.snaphere.api.comment.dto.CreateCommentRequest;
import com.snaphere.api.common.security.CurrentUser;
import com.snaphere.api.common.security.CurrentUserProvider;
import com.snaphere.api.common.web.ApiResponse;
import com.snaphere.api.common.web.TraceIdFilter;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * API-CMU-006 — 대댓글 작성.
 *
 * <p>기능 명세: 5.3 댓글 &gt; 대댓글
 * <p>요구사항: CMU-014, CMU-015
 *
 * <p>댓글 ID 로 지목하는 동작은 경로가 {@code /api/v1/comments/{commentId}} 라 게시글 하위
 * 컨트롤러와 갈라 둔다. 대댓글은 부모에서 게시글을 찾아가므로 경로에 게시글 ID 가 없다 —
 * 명세가 그렇게 정의한 이유는 클라이언트가 보낸 게시글 ID 와 부모의 게시글이 다를 때 무엇을
 * 믿을지 정해야 하는 문제를 아예 만들지 않으려는 것이다.
 */
@RestController
@RequestMapping("/api/v1/comments/{commentId}")
public class CommentThreadController {

    private final CommentService commentService;
    private final CurrentUserProvider currentUserProvider;

    public CommentThreadController(CommentService commentService,
                                   CurrentUserProvider currentUserProvider) {
        this.commentService = commentService;
        this.currentUserProvider = currentUserProvider;
    }

    /**
     * 대댓글을 단다. 대댓글에 달아도 같은 스레드로 들어간다. (CMU-015)
     *
     * <p>응답의 {@code parentId} 는 요청 경로의 {@code commentId} 와 다를 수 있다 — 서버가
     * 최상위 댓글로 올렸기 때문이다. 앱은 이 값을 보고 스레드를 찾아야 한다.
     */
    @PostMapping("/replies")
    public ResponseEntity<ApiResponse<CommentResponse>> reply(
            @PathVariable long commentId,
            @Valid @RequestBody CreateCommentRequest request,
            HttpServletRequest httpRequest) {

        CurrentUser user = currentUserProvider.require(httpRequest);
        CommentResponse created = commentService.reply(commentId, user.userId(), request);

        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.ok(created, TraceIdFilter.currentTraceId(httpRequest)));
    }
}
