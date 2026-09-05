package com.snaphere.api.social;
import com.snaphere.api.common.error.ApiException; import org.junit.jupiter.api.Test; import java.time.Instant; import java.util.UUID; import static org.assertj.core.api.Assertions.*;
class FollowCursorTest { @Test void 커서를_왕복한다(){FollowCursor c=new FollowCursor(Instant.parse("2026-09-06T00:00:00Z"),UUID.randomUUID());assertThat(FollowCursor.decode(c.encode())).isEqualTo(c);}@Test void 깨진_커서는_400이다(){assertThatThrownBy(()->FollowCursor.decode("bad")).isInstanceOf(ApiException.class);} }
