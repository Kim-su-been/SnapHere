package com.snaphere.api.config;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.nimbusds.jose.jwk.JWKSet;
import com.nimbusds.jose.jwk.RSAKey;
import com.nimbusds.jose.jwk.source.JWKSource;
import com.nimbusds.jose.proc.SecurityContext;
import com.snaphere.api.common.error.ErrorBody;
import com.snaphere.api.common.error.ErrorCode;
import com.snaphere.api.common.web.ApiResponse;
import com.snaphere.api.common.web.TraceIdFilter;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.MediaType;
import org.springframework.http.HttpMethod;
import org.springframework.security.config.Customizer;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.security.oauth2.jwt.JwtEncoder;
import org.springframework.security.oauth2.jwt.NimbusJwtDecoder;
import org.springframework.security.oauth2.jwt.NimbusJwtEncoder;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationConverter;
import org.springframework.security.web.SecurityFilterChain;

import java.security.KeyFactory;
import java.security.KeyPair;
import java.security.KeyPairGenerator;
import java.security.interfaces.RSAPrivateKey;
import java.security.interfaces.RSAPublicKey;
import java.security.spec.PKCS8EncodedKeySpec;
import java.security.spec.X509EncodedKeySpec;
import java.util.Base64;
import java.util.List;

@Configuration
@EnableMethodSecurity
public class SecurityConfig {

    @Bean
    RsaKeys rsaKeys(PlatformProperties.Auth properties) {
        try {
            if (hasText(properties.jwtPrivateKey()) && hasText(properties.jwtPublicKey())) {
                KeyFactory factory = KeyFactory.getInstance("RSA");
                RSAPrivateKey privateKey = (RSAPrivateKey) factory.generatePrivate(
                        new PKCS8EncodedKeySpec(decodePem(properties.jwtPrivateKey())));
                RSAPublicKey publicKey = (RSAPublicKey) factory.generatePublic(
                        new X509EncodedKeySpec(decodePem(properties.jwtPublicKey())));
                return new RsaKeys(publicKey, privateKey);
            }
            KeyPairGenerator generator = KeyPairGenerator.getInstance("RSA");
            generator.initialize(2048);
            KeyPair pair = generator.generateKeyPair();
            return new RsaKeys((RSAPublicKey) pair.getPublic(), (RSAPrivateKey) pair.getPrivate());
        } catch (Exception e) {
            throw new IllegalStateException("JWT RSA 키를 읽지 못했습니다.", e);
        }
    }

    @Bean
    JwtEncoder jwtEncoder(RsaKeys keys) {
        RSAKey rsaKey = new RSAKey.Builder(keys.publicKey()).privateKey(keys.privateKey()).build();
        JWKSource<SecurityContext> source = (selector, context) -> selector.select(new JWKSet(rsaKey));
        return new NimbusJwtEncoder(source);
    }

    @Bean
    JwtDecoder jwtDecoder(RsaKeys keys) {
        return NimbusJwtDecoder.withPublicKey(keys.publicKey()).build();
    }

    @Bean
    SecurityFilterChain securityFilterChain(HttpSecurity http, ObjectMapper mapper) throws Exception {
        JwtAuthenticationConverter converter = new JwtAuthenticationConverter();
        converter.setJwtGrantedAuthoritiesConverter(jwt -> {
            String role = jwt.getClaimAsString("role");
            return role == null ? List.of() : List.of(new SimpleGrantedAuthority("ROLE_" + role));
        });

        http.csrf(csrf -> csrf.disable())
                .cors(Customizer.withDefaults())
                .authorizeHttpRequests(auth -> auth
                        .requestMatchers("/actuator/health", "/api/v1/auth/google", "/api/v1/auth/refresh").permitAll()
                        .requestMatchers("/api/v1/admin/**").hasRole("ADMIN")
                        .requestMatchers(HttpMethod.GET, "/api/v1/regions/**", "/api/v1/places/**").permitAll()
                        .requestMatchers("/api/v1/auth/onboarding", "/api/v1/auth/logout").authenticated()
                        .requestMatchers("/api/v1/me/**", "/api/v1/tags/**").authenticated()
                        .requestMatchers(HttpMethod.POST, "/api/v1/places/**").authenticated()
                        .requestMatchers(HttpMethod.PUT, "/api/v1/places/**").authenticated()
                        .requestMatchers(HttpMethod.DELETE, "/api/v1/places/**").authenticated()
                        .anyRequest().permitAll())
                .oauth2ResourceServer(oauth -> oauth
                        .jwt(jwt -> jwt.jwtAuthenticationConverter(converter))
                        .authenticationEntryPoint((request, response, exception) -> writeError(
                                mapper, request, response, ErrorCode.AUTH_REQUIRED)))
                .exceptionHandling(errors -> errors.accessDeniedHandler((request, response, exception) ->
                        writeError(mapper, request, response, ErrorCode.ADMIN_REQUIRED)));
        return http.build();
    }

    private static void writeError(ObjectMapper mapper, jakarta.servlet.http.HttpServletRequest request,
                                   HttpServletResponse response, ErrorCode code) throws java.io.IOException {
        response.setStatus(code.status().value());
        response.setContentType(MediaType.APPLICATION_JSON_VALUE);
        mapper.writeValue(response.getOutputStream(), ApiResponse.fail(
                ErrorBody.of(code), TraceIdFilter.currentTraceId(request)));
    }

    private static byte[] decodePem(String value) {
        String normalized = value.replace("\\n", "\n")
                .replaceAll("-----BEGIN [A-Z ]+-----", "")
                .replaceAll("-----END [A-Z ]+-----", "")
                .replaceAll("\\s", "");
        return Base64.getDecoder().decode(normalized);
    }

    private static boolean hasText(String value) {
        return value != null && !value.isBlank();
    }

    public record RsaKeys(RSAPublicKey publicKey, RSAPrivateKey privateKey) {
    }
}
