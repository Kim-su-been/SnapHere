package com.snaphere.api.auth;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

import java.util.Map;

public final class AuthDtos {
    private AuthDtos() {
    }

    public record GoogleLoginRequest(
            @NotBlank String idToken,
            @NotBlank String deviceId,
            @Pattern(regexp = "IOS|ANDROID") String platform,
            String fcmToken
    ) {
    }

    public record OnboardingRequest(
            @NotBlank @Size(min = 2, max = 20) String nickname,
            @NotBlank String termsVersion,
            @Pattern(regexp = "ko-KR|en-US|zh-CN|ja-JP") String locale
    ) {
    }

    public record RefreshRequest(@NotBlank String refreshToken, @NotBlank String deviceId) {
    }

    public record TokenBundle(String accessToken, long accessTokenExpiresIn,
                              String refreshToken, long refreshTokenExpiresIn) {
    }

    public record AuthUser(String userId, String email, String nickname, String profileImageUrl,
                           String locale, String role, boolean needsProfileSetup) {
    }

    public record AuthResult(TokenBundle tokens, AuthUser user, boolean onboardingRequired,
                             boolean recoveryOffered, String restoreKey) {
    }

    public record GoogleIdentity(String subject, String email, String name, String picture) {
    }

    public static Map<String, Object> empty() {
        return Map.of();
    }
}
