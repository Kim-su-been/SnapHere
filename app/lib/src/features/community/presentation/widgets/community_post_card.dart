import 'package:flutter/material.dart';
import 'package:snap_here/src/app/theme/app_tokens.dart';
import 'package:snap_here/src/features/community/domain/community_models.dart';

/// Figma `DS/Components / Content/PostCard`.
/// `03_커뮤니티_전체`와 `03_커뮤니티_검색결과`가 같은 카드를 쓴다.
class CommunityPostCard extends StatelessWidget {
  const CommunityPostCard({required this.post, this.onTap, super.key});

  final CommunityPost post;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(post: post),
            _Thumbnail(post: post),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.sm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(post.title, style: textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    post.content,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            _Footer(post: post),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.post});

  final CommunityPost post;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          _Avatar(author: post.author),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.author.nickname,
                  style: textTheme.labelLarge,
                  overflow: TextOverflow.ellipsis,
                ),
                if (post.locationLabel case final label?) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(
                        Icons.place_outlined,
                        size: 12,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          label,
                          style: textTheme.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (post.badge case final badge?) ...[
            const SizedBox(width: AppSpacing.sm),
            _BadgeChip(label: badge.label),
          ],
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.author});

  final CommunityAuthor author;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.brandSubtle,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        author.avatarLabel,
        style: Theme.of(context).textTheme.bodySmall
            ?.copyWith(color: AppColors.textPrimary),
      ),
    );
  }
}

class _BadgeChip extends StatelessWidget {
  const _BadgeChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.brandSubtle,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall
            ?.copyWith(color: AppColors.textPrimary),
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.post});

  final CommunityPost post;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: AspectRatio(
          aspectRatio: 16 / 10,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // API 연동 전에는 URL이 없어 자리 표시자를 그린다.
              if (post.thumbnailUrl case final url?)
                Image.network(url, fit: BoxFit.cover)
              else
                const ColoredBox(
                  color: AppColors.brandSubtle,
                  child: Icon(
                    Icons.photo_outlined,
                    size: 40,
                    color: AppColors.textSecondary,
                  ),
                ),
              if (post.imageCount > 1)
                Positioned(
                  top: AppSpacing.sm,
                  right: AppSpacing.sm,
                  child: _ImageCountChip(count: post.imageCount),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImageCountChip extends StatelessWidget {
  const _ImageCountChip({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.textPrimary.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.photo_library_outlined,
            size: 12,
            color: Colors.white,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            '+${count - 1}',
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.post});

  final CommunityPost post;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: Row(
        children: [
          const Icon(
            Icons.favorite_border,
            size: 16,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text('${post.likeCount}', style: textTheme.bodySmall),
          const SizedBox(width: AppSpacing.md),
          const Icon(
            Icons.chat_bubble_outline,
            size: 16,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text('${post.commentCount}', style: textTheme.bodySmall),
          const Spacer(),
          Text(formatRelativeTime(post.createdAt), style: textTheme.bodySmall),
        ],
      ),
    );
  }
}

/// Figma가 `2시간 전`, `3시간 전`처럼 상대 시각을 쓴다.
@visibleForTesting
String formatRelativeTime(DateTime createdAt, {DateTime? now}) {
  final elapsed = (now ?? DateTime.now()).difference(createdAt);
  if (elapsed.inMinutes < 1) return '방금 전';
  if (elapsed.inHours < 1) return '${elapsed.inMinutes}분 전';
  if (elapsed.inDays < 1) return '${elapsed.inHours}시간 전';
  if (elapsed.inDays < 7) return '${elapsed.inDays}일 전';
  return '${createdAt.year}.${createdAt.month}.${createdAt.day}';
}
