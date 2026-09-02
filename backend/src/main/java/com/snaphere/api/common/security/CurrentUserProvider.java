package com.snaphere.api.common.security;

import jakarta.servlet.http.HttpServletRequest;

/**
 * 현재 요청의 로그인 사용자를 알려준다. (AUTH-011)
 *
 * <p>구글 로그인·JWT 검증(AUTH-001, AUTH-007)이 들어오면 이 인터페이스의 구현만 바꾼다.
 * 도메인 코드는 사용자 식별 방법을 몰라도 되도록 여기서 끊는다.
 */
public interface CurrentUserProvider {

    /** 로그인 사용자를 반환한다. 없으면 AUTH_REQUIRED 로 막는다. */
    CurrentUser require(HttpServletRequest request);
}
