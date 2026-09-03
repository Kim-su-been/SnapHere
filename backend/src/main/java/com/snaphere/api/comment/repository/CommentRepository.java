package com.snaphere.api.comment.repository;

import com.snaphere.api.comment.CommentStatus;
import com.snaphere.api.comment.entity.CommentEntity;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.OffsetDateTime;
import java.util.Collection;
import java.util.List;
import java.util.Optional;

/** 댓글 조회. (CMU-013, CMU-014, CMU-016, CMU-017) */
public interface CommentRepository extends JpaRepository<CommentEntity, Long> {

    Optional<CommentEntity> findByCommentIdAndStatus(Long commentId, CommentStatus status);

    /**
     * 최상위 댓글 한 페이지. 최신순이다. (CMU-013, CMU-010)
     *
     * <p>커서는 {@code (createdAt, commentId)} 두 키를 함께 본다 — 시각만 쓰면 같은 순간에 달린
     * 댓글이 두 페이지에 나오거나 사라진다.
     *
     * <p>삭제된 최상위 댓글도 살아 있는 자식이 있으면 남긴다. 자리표시자를 빼면 대댓글만 붕 떠서
     * 대화의 앞뒤가 끊긴다 (CMU-017).
     */
    @Query("""
            select c from CommentEntity c
             where c.postId = :postId
               and c.parentId is null
               and (c.status = com.snaphere.api.comment.CommentStatus.ACTIVE
                    or exists (select r.commentId from CommentEntity r
                                where r.parentId = c.commentId
                                  and r.status = com.snaphere.api.comment.CommentStatus.ACTIVE))
               and (:cursorCreatedAt is null
                    or c.createdAt < :cursorCreatedAt
                    or (c.createdAt = :cursorCreatedAt and c.commentId < :cursorCommentId))
             order by c.createdAt desc, c.commentId desc
            """)
    List<CommentEntity> findRoots(@Param("postId") Long postId,
                                  @Param("cursorCreatedAt") OffsetDateTime cursorCreatedAt,
                                  @Param("cursorCommentId") Long cursorCommentId,
                                  Pageable pageable);

    /**
     * 부모 여러 개의 대댓글을 한 번에 가져온다. (CMU-013)
     *
     * <p>부모마다 따로 조회하면 페이지 크기만큼 쿼리가 나간다 — 명세가 IN 절 일괄 조회를 못 박은
     * 이유다. 대댓글은 오래된 순이다: 대화는 위에서 아래로 읽힌다.
     */
    @Query("""
            select c from CommentEntity c
             where c.parentId in :parentIds
               and c.status = com.snaphere.api.comment.CommentStatus.ACTIVE
             order by c.createdAt asc, c.commentId asc
            """)
    List<CommentEntity> findRepliesOf(@Param("parentIds") Collection<Long> parentIds);

    boolean existsByParentIdAndStatus(Long parentId, CommentStatus status);

    @Modifying
    @Query("update CommentEntity c set c.likeCount = c.likeCount + :delta where c.commentId = :commentId")
    int addLikeCount(@Param("commentId") Long commentId, @Param("delta") int delta);
}
