package com.snaphere.api.post.tag;

import com.snaphere.api.post.dto.TagSummaryResponse;
import com.snaphere.api.post.entity.TagEntity;
import com.snaphere.api.post.repository.PostTagRepository;
import com.snaphere.api.post.repository.TagRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;
import org.springframework.data.domain.Pageable;
import org.springframework.test.util.ReflectionTestUtils;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.isNull;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * 인기 태그 조회 — CMU-031
 *
 * <p>집계 순서를 응답이 그대로 지키는지, 개수 규약을 어떻게 자르는지가 이 서비스의 판단이다.
 */
@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class TagQueryServiceTest {

    @Mock private PostTagRepository postTags;
    @Mock private TagRepository tags;

    private TagQueryService service;

    @BeforeEach
    void setUp() {
        service = new TagQueryService(postTags, tags);
    }

    private static TagEntity tag(long tagId, String name) {
        TagEntity tag = TagEntity.of(name);
        ReflectionTestUtils.setField(tag, "tagId", tagId);
        ReflectionTestUtils.setField(tag, "usageCount", 9999L);
        return tag;
    }

    @Test
    @DisplayName("집계 순서를 그대로 지킨다 — findAllById 는 순서를 보장하지 않는다")
    void keepsCountedOrder() {
        when(postTags.findPopularTagCounts(isNull(), any(Pageable.class)))
                .thenReturn(List.<Object[]>of(new Object[]{2L, 10L}, new Object[]{1L, 4L}));
        // 저장소가 ID 오름차순으로 돌려주는 상황을 만든다.
        when(tags.findAllById(any())).thenReturn(List.of(tag(1L, "서울"), tag(2L, "야경")));

        List<TagSummaryResponse> popular = service.popular(null, null);

        assertThat(popular).extracting(TagSummaryResponse::name)
                .containsExactly("야경", "서울");
    }

    @Test
    @DisplayName("사용 횟수는 집계값이다 — tags.usage_count 는 지역 구분 없는 누적이라 쓰지 않는다")
    void usesCountedValue() {
        when(postTags.findPopularTagCounts(any(), any(Pageable.class)))
                .thenReturn(List.<Object[]>of(new Object[]{1L, 4L}));
        when(tags.findAllById(any())).thenReturn(List.of(tag(1L, "서울")));

        assertThat(service.popular(1, null).get(0).usageCount()).isEqualTo(4L);
    }

    @Test
    @DisplayName("개수를 안 보내면 20, 50 을 넘기면 50 으로 자른다")
    void limitContract() {
        when(postTags.findPopularTagCounts(any(), any(Pageable.class))).thenReturn(List.of());

        service.popular(null, null);
        service.popular(null, 500);

        ArgumentCaptor<Pageable> pageable = ArgumentCaptor.forClass(Pageable.class);
        verify(postTags, org.mockito.Mockito.times(2))
                .findPopularTagCounts(isNull(), pageable.capture());
        assertThat(pageable.getAllValues().get(0).getPageSize()).isEqualTo(20);
        assertThat(pageable.getAllValues().get(1).getPageSize()).isEqualTo(50);
    }

    @Test
    @DisplayName("집계가 비면 태그 조회를 하지 않는다")
    void emptyCounts() {
        when(postTags.findPopularTagCounts(any(), any(Pageable.class))).thenReturn(List.of());

        assertThat(service.popular(null, null)).isEmpty();
        verify(tags, org.mockito.Mockito.never()).findAllById(any());
    }
}
