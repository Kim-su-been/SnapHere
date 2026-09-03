package com.snaphere.api.post.repository;

import com.snaphere.api.post.entity.PostTagEntity;
import com.snaphere.api.post.entity.PostTagId;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Collection;
import java.util.List;

/** 게시글-태그 연결. (PST-004, CMU-032) */
public interface PostTagRepository extends JpaRepository<PostTagEntity, PostTagId> {

    List<PostTagEntity> findByIdPostId(Long postId);

    /** 목록·상세 응답의 태그를 한 번에. 게시글마다 조회하면 N+1 이다 (SYS-018). */
    List<PostTagEntity> findByIdPostIdIn(Collection<Long> postIds);

    /** 게시글 수정 시 전부 지우고 다시 넣는다. 차이 계산은 버그를 부른다. (CMU-032) */
    void deleteByIdPostId(Long postId);
}
