// JDK 21 이 로컬에 없어도 Gradle 이 알아서 내려받게 한다.
// 팀원 환경마다 자바 버전이 달라도 같은 툴체인으로 빌드된다.
plugins {
    id("org.gradle.toolchains.foojay-resolver-convention") version "0.8.0"
}

rootProject.name = "snaphere-api"
