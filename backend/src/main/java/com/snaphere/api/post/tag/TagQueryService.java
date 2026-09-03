package com.snaphere.api.post.tag;

import com.snaphere.api.post.dto.TagSummaryResponse;
import com.snaphere.api.post.entity.TagEntity;
import com.snaphere.api.post.repository.PostTagRepository;
import com.snaphere.api.post.repository.TagRepository;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * API-CMU-012 — 인기 태그 조회.
 *
 * <p>기능 명세: 해당 없음 — 인기 태그 목록은 화면 정의에 없다. 태그 검색(1.2 검색 > 태그 검색)의
 * 진입을 돕는 조회다
 * <p>요구사항: CMU-031
 */
@Service
public class TagQueryService {

    /** 명세 기본 20 · 최대 50. 페이징 규약과 같은 값이지만 커서가 없는 목록이라 따로 둔다. */
    private static final int DEFAULT_LIMIT = 20;
    private static final int MAX_LIMIT = 50;

    private final PostTagRepository postTags;
    private final TagRepository tags;

    public TagQueryService(PostTagRepository postTags, TagRepository tags) {
        this.postTags = postTags;
        this.tags = tags;
    }

    /**
     * 지역별 인기 태그. {@code areaCode} 를 생략하면 전국이다. (CMU-031)
     *
     * <p>집계 순서를 응답 순서로 그대로 옮긴다 — {@code findAllById} 는 순서를 보장하지 않으므로
     * ID 목록으로 다시 줄을 세운다. 이걸 빼면 인기 순위가 조회마다 뒤섞인다.
     */
    @Transactional(readOnly = true)
    public List<TagSummaryResponse> popular(Integer areaCode, Integer requestedLimit) {
        int limit = resolveLimit(requestedLimit);

        List<Object[]> counted = postTags.findPopularTagCounts(areaCode, PageRequest.of(0, limit));
        if (counted.isEmpty()) {
            return List.of();
        }

        Map<Long, Long> countByTagId = new LinkedHashMap<>();
        for (Object[] row : counted) {
            countByTagId.put(((Number) row[0]).longValue(), ((Number) row[1]).longValue());
        }

        Map<Long, TagEntity> found = new LinkedHashMap<>();
        for (TagEntity tag : tags.findAllById(countByTagId.keySet())) {
            found.put(tag.getTagId(), tag);
        }

        List<TagSummaryResponse> result = new ArrayList<>(countByTagId.size());
        for (Map.Entry<Long, Long> entry : countByTagId.entrySet()) {
            TagEntity tag = found.get(entry.getKey());
            if (tag != null) {
                result.add(TagSummaryResponse.popular(tag, entry.getValue()));
            }
        }
        return result;
    }

    /**
     * 잘못된 개수를 400 으로 돌려주지 않고 조용히 자른다. 목록이 크기 때문에 실패하면 앱이 화면을
     * 못 그린다 — PagingProperties 와 같은 판단이다.
     */
    private int resolveLimit(Integer requested) {
        if (requested == null || requested <= 0) {
            return DEFAULT_LIMIT;
        }
        return Math.min(requested, MAX_LIMIT);
    }
}
