package com.snaphere.api.auth;
import org.springframework.data.jpa.repository.JpaRepository; import java.util.*;
interface UserRepository extends JpaRepository<User, UUID> { Optional<User> findByGoogleSubject(String googleSubject); }
