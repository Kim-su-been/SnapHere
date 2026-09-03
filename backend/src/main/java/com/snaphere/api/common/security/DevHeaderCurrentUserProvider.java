package com.snaphere.api.common.security;

import com.snaphere.api.common.error.ApiException;
import com.snaphere.api.common.error.ErrorCode;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;

/**
 * 임시 구현. {@code X-Debug-User-Id} 헤더를 사용자로 취급한다.
 *
 * <p><b>인증(AUTH-001, AUTH-007)이 구현되면 이 클래스는 삭제한다.</b>
 * 그때까지 게시글·미디어 기능을 혼자 개발·테스트할 수 있게 두는 임시 통로이며,
 * 운영 프로파일에서는 절대 활성화하지 않는다.
 */
@Component
public class DevHeaderCurrentUserProvider implements CurrentUserProvider {

    public static final String HEADER = "X-Debug-User-Id";

    @Override
    public CurrentUser require(HttpServletRequest request) {
        String raw = request.getHeader(HEADER);
        if (!StringUtils.hasText(raw)) {
            throw new ApiException(ErrorCode.AUTH_REQUIRED);
        }
        try {
            return new CurrentUser(Long.parseLong(raw.trim()));
        } catch (NumberFormatException e) {
            throw new ApiException(ErrorCode.AUTH_REQUIRED);
        }
    }
}
