package com.snaphere.api.auth;

import com.snaphere.api.common.error.ApiException;
import com.snaphere.api.common.error.ErrorCode;
import com.snaphere.api.config.PlatformProperties;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.SecureRandom;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.Base64;
import java.util.Set;
import java.util.stream.Collectors;
import java.util.stream.Stream;

@Service
public class AuthService {
    private static final long REFRESH_SECONDS = 30L * 24 * 60 * 60;
    private final JdbcClient jdbc;
    private final GoogleTokenVerifier google;
    private final JwtService jwt;
    private final PlatformProperties.Auth properties;
    private final SecureRandom random = new SecureRandom();

    public AuthService(JdbcClient jdbc, GoogleTokenVerifier google, JwtService jwt,
                       PlatformProperties.Auth properties) {
        this.jdbc = jdbc;
        this.google = google;
        this.jwt = jwt;
        this.properties = properties;
    }

    @Transactional
    public AuthDtos.AuthResult googleLogin(AuthDtos.GoogleLoginRequest request) {
        AuthDtos.GoogleIdentity identity = google.verify(request.idToken());
        Set<String> admins = Stream.of(nullToEmpty(properties.adminGoogleSubjects()).split(","))
                .map(String::trim).filter(s -> !s.isEmpty()).collect(Collectors.toSet());
        String role = admins.contains(identity.subject()) ? "ADMIN" : "USER";
        long userId = jdbc.sql("""
                INSERT INTO users(provider, provider_user_id, email, nickname, profile_image_url, role)
                VALUES ('GOOGLE', :sub, :email, :name, :picture, :role)
                ON CONFLICT (provider, provider_user_id) DO UPDATE SET
                  email=excluded.email, profile_image_url=excluded.profile_image_url,
                  role=CASE WHEN excluded.role='ADMIN' THEN 'ADMIN' ELSE users.role END, updated_at=now()
                RETURNING user_id
                """).param("sub", identity.subject()).param("email", identity.email())
                .param("name", identity.name()).param("picture", identity.picture()).param("role", role)
                .query(Long.class).single();
        jdbc.sql("""
                INSERT INTO user_devices(device_id,user_id,fcm_token,platform)
                VALUES (:device,:user,:fcm,:platform)
                ON CONFLICT(device_id) DO UPDATE SET user_id=excluded.user_id,
                  fcm_token=excluded.fcm_token, platform=excluded.platform, updated_at=now()
                """).param("device", request.deviceId()).param("user", userId)
                .param("fcm", request.fcmToken()).param("platform", request.platform()).update();
        return issueResult(userId, request.deviceId());
    }

    @Transactional
    public AuthDtos.AuthUser onboard(CurrentActor actor, AuthDtos.OnboardingRequest request) {
        if (!properties.termsVersion().equals(request.termsVersion())) {
            throw new ApiException(ErrorCode.AUTH_TERMS_REQUIRED);
        }
        jdbc.sql("""
                UPDATE users SET nickname=:nickname, locale=:locale, terms_agreed_at=now(), updated_at=now()
                WHERE user_id=:id AND status='ACTIVE'
                """).param("nickname", request.nickname().trim()).param("locale", request.locale())
                .param("id", actor.userId()).update();
        return profile(actor.userId());
    }

