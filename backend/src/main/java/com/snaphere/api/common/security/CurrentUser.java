package com.snaphere.api.common.security;

/** 요청을 보낸 로그인 사용자. 인증 구현(AUTH-001) 전까지는 개발용 provider 가 채운다. */
public record CurrentUser(long userId) {
}
