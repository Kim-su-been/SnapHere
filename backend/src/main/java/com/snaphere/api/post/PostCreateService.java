package com.snaphere.api.post;

import com.snaphere.api.badge.AwardedBadge;
import com.snaphere.api.badge.BadgeAwarder;
import com.snaphere.api.common.error.ApiException;
import com.snaphere.api.common.error.ErrorCode;
import com.snaphere.api.media.storage.MediaUrlResolver;
import com.snaphere.api.place.EventSnapshot;
import com.snaphere.api.place.EventSnapshotReader;
import com.snaphere.api.place.PlaceStatus;
import com.snaphere.api.place.entity.PlaceEntity;
import com.snaphere.api.place.repository.PlaceRepository;
import com.snaphere.api.post.dto.BadgeSummaryResponse;
import com.snaphere.api.post.dto.CreatePostRequest;
import com.snaphere.api.post.dto.CreatePostResponse;
import com.snaphere.api.post.dto.PlaceSummaryResponse;
import com.snaphere.api.post.dto.PostDetailResponse;
import com.snaphere.api.post.dto.PostImageRequest;
import com.snaphere.api.post.dto.PostImageResponse;
import com.snaphere.api.post.dto.PostSummaryResponse;
import com.snaphere.api.post.dto.TagSummaryResponse;
import com.snaphere.api.post.dto.TierResultResponse;
import com.snaphere.api.post.dto.UserSummaryResponse;
import com.snaphere.api.post.entity.PostEntity;
import com.snaphere.api.post.entity.PostImageEntity;
import com.snaphere.api.post.entity.PostTagEntity;
import com.snaphere.api.post.entity.TagEntity;
import com.snaphere.api.post.repository.PostImageRepository;
import com.snaphere.api.post.repository.PostRepository;
import com.snaphere.api.post.repository.PostTagRepository;
import com.snaphere.api.post.repository.TagRepository;
import com.snaphere.api.post.tier.GeoDistance;
import com.snaphere.api.post.tier.TierDecision;
import com.snaphere.api.post.tier.TierDecisionLogger;
import com.snaphere.api.post.tier.TierInput;
import com.snaphere.api.post.tier.TierPolicy;
import com.snaphere.api.post.tier.TierThresholds;
import com.snaphere.api.post.tier.VerifyRadiusResolver;
import com.snaphere.api.user.AuthorSnapshot;
import com.snaphere.api.user.AuthorSnapshotReader;
import com.snaphere.api.visit.VisitRecorder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.OffsetDateTime;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * API-PST-003 — 게시글 생성. (PST-016)
 *
 * <p>기능 명세: 2.3 사진·캡션·태그 &gt; 게시글 등록
 *
 * <p>클라이언트가 보낸 등급과 지역 코드는 쓰지 않는다. 등급은 미리보기와 같은
 * {@link TierPolicy} 로 다시 판정하고(PST-022) 지역 코드는 장소에서 역산한다(PST-018).
 * 미리보기와 실제 판정이 다르면 사용자가 속았다고 느끼므로 규칙은 한 곳에만 둔다.
 */
@Service
public class PostCreateService {

    private static final ZoneId KST = ZoneId.of("Asia/Seoul"); // SYS-005

    private final PostRepository posts;
    private final PostImageRepository postImages;
    private final PostTagRepository postTags;
    private final TagRepository tags;
    private final PlaceRepository places;
    private final EventSnapshotReader events;
    private final VerifyRadiusResolver radiusResolver;
    private final TierDecisionLogger decisionLogger;
    private final PostCreateValidator validator;
    private final TagService tagService;
    private final MediaUrlResolver mediaUrls;
    private final AuthorSnapshotReader authors;
    private final VisitRecorder visitRecorder;
    private final BadgeAwarder badgeAwarder;

    public PostCreateService(PostRepository posts,
                             PostImageRepository postImages,
                             PostTagRepository postTags,
                             TagRepository tags,
                             PlaceRepository places,
                             EventSnapshotReader events,
                             VerifyRadiusResolver radiusResolver,
                             TierDecisionLogger decisionLogger,
                             PostCreateValidator validator,
                             TagService tagService,
                             MediaUrlResolver mediaUrls,
                             AuthorSnapshotReader authors,
                             VisitRecorder visitRecorder,
                             BadgeAwarder badgeAwarder) {
        this.posts = posts;
        this.postImages = postImages;
        this.postTags = postTags;
        this.tags = tags;
        this.places = places;
        this.events = events;
        this.radiusResolver = radiusResolver;
        this.decisionLogger = decisionLogger;
        this.validator = validator;
        this.tagService = tagService;
        this.mediaUrls = mediaUrls;
        this.authors = authors;
        this.visitRecorder = visitRecorder;
        this.badgeAwarder = badgeAwarder;
    }