    @Transactional(noRollbackFor = ApiException.class)
    public AuthDtos.AuthResult refresh(AuthDtos.RefreshRequest request) {
        String hash = hash(request.refreshToken());
        RefreshRow row = jdbc.sql("""
                SELECT user_id, device_id, expires_at, revoked_at, replaced_by_hash
                FROM refresh_tokens WHERE token_hash=:hash FOR UPDATE
                """).param("hash", hash).query((rs, n) -> new RefreshRow(rs.getLong(1), rs.getString(2),
                        rs.getTimestamp(3).toInstant(), rs.getTimestamp(4) == null ? null : rs.getTimestamp(4).toInstant(),
                        rs.getString(5))).optional().orElseThrow(() -> new ApiException(ErrorCode.AUTH_INVALID_REFRESH));
        if (!row.deviceId().equals(request.deviceId())) throw new ApiException(ErrorCode.AUTH_INVALID_REFRESH);
        if (row.expiresAt().isBefore(Instant.now())) throw new ApiException(ErrorCode.AUTH_REFRESH_EXPIRED);
        if (row.revokedAt() != null) {
            if (row.replacedByHash() != null) {
                jdbc.sql("UPDATE refresh_tokens SET revoked_at=coalesce(revoked_at,now()) WHERE user_id=:user")
                        .param("user", row.userId()).update();
                throw new ApiException(ErrorCode.AUTH_TOKEN_REUSED);
            }
            throw new ApiException(ErrorCode.AUTH_INVALID_REFRESH);
        }
        String raw = newRefreshToken();
        String nextHash = hash(raw);
        jdbc.sql("UPDATE refresh_tokens SET revoked_at=now(), replaced_by_hash=:next WHERE token_hash=:hash")
                .param("next", nextHash).param("hash", hash).update();
        insertRefresh(nextHash, row.userId(), row.deviceId());
        return resultWithToken(row.userId(), row.deviceId(), raw);
    }

    @Transactional
    public void logout(CurrentActor actor) {
        jdbc.sql("UPDATE refresh_tokens SET revoked_at=coalesce(revoked_at,now()) WHERE user_id=:user AND device_id=:device")
                .param("user", actor.userId()).param("device", actor.deviceId()).update();
        jdbc.sql("UPDATE user_devices SET fcm_token=NULL, updated_at=now() WHERE user_id=:user AND device_id=:device")
                .param("user", actor.userId()).param("device", actor.deviceId()).update();
    }

    private AuthDtos.AuthResult issueResult(long userId, String deviceId) {
        String raw = newRefreshToken();
        insertRefresh(hash(raw), userId, deviceId);
        return resultWithToken(userId, deviceId, raw);
    }

    private AuthDtos.AuthResult resultWithToken(long userId, String deviceId, String rawRefresh) {
        AuthDtos.AuthUser user = profile(userId);
        String access = jwt.issueAccessToken(userId, user.role(), deviceId);
        AuthDtos.TokenBundle bundle = new AuthDtos.TokenBundle(access, JwtService.ACCESS_SECONDS,
                rawRefresh, REFRESH_SECONDS);
        return new AuthDtos.AuthResult(bundle, user, user.needsProfileSetup(), false, null);
    }

    private AuthDtos.AuthUser profile(long userId) {
        return jdbc.sql("""
                SELECT user_id,email,nickname,profile_image_url,locale,role,terms_agreed_at
                FROM users WHERE user_id=:id AND status='ACTIVE'
                """).param("id", userId).query((rs, n) -> new AuthDtos.AuthUser(
                        ExternalIds.user(rs.getLong("user_id")), rs.getString("email"), rs.getString("nickname"),
                        rs.getString("profile_image_url"), rs.getString("locale"), rs.getString("role"),
                        rs.getTimestamp("terms_agreed_at") == null)).single();
    }

    private void insertRefresh(String hash, long userId, String deviceId) {
        jdbc.sql("""
                INSERT INTO refresh_tokens(token_hash,user_id,device_id,expires_at)
                VALUES (:hash,:user,:device,:expires)
                """).param("hash", hash).param("user", userId).param("device", deviceId)
                .param("expires", Instant.now().plus(REFRESH_SECONDS, ChronoUnit.SECONDS)).update();
    }

    private String newRefreshToken() {
        byte[] bytes = new byte[32];
        random.nextBytes(bytes);
        return "rt_" + Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
    }

    private static String hash(String value) {
        try {
            return java.util.HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256")
                    .digest(value.getBytes(StandardCharsets.UTF_8)));
        } catch (Exception e) {
            throw new IllegalStateException(e);
        }
    }

    private static String nullToEmpty(String value) { return value == null ? "" : value; }
    private record RefreshRow(long userId, String deviceId, Instant expiresAt,
                              Instant revokedAt, String replacedByHash) { }
}
