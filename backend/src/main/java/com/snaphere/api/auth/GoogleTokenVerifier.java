package com.snaphere.api.auth;

import com.snaphere.api.common.error.ApiException;
import com.snaphere.api.common.error.ErrorCode;
import com.snaphere.api.config.PlatformProperties;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.jwt.JwtException;
import org.springframework.security.oauth2.jwt.NimbusJwtDecoder;
import org.springframework.stereotype.Component;

@Component
public class GoogleTokenVerifier {
    private final NimbusJwtDecoder decoder = NimbusJwtDecoder
            .withJwkSetUri("https://www.googleapis.com/oauth2/v3/certs").build();
    private final PlatformProperties.Auth properties;

    public GoogleTokenVerifier(PlatformProperties.Auth properties) {
        this.properties = properties;
    }

    public AuthDtos.GoogleIdentity verify(String token) {
        try {
            Jwt jwt = decoder.decode(token);
            String issuer = jwt.getIssuer() == null ? "" : jwt.getIssuer().toString();
            if (!("https://accounts.google.com".equals(issuer) || "accounts.google.com".equals(issuer))) {
                throw new ApiException(ErrorCode.AUTH_INVALID_GOOGLE_TOKEN);
            }
            if (properties.googleClientId() == null || properties.googleClientId().isBlank()
                    || !jwt.getAudience().contains(properties.googleClientId())) {
                throw new ApiException(ErrorCode.AUTH_AUDIENCE_MISMATCH);
            }
            return new AuthDtos.GoogleIdentity(jwt.getSubject(), jwt.getClaimAsString("email"),
                    jwt.getClaimAsString("name"), jwt.getClaimAsString("picture"));
        } catch (ApiException e) {
            throw e;
        } catch (JwtException e) {
            throw new ApiException(ErrorCode.AUTH_INVALID_GOOGLE_TOKEN);
        }
    }
}
