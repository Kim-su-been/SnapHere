package com.snaphere.api.auth;

import com.snaphere.api.common.web.ApiResponse;
import com.snaphere.api.common.web.TraceIdFilter;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/auth")
public class AuthController {
    private final AuthService service;

    public AuthController(AuthService service) { this.service = service; }

    @PostMapping("/google")
    ApiResponse<AuthDtos.AuthResult> google(@Valid @RequestBody AuthDtos.GoogleLoginRequest body,
                                             HttpServletRequest request) {
        return ApiResponse.ok(service.googleLogin(body), TraceIdFilter.currentTraceId(request));
    }

    @PostMapping("/onboarding")
    ResponseEntity<ApiResponse<AuthDtos.AuthUser>> onboarding(Authentication authentication,
                                                               @Valid @RequestBody AuthDtos.OnboardingRequest body,
                                                               HttpServletRequest request) {
        var user = service.onboard(CurrentActor.required(authentication), body);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.ok(user, TraceIdFilter.currentTraceId(request)));
    }

    @PostMapping("/refresh")
    ApiResponse<AuthDtos.AuthResult> refresh(@Valid @RequestBody AuthDtos.RefreshRequest body,
                                              HttpServletRequest request) {
        return ApiResponse.ok(service.refresh(body), TraceIdFilter.currentTraceId(request));
    }

    @PostMapping("/logout")
    ResponseEntity<Void> logout(Authentication authentication) {
        service.logout(CurrentActor.required(authentication));
        return ResponseEntity.noContent().build();
    }
}
