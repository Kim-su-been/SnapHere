package com.snaphere.api.auth;
import org.springframework.data.jpa.repository.JpaRepository; import java.util.*;
interface UserDeviceRepository extends JpaRepository<UserDevice, UUID> { Optional<UserDevice> findByUserIdAndDeviceIdentifier(UUID userId, String deviceIdentifier); }
