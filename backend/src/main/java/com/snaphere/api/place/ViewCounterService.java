package com.snaphere.api.place;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import com.snaphere.api.config.PlaceTaskConfig;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.scheduling.annotation.Async;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

import java.util.Set;

@Service
public class ViewCounterService {
    private static final Logger log = LoggerFactory.getLogger(ViewCounterService.class);
    private static final String PREFIX = "place:view:";
    private final StringRedisTemplate redis;
    private final PlaceRepository places;

    public ViewCounterService(StringRedisTemplate redis, PlaceRepository places) {
        this.redis = redis;
        this.places = places;
    }

    @Async(PlaceTaskConfig.PLACE_TASK_EXECUTOR)
    public void increment(long placeId) {
        try {
            redis.opsForValue().increment(PREFIX + placeId);
        } catch (RuntimeException e) {
            try {
                places.addViewCount(placeId, 1);
            } catch (RuntimeException fallbackError) {
                e.addSuppressed(fallbackError);
                log.warn("장소 조회수 Redis·DB 증가 실패 placeId={}", placeId, e);
            }
        }
    }

    public long pending(long placeId) {
        try {
            String value = redis.opsForValue().get(PREFIX + placeId);
            return value == null ? 0 : Long.parseLong(value);
        } catch (RuntimeException e) {
            return 0;
        }
    }

    @Scheduled(cron = "${snaphere.jobs.view-flush-cron:0 * * * * *}", zone = "Asia/Seoul")
    public void flush() {
        Set<String> keys;
        try {
            keys = redis.keys(PREFIX + "*");
        } catch (RuntimeException e) {
            log.warn("조회수 키 조회 실패", e);
            return;
        }
        if (keys == null) return;
        for (String key : keys) {
            Long delta = null;
            try {
                String value = redis.opsForValue().getAndDelete(key);
                if (value == null) continue;
                delta = Long.parseLong(value);
                long placeId = Long.parseLong(key.substring(PREFIX.length()));
                places.addViewCount(placeId, delta);
            } catch (RuntimeException e) {
                if (delta != null) {
                    try { redis.opsForValue().increment(key, delta); } catch (RuntimeException ignored) { }
                }
                log.error("조회수 DB 반영 실패 key={}", key, e);
            }
        }
    }
}
