package com.snaphere.api.post.repository;

import com.snaphere.api.post.entity.PostImageEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.UUID;

/** 게시글 사진 조회. (PST-001, PST-021, PST-031) */
public interface PostImageRepository extends JpaRepository<PostImageEntity, Long> {

    List<PostImageEntity> findByPostIdOrderBySortOrder(Long postId);

    /** 목록 응답의 대표 사진 비율을 한 번에 가져온다 — 카드마다 조회하면 N+1 이다. (PST-021) */
    List<PostImageEntity> findByPostIdInAndSortOrderOrderByPostId(List<Long> postIds, short sortOrder);

    /**
     * 본인 계정 안에서 같은 이미지 해시를 이미 올렸는지. (PST-031)
     *
     * <p>해시는 후처리 배치가 채우므로(PST-019) 아직 null 인 사진은 판정 대상이 아니다.
     */
    @Query("""
            select count(i) from PostImageEntity i, PostEntity p
             where i.postId = p.postId
               and p.userId = :userId
               and i.imageHash = :imageHash
               and p.status <> com.snaphere.api.post.PostStatus.DELETED
            """)
    long countSameHashOwnedBy(@Param("userId") UUID userId, @Param("imageHash") String imageHash);

    void deleteByPostId(Long postId);
}
