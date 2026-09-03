package com.snaphere.api.auth;

import com.snaphere.api.config.PlatformProperties;
import org.springframework.security.oauth2.jose.jws.SignatureAlgorithm;
import org.springframework.security.oauth2.jwt.JwtClaimsSet;
import org.springframework.security.oauth2.jwt.JwtEncoder;
import org.springframework.security.oauth2.jwt.JwtEncoderParameters;
import org.springframework.security.oauth2.jwt.JwsHeader;
import org.springframework.stereotype.Service;

import java.time.Instant;

@Service
public class JwtService {
    public static final long ACCESS_SECONDS = 7200;
    private final JwtEncoder encoder;
    private final PlatformProperties.Auth properties;

    public JwtService(JwtEncoder encoder, PlatformProperties.Auth properties) {
        this.encoder = encoder;
        this.properties = properties;
    }

    public String issueAccessToken(long userId, String role, String deviceId) {
        Instant now = Instant.now();
        JwtClaimsSet claims = JwtClaimsSet.builder()
                .issuer(properties.jwtIssuer())
                .issuedAt(now)
                .expiresAt(now.plusSeconds(ACCESS_SECONDS))
                .subject(ExternalIds.user(userId))
                .claim("role", role)
                .claim("device_id", deviceId)
                .build();
        return encoder.encode(JwtEncoderParameters.from(
                JwsHeader.with(SignatureAlgorithm.RS256).build(), claims)).getTokenValue();
    }
}