    @Transactional
    public CreatePostResponse create(UUID userId, CreatePostRequest request) {
        OffsetDateTime now = OffsetDateTime.now(KST);

        List<PostImageRequest> images = validator.validateImages(request, userId);
        PlaceEntity place = loadPlace(request.placeId());
        EventSnapshot event = loadEvent(request.eventId());
        validator.validateTakenAt(request, now);

        List<TagEntity> resolvedTags = tagService.resolveAll(request.tagNamesOrEmpty());
        validator.validateTagCount(resolvedTags.size());

        TierInput tierInput = buildTierInput(request, place, event, now);
        TierDecision decision = TierPolicy.decide(tierInput, TierThresholds.DEFAULT);

        // 지역 코드는 장소에서 가져온다. 요청 본문에는 애초에 받는 필드가 없다 (PST-018).
        PostEntity post = posts.save(PostEntity.create(
                userId, place.getPlaceId(), request.eventId(), place.getAreaCode(),
                request.content(), decision.tier(),
                request.lat(), request.lng(), request.takenAt(), request.source()));

        List<PostImageEntity> savedImages = saveImages(post.getPostId(), images);
        List<PostTagEntity> savedTagLinks = saveTagLinks(post.getPostId(), resolvedTags);

        decisionLogger.record(post.getPostId(), userId, place.getPlaceId(),
                request.eventId(), tierInput, decision);
        places.addPostCount(place.getPlaceId(), 1, now);

        boolean visitRecorded = visitRecorder.recordIfEligible(
                userId, place.getPlaceId(), decision.tier().countsForVisit(), now);
        List<AwardedBadge> awarded = badgeAwarder.awardForPost(
                userId, post.getPostId(), place.getPlaceId(), request.eventId(),
                decision.tier().eligibleForBadge());

        return buildResponse(post, place, savedImages, resolvedTags, savedTagLinks,
                decision, visitRecorded, awarded);
    }

    /** 장소는 필수이고, 숨김·삭제된 장소도 없는 것으로 본다 (PST-002, PLC-023). */
    private PlaceEntity loadPlace(Long placeId) {
        long id = validator.requirePlaceId(placeId);
        return places.findByPlaceIdAndStatus(id, PlaceStatus.ACTIVE)
                .orElseThrow(() -> new ApiException(ErrorCode.PLACE_NOT_FOUND,
                        Map.of("placeId", id)));
    }

    private EventSnapshot loadEvent(Long eventId) {
        if (eventId == null) {
            return null;
        }
        return events.findById(eventId)
                .orElseThrow(() -> new ApiException(ErrorCode.EVENT_NOT_FOUND,
                        Map.of("eventId", eventId)));
    }

    // ─────────────────────────────────────────────────────────── 등급 판정 (PST-022)

    private TierInput buildTierInput(CreatePostRequest request, PlaceEntity place,
                                     EventSnapshot event, OffsetDateTime now) {
        int radiusM = radiusResolver.resolve(place.toSnapshot(), event);
        Integer distanceM = null;
        if (request.hasCoordinate() && place.hasCoordinate()) {
            distanceM = GeoDistance.meters(place.getLat(), place.getLng(), request.lat(), request.lng());
        }
        return new TierInput(request.source(), request.takenAt(), distanceM, radiusM,
                place.hasCoordinate(), now);
    }

    // ─────────────────────────────────────────────────────────── 저장

    private List<PostImageEntity> saveImages(Long postId, List<PostImageRequest> images) {
        List<PostImageEntity> entities = new ArrayList<>(images.size());
        for (PostImageRequest image : images) {
            entities.add(PostImageEntity.create(
                    postId, image.imageKey(), image.sortOrder(), image.aspectRatio()));
        }
        List<PostImageEntity> saved = new ArrayList<>(postImages.saveAll(entities));
        saved.sort((a, b) -> Short.compare(a.getSortOrder(), b.getSortOrder()));
        return saved;
    }

    /**
     * 태그 연결과 사용 횟수 증가.
     *
     * <p>{@code isSuggested} 는 아직 항상 false 다. 추천 태그 자동 주입(CMU-026~029)이 들어오면
     * 그때 구분한다. {@code isLocked} 도 행사 고정 태그(EVT-018)와 함께 채운다.
     */
    private List<PostTagEntity> saveTagLinks(Long postId, List<TagEntity> resolved) {
        List<PostTagEntity> links = new ArrayList<>(resolved.size());
        List<Long> tagIds = new ArrayList<>(resolved.size());
        for (TagEntity tag : resolved) {
            links.add(PostTagEntity.of(postId, tag.getTagId(), false, false));
            tagIds.add(tag.getTagId());
        }
        List<PostTagEntity> saved = new ArrayList<>(postTags.saveAll(links));
        tags.addUsageCount(tagIds, 1);
        return saved;
    }

    // ─────────────────────────────────────────────────────────── 응답 조립

    private CreatePostResponse buildResponse(PostEntity post, PlaceEntity place,
                                             List<PostImageEntity> images,
                                             List<TagEntity> resolvedTags,
                                             List<PostTagEntity> tagLinks,
                                             TierDecision decision,
                                             boolean visitRecorded,
                                             List<AwardedBadge> awarded) {
        UserSummaryResponse author = authors.findById(post.getUserId())
                .map(UserSummaryResponse::from)
                .orElseGet(() -> UserSummaryResponse.from(
                        new AuthorSnapshot(post.getUserId(), null, null)));

        List<PostImageResponse> imageResponses = new ArrayList<>(images.size());
        for (PostImageEntity image : images) {
            imageResponses.add(PostImageResponse.from(image, mediaUrls.publicUrl(image.getImageKey())));
        }

        List<TagSummaryResponse> tagResponses = new ArrayList<>(resolvedTags.size());
        for (int i = 0; i < resolvedTags.size(); i++) {
            PostTagEntity link = i < tagLinks.size() ? tagLinks.get(i) : null;
            tagResponses.add(TagSummaryResponse.from(resolvedTags.get(i), link));
        }

        PostSummaryResponse summary = PostSummaryResponse.of(
                post, author, PlaceSummaryResponse.from(place), imageResponses);
        TierResultResponse tierResult = TierResultResponse.from(decision);
        PostDetailResponse detail = PostDetailResponse.of(
                post, summary, imageResponses, tagResponses, tierResult);

        List<BadgeSummaryResponse> badges = new ArrayList<>(awarded.size());
        for (AwardedBadge badge : awarded) {
            badges.add(BadgeSummaryResponse.from(badge));
        }
        return new CreatePostResponse(detail, tierResult, visitRecorded, badges);
    }
}
