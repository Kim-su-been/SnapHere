package com.snaphere.api.auth;

import com.snaphere.api.common.error.ApiException;
import com.snaphere.api.common.error.ErrorCode;
import org.springframework.security.core.Authentication;
import org.springframework.security.oauth2.jwt.Jwt;

public record CurrentActor(long userId, String externalId, String role, String deviceId) {
    public static CurrentActor required(Authentication authentication) {
        if (authentication == null || !(authentication.getPrincipal() instanceof Jwt jwt)) {
            throw new ApiException(ErrorCode.AUTH_REQUIRED);
        }
        return new CurrentActor(
                ExternalIds.parse(jwt.getSubject(), "usr", ErrorCode.AUTH_REQUIRED),
                jwt.getSubject(), jwt.getClaimAsString("role"), jwt.getClaimAsString("device_id"));
    }

    public static CurrentActor optional(Authentication authentication) {
        return authentication == null || !authentication.isAuthenticated() ? null : required(authentication);
    }
}
