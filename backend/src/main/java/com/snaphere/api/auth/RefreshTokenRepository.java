package com.snaphere.api.auth;
import org.springframework.data.jpa.repository.JpaRepository; import java.util.*;
interface RefreshTokenRepository extends JpaRepository<RefreshToken, UUID> { Optional<RefreshToken> findByTokenHash(String tokenHash); List<RefreshToken> findAllByUserId(UUID userId); List<RefreshToken> findAllByDeviceId(UUID deviceId); }
