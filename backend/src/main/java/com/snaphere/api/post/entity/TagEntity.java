package com.snaphere.api.post.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

import java.time.OffsetDateTime;
import java.util.Locale;

/**
 * 해시태그 마스터. (CMU-025)
 *
 * <p>{@code normalizedName} 이 유일 키다. 표시용 원문({@code name})은 대소문자·공백이 달라도
 * 같은 태그로 묶기 위해 따로 둔다.
 */
@Entity
@Table(name = "tags")
public class TagEntity {

    public static final int MAX_NAME_LENGTH = 50;

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "tag_id")
    private Long tagId;

    @Column(name = "name", nullable = false, length = MAX_NAME_LENGTH)
    private String name;

    @Column(name = "normalized_name", nullable = false, length = MAX_NAME_LENGTH)
    private String normalizedName;

    /** K-컬처 테마 랭킹 키. 사용자가 직접 쓴 태그도 집계 대상이다. (RNK-005) */
    @Column(name = "theme_code", length = 30)
    private String themeCode;

    @Column(name = "usage_count", nullable = false)
    private long usageCount;

    @Column(name = "created_at", nullable = false)
    private OffsetDateTime createdAt;

    protected TagEntity() {
    }

    public static TagEntity of(String rawName) {
        TagEntity tag = new TagEntity();
        tag.name = rawName.strip();
        tag.normalizedName = normalize(rawName);
        tag.createdAt = OffsetDateTime.now();
        return tag;
    }

    /** 소문자 변환 + 공백 제거. 앞의 '#' 도 떼어 낸다. (CMU-025) */
    public static String normalize(String rawName) {
        String value = rawName.strip();
        if (value.startsWith("#")) {
            value = value.substring(1);
        }
        return value.replaceAll("\\s+", "").toLowerCase(Locale.ROOT);
    }

    public Long getTagId() {
        return tagId;
    }

    public String getName() {
        return name;
    }

    public String getNormalizedName() {
        return normalizedName;
    }

    public String getThemeCode() {
        return themeCode;
    }

    public long getUsageCount() {
        return usageCount;
    }
}
