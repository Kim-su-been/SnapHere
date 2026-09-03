package com.snaphere.api.post.media;

import com.snaphere.api.common.config.AsyncConfig;
import com.snaphere.api.post.event.PostCreatedEvent;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Component;
import org.springframework.transaction.event.TransactionPhase;
import org.springframework.transaction.event.TransactionalEventListener;

/**
 * 게시글이 커밋된 뒤 이미지 후처리를 시작한다. (PST-019)
 *
 * <p>{@link TransactionPhase#AFTER_COMMIT} 이어야 한다. 커밋 전에 시작하면 후처리 스레드가
 * {@code post_images} 를 조회할 때 행이 아직 없다.
 *
 * <p>{@link Async} 라 등록 응답을 기다리게 하지 않는다. 후처리가 실패해도 게시글은 남는다 —
 * 사진은 원본 그대로 보이고 썸네일·해시만 비어 있다. 그 상태를 응답 계약이 견디도록
 * 목록에서는 원본 주소와 기본 비율을 대신 준다 (PST-021).
 */
@Component
public class PostImageProcessingListener {

    private final PostImagePostProcessor processor;

    public PostImageProcessingListener(PostImagePostProcessor processor) {
        this.processor = processor;
    }

    @Async(AsyncConfig.IMAGE_PROCESSING_EXECUTOR)
    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)
    public void onPostCreated(PostCreatedEvent event) {
        processor.process(event.postId());
    }
}
