package com.snaphere.api.auth;

import jakarta.persistence.*;
import java.time.Instant;
import java.util.UUID;

@Entity @Table(name = "users")
public class User {
    @Id private UUID id;
    @Column(name = "google_subject", nullable = false, unique = true) private String googleSubject;
    @Column(nullable = false) private String email;
    private String nickname;
    @Column(name = "profile_image_url") private String profileImageUrl;
    @Enumerated(EnumType.STRING) @Column(nullable = false) private UserStatus status;
    @Enumerated(EnumType.STRING) @Column(nullable = false) private UserRole role;
    @Column(name = "onboarding_completed", nullable = false) private boolean onboardingCompleted;
    @Column(name = "terms_version") private String termsVersion;
    @Column(nullable = false) private String locale;
    @Column(name = "created_at", nullable = false) private Instant createdAt;
    @Column(name = "updated_at", nullable = false) private Instant updatedAt;
    protected User() {}
    public static User newGoogleUser(String subject, String email, String picture) { User u = new User(); u.id=UUID.randomUUID(); u.googleSubject=subject; u.email=email; u.profileImageUrl=picture; u.status=UserStatus.PENDING; u.role=UserRole.USER; u.locale="ko-KR"; u.createdAt=u.updatedAt=Instant.now(); return u; }
    public UUID getId(){return id;} public String getEmail(){return email;} public String getNickname(){return nickname;} public String getProfileImageUrl(){return profileImageUrl;} public UserStatus getStatus(){return status;} public UserRole getRole(){return role;} public boolean isOnboardingCompleted(){return onboardingCompleted;} public String getLocale(){return locale;}
    public void completeOnboarding(String nickname, String termsVersion, String locale) { this.nickname=nickname; this.termsVersion=termsVersion; this.locale=locale; this.onboardingCompleted=true; this.status=UserStatus.ACTIVE; this.updatedAt=Instant.now(); }
}
