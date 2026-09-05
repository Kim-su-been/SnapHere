package com.snaphere.api.place;

import org.springframework.stereotype.Component;

import java.util.List;

/**
 * {@code events} 테이블이 생기기 전까지 쓰는 구현. 항상 빈 목록.
 *
 * <p><b>실제 구현을 추가할 때 이 파일을 지운다.</b> 조건부 등록을 걸지 않았으므로 구현이 하나 더
 * 생기면 애플리케이션이 뜨지 않고 중복 빈을 알려 준다 — NoOpBadgeAwarder 와 같은 방식이다.
 *
 * <p>빈 목록이라 행사 참여 업로드에서 고정 태그가 아직 붙지 않는다. 추천이 하나 비는 것은
 * 화면에서 조용히 지나가지만, 없는 테이블을 읽으면 업로드 자체가 실패한다.
 */
@Component
public class NoOpEventFixedTagReader implements EventFixedTagReader {

    @Override
    public List<String> fixedTagNames(long eventId) {
        return List.of();
    }
}
