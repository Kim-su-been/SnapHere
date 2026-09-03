package com.snaphere.api.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

public final class PlatformProperties {
    private PlatformProperties() {
    }

    @ConfigurationProperties("snaphere.auth")
    public record Auth(
            String googleClientId,
            String jwtIssuer,
            String jwtPrivateKey,
            String jwtPublicKey,
            String adminGoogleSubjects,
            String termsVersion
    ) {
    }

    @ConfigurationProperties("snaphere.tour-api")
    public record TourApi(String baseUrl, String serviceKey, String mobileApp, String mobileOs) {
    }

    @ConfigurationProperties("snaphere.google")
    public record Google(String geocodingBaseUrl, String mapsApiKey) {
    }
}
