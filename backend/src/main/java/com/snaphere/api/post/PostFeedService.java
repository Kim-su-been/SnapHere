package com.snaphere.api.post;

import com.snaphere.api.common.web.CursorPage;
import com.snaphere.api.common.web.PagingProperties;
import com.snaphere.api.post.dto.PostSummaryResponse;
import com.snaphere.api.post.entity.PostEntity;
import com.snaphere.api.post.entity.TagEntity;
import com.snaphere.api.post.repository.PostRepository;
import com.snaphere.api.post.repository.TagRepository;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.OffsetDateTime;
import java.time.ZoneId;
import java.util.List;

/**
 * API-PST-004 — 게시글 목록 조회. (PST-034)
 *
 * <p>기능 명세: 4.1 지역 커뮤니티 · 5.1 본문
 *
 * <p>비회원도 조회할 수 있고, 삭제·블라인드 게시글은 목록에서 제외된다.
 */
@Service
public class PostFeedService {

    private static final ZoneId KST = ZoneId.of("Asia/Seoul"); // SYS-005

    private final PostRepository posts;
    private final TagRepository tags;
    private final PostResponseAssembler assembler;
    private final PagingProperties paging;

    public PostFeedService(PostRepository posts,
                           TagRepository tags,
                           PostResponseAssembler assembler,
                           PagingProperties paging) {
        this.posts = posts;
        this.tags = tags;
        this.assembler = assembler;
        this.paging = paging;
    }

    @Transactional(readOnly = true)
    public CursorPage<PostSummaryResponse> list(Integer areaCode, Long placeId, String tag,
                                                PostFeedPeriod period, String cursor, Integer size) {
        Long tagId = resolveTagId(tag);
        if (tag != null && !tag.isBlank() && tagId == null) {
            // 아무도 쓰지 않은 태그다. 에러가 아니라 결과가 없는 것이다 (CMU-030).
            return CursorPage.empty();
        }

        int pageSize = paging.resolve(size);
        PostCursor decoded = PostCursor.decode(cursor);
        OffsetDateTime createdFrom = (period == null ? PostFeedPeriod.DEFAULT : period)
                .from(OffsetDateTime.now(KST));

        // 한 건 더 읽어 다음 페이지가 있는지 본다. COUNT 를 따로 세면 같은 조건을 두 번 훑는다.
        List<PostEntity> rows = posts.findFeed(areaCode, placeId, tagId, createdFrom,
                decoded == null ? null : decoded.createdAt(),
                decoded == null ? null : decoded.postId(),
                PageRequest.of(0, pageSize + 1));

        boolean hasNext = rows.size() > pageSize;
        List<PostEntity> page = hasNext ? rows.subList(0, pageSize) : rows;
        if (page.isEmpty()) {
            return CursorPage.empty();
        }

        PostEntity last = page.get(page.size() - 1);
        String nextCursor = hasNext
                ? new PostCursor(last.getCreatedAt(), last.getPostId()).encode()
                : null;
        return CursorPage.of(assembler.summaries(page), nextCursor);
    }

    private Long resolveTagId(String tag) {
        if (tag == null || tag.isBlank()) {
            return null;
        }
        return tags.findByNormalizedName(TagEntity.normalize(tag))
                .map(TagEntity::getTagId)
                .orElse(null);
    }

    /** 장소 상세의 게시글 그리드. (PLC-013) */
    @Transactional(readOnly = true)
    public CursorPage<PostSummaryResponse> listByPlace(long placeId, String cursor, Integer size) {
        return list(null, placeId, null, PostFeedPeriod.ALL, cursor, size);
    }

}
