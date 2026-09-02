package com.snaphere.api.post.repository;

import com.snaphere.api.post.PostStatus;
import com.snaphere.api.post.entity.PostEntity;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * 게시글 조회.
 *
 * <p>목록은 전부 커서 기반이다 (SYS-003). {@code createdAt} 이 같은 행이 있을 수 있어
 * {@code postId} 를 2차 키로 함께 비교한다 — 그러지 않으면 같은 행이 두 페이지에 나온다.
 */
public interface PostRepository extends JpaRepository<PostEntity, Long> {

    Optional<PostEntity> findByPostIdAndStatus(Long postId, PostStatus status);

    /** 지역 커뮤니티 최신순. {@code idx_posts_area_created} 부분 인덱스를 탄다. (CMU-001) */
    @Query("""
            select p from PostEntity p
             where p.areaCode = :areaCode
               and p.status = com.snaphere.api.post.PostStatus.ACTIVE
               and (:cursorCreatedAt is null
                    or p.createdAt < :cursorCreatedAt
                    or (p.createdAt = :cursorCreatedAt and p.postId < :cursorPostId))
             order by p.createdAt desc, p.postId desc
            """)
    List<PostEntity> findRegionFeed(@Param("areaCode") Integer areaCode,
                                    @Param("cursorCreatedAt") OffsetDateTime cursorCreatedAt,
                                    @Param("cursorPostId") Long cursorPostId,
                                    Pageable pageable);

    /** 장소 상세의 게시글 그리드. (PLC-013) */
    List<PostEntity> findByPlaceIdAndStatusOrderByCreatedAtDescPostIdDesc(
            Long placeId, PostStatus status, Pageable pageable);

    /** 프로필 그리드. (USER-008) */
    List<PostEntity> findByUserIdAndStatusOrderByCreatedAtDescPostIdDesc(
            UUID userId, PostStatus status, Pageable pageable);

    /** 하루 업로드 한도 판정. 기준일은 Asia/Seoul 자정이다 (SYS-005) — 호출자가 경계를 넘긴다. */
    long countByUserIdAndStatusAndCreatedAtGreaterThanEqual(
            UUID userId, PostStatus status, OffsetDateTime from);

    /** 같은 장소 하루 한도 판정. (PST-030) */
    long countByUserIdAndPlaceIdAndStatusAndCreatedAtGreaterThanEqual(
            UUID userId, Long placeId, PostStatus status, OffsetDateTime from);

    @Modifying
    @Query("update PostEntity p set p.likeCount = p.likeCount + :delta where p.postId = :postId")
    int addLikeCount(@Param("postId") Long postId, @Param("delta") int delta);

    @Modifying
    @Query("update PostEntity p set p.commentCount = p.commentCount + :delta where p.postId = :postId")
    int addCommentCount(@Param("postId") Long postId, @Param("delta") int delta);
}
