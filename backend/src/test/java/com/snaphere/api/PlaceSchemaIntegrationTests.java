package com.snaphere.api;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.testcontainers.containers.GenericContainer;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;
import org.testcontainers.utility.DockerImageName;

import static org.assertj.core.api.Assertions.assertThat;

@SpringBootTest(properties = {
        "snaphere.jobs.place-sync-cron=-",
        "snaphere.jobs.view-flush-cron=-"
})
@Testcontainers(disabledWithoutDocker = true)
class PlaceSchemaIntegrationTests {
    @Container
    static final PostgreSQLContainer<?> POSTGRES = new PostgreSQLContainer<>(
            DockerImageName.parse("percona/percona-distribution-postgresql-with-postgis:17.10-2")
                    .asCompatibleSubstituteFor("postgres"));
    @Container
    static final GenericContainer<?> REDIS = new GenericContainer<>(DockerImageName.parse("redis:7.4-alpine"))
            .withExposedPorts(6379);

    @DynamicPropertySource
    static void properties(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", POSTGRES::getJdbcUrl);
        registry.add("spring.datasource.username", POSTGRES::getUsername);
        registry.add("spring.datasource.password", POSTGRES::getPassword);
        registry.add("spring.data.redis.host", REDIS::getHost);
        registry.add("spring.data.redis.port", () -> REDIS.getMappedPort(6379));
    }

    @Autowired JdbcClient jdbc;

    @Test
    void 시도_코드는_비연속_17개이고_고정된_DB_버전과_PostGIS가_활성화된다() {
        assertThat(jdbc.sql("SELECT area_code FROM regions ORDER BY area_code").query(Integer.class).list())
                .containsExactly(1,2,3,4,5,6,7,8,31,32,33,34,35,36,37,38,39);
        assertThat(jdbc.sql("SHOW server_version").query(String.class).single()).startsWith("17.10");
        assertThat(jdbc.sql("SELECT PostGIS_Lib_Version()").query(String.class).single()).isEqualTo("3.5.7");
    }
}
