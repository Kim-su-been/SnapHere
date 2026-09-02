package com.snaphere.api.report;

import com.snaphere.api.common.error.ApiException;
import com.snaphere.api.common.error.ErrorCode;
import com.snaphere.api.post.PostStatus;
import com.snaphere.api.post.entity.PostEntity;
import com.snaphere.api.post.repository.PostRepository;
import com.snaphere.api.report.dto.CreateReportRequest;
import com.snaphere.api.report.dto.ReportReceiptResponse;
import com.snaphere.api.report.entity.ReportEntity;
import com.snaphere.api.report.repository.ReportRepository;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Map;
import java.util.UUID;

/**
 * API-PST-013 — 게시글 신고. (PST-043, PST-044)
 *
 * <p>기능 명세: 5.5 관리 &gt; 신고
 *
 * <p>대상 존재 확인을 애플리케이션이 한다. {@code reports.target_id} 는 게시글과 장소를 함께
 * 담아 외래키를 걸 수 없다.
 */
@Service
public class PostReportService {

    private final ReportRepository reports;
    private final PostRepository posts;

    public PostReportService(ReportRepository reports, PostRepository posts) {
        this.reports = reports;
        this.posts = posts;
    }

    @Transactional
    public ReportReceiptResponse report(long postId, UUID reporterId, CreateReportRequest request) {
        requireReportablePost(postId);
        requireNotReportedBefore(postId, reporterId);

        try {
            ReportEntity saved = reports.saveAndFlush(ReportEntity.of(
                    reporterId, ReportTargetType.POST, postId,
                    request.reason(), request.detail()));
            return ReportReceiptResponse.from(saved);
        } catch (DataIntegrityViolationException duplicated) {
            // 같은 사람이 연달아 눌러 UNIQUE 가 튕겼다. 사전 검사와 같은 결과를 준다 (PST-044).
            throw new ApiException(ErrorCode.REPORT_DUPLICATE, Map.of("postId", postId));
        }
    }

    /**
     * 같은 사람이 같은 대상을 두 번 신고할 수 없다. (PST-044)
     *
     * <p>먼저 조회해서 걸러 내는 것은 사용자에게 명확한 코드를 주기 위한 것이고, 실제 보장은
     * UNIQUE 제약이 한다 — 조회와 삽입 사이에 다른 요청이 끼어들 수 있다.
     */
    private void requireNotReportedBefore(long postId, UUID reporterId) {
        if (reports.existsByReporterIdAndTargetTypeAndTargetId(
                reporterId, ReportTargetType.POST, postId)) {
            throw new ApiException(ErrorCode.REPORT_DUPLICATE, Map.of("postId", postId));
        }
    }

    /**
     * 신고할 수 있는 게시글인지.
     *
     * <p>이미 가려진 게시글도 신고를 받는다. 자동 블라인드는 임시 조치이고 운영자가 복구할 수
     * 있으므로(SYS-017), 그 사이에 들어온 신고를 버리면 누적 판단의 근거가 사라진다.
     * 삭제된 게시글은 되돌아오지 않으므로 받지 않는다.
     */
    private PostEntity requireReportablePost(long postId) {
        PostEntity post = posts.findById(postId)
                .orElseThrow(() -> new ApiException(ErrorCode.POST_NOT_FOUND,
                        Map.of("postId", postId)));
        if (post.getStatus() == PostStatus.DELETED) {
            throw new ApiException(ErrorCode.POST_NOT_FOUND, Map.of("postId", postId));
        }
        return post;
    }
}
