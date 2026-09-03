package com.snaphere.api.post.repository;

import com.snaphere.api.post.entity.TagEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.Collection;
import java.util.List;
import java.util.Optional;

/** 해시태그 마스터 조회. (CMU-025, CMU-030, CMU-031) */
public interface TagRepository extends JpaRepository<TagEntity, Long> {

    Optional<TagEntity> findByNormalizedName(String normalizedName);

    List<TagEntity> findByNormalizedNameIn(Collection<String> normalizedNames);

    @Modifying
    @Query("update TagEntity t set t.usageCount = t.usageCount + :delta where t.tagId in :tagIds")
    int addUsageCount(@Param("tagIds") Collection<Long> tagIds, @Param("delta") int delta);
}
