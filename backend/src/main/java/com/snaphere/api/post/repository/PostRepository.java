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

    /**
     * 목록 조회. 지역·장소·태그·기간을 조합한다. (PST-034)
     *
     * <p>필터는 전부 선택이고 null 이면 조건에서 빠진다. 조합마다 메서드를 따로 두면
     * 커서 비교 조건을 여러 곳에 복사하게 되고, 한 곳만 고치면 페이징이 어긋난다.
     *
     * <p>{@code areaCode} 만 준 경우 {@code idx_posts_area_created} 부분 인덱스를 탄다
     * (CMU-001, PLC-013).
     *
     * <p>태그는 ID 로 받는다. 정규화 이름 → ID 변환은 조회 전에 한 번만 하면 되고,
     * 그 이름을 쓴 태그가 없으면 애초에 이 쿼리를 돌릴 필요가 없다 (CMU-030).
     */
    @Query("""
            select p from PostEntity p
             where p.status = com.snaphere.api.post.PostStatus.ACTIVE
               and (:areaCode is null or p.areaCode = :areaCode)
               and (:placeId is null or p.placeId = :placeId)
               and (:createdFrom is null or p.createdAt >= :createdFrom)
               and (:tagId is null
                    or exists (select pt.id.postId from PostTagEntity pt
                                where pt.id.postId = p.postId and pt.id.tagId = :tagId))
               and (:cursorCreatedAt is null
                    or p.createdAt < :cursorCreatedAt
                    or (p.createdAt = :cursorCreatedAt and p.postId < :cursorPostId))
             order by p.createdAt desc, p.postId desc
            """)
    List<PostEntity> findFeed(@Param("areaCode") Integer areaCode,
                              @Param("placeId") Long placeId,
                              @Param("tagId") Long tagId,
                              @Param("createdFrom") OffsetDateTime createdFrom,
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

    /** 조회수 증가. 엔티티를 읽어 고치면 같은 게시글 동시 조회에서 값이 밀린다. (PST-042) */
    @Modifying
    @Query("update PostEntity p set p.viewCount = p.viewCount + 1 where p.postId = :postId")
    int increaseViewCount(@Param("postId") Long postId);

    @Modifying
    @Query("update PostEntity p set p.likeCount = p.likeCount + :delta where p.postId = :postId")
    int addLikeCount(@Param("postId") Long postId, @Param("delta") int delta);

    @Modifying
    @Query("update PostEntity p set p.commentCount = p.commentCount + :delta where p.postId = :postId")
    int addCommentCount(@Param("postId") Long postId, @Param("delta") int delta);
}
