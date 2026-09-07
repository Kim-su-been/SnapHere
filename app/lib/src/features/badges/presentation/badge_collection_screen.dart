import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:snap_here/src/app/theme/app_tokens.dart';
import 'package:snap_here/src/core/ui/design_icon.dart';
import 'package:snap_here/src/core/ui/paged_sliver.dart';
import 'package:snap_here/src/core/ui/remote_image.dart';
import 'package:snap_here/src/features/badges/application/badge_providers.dart';
import 'package:snap_here/src/features/badges/domain/badge_models.dart';
import 'package:snap_here/src/features/badges/presentation/visit_map_panel.dart';

/// Figma 92:2259: 방문 지도 280px + 획득한 뱃지 목록.
class BadgeCollectionScreen extends ConsumerWidget {
  const BadgeCollectionScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collection = ref.watch(badgeCollectionProvider);
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('수집한 뱃지'),
        toolbarHeight: 48,
        leading: const DesignBackButton(),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(badgeCollectionProvider);
          ref.invalidate(visitMapProvider);
          await ref
              .read(badgeCollectionProvider.future)
              .then<void>((_) {}, onError: (Object _, StackTrace _) {});
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          children: [
            const VisitMapPanel(),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Text(
                '내 뱃지 목록',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(height: 12),
            collection.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => RetryMessage(
                message: '뱃지를 불러오지 못했어요',
                onRetry: () => ref.invalidate(badgeCollectionProvider),
              ),
              data: (data) {
                final earned = data.items
                    .where((badge) => badge.earned)
                    .toList();
                if (earned.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 64),
                    child: Text(
                      '아직 수집한 뱃지가 없어요\n여행 사진을 올리고 첫 뱃지를 모아 보세요.',
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                return Column(
                  children: [
                    for (final badge in earned)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: _BadgeRow(badge: badge),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _BadgeRow extends StatelessWidget {
  const _BadgeRow({required this.badge});
  final CollectedBadge badge;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: const BorderSide(color: AppColors.border),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: () => showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (_) => BadgeDetailSheet(badgeId: badge.id),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            SizedBox.square(
              dimension: 40,
              child: ClipOval(child: RemoteImage(url: badge.iconUrl)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    badge.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    badge.earnedAt == null
                        ? '획득한 뱃지'
                        : '${_date(badge.earnedAt!)} 획득',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const DesignIcon('chevron', size: 16),
          ],
        ),
      ),
    ),
  );
}

class BadgeDetailSheet extends ConsumerWidget {
  const BadgeDetailSheet({required this.badgeId, super.key});
  final String badgeId;
  @override
  Widget build(BuildContext context, WidgetRef ref) => SafeArea(
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: ref
          .watch(badgeDetailProvider(badgeId))
          .when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => RetryMessage(
              message: '뱃지 상세를 불러오지 못했어요',
              onRetry: () => ref.invalidate(badgeDetailProvider(badgeId)),
            ),
            data: (detail) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: SizedBox.square(
                    dimension: 64,
                    child: ClipOval(
                      child: RemoteImage(url: detail.badge.iconUrl),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  detail.badge.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (detail.badge.description case final description?) ...[
                  const SizedBox(height: 12),
                  Text(description, textAlign: TextAlign.center),
                ],
                const SizedBox(height: 16),
                Text(
                  '진행 ${detail.currentValue} / ${detail.targetValue} · ${detail.earnedCount}명 획득',
                  textAlign: TextAlign.center,
                ),
                if (detail.sourcePostId case final postId?) ...[
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () {
                      context.pop();
                      context.push('/photos/$postId');
                    },
                    child: const Text('뱃지를 획득한 게시글 보기'),
                  ),
                ],
              ],
            ),
          ),
    ),
  );
}

String _date(DateTime value) {
  final local = value.toLocal();
  return '${local.year}.${local.month.toString().padLeft(2, '0')}.${local.day.toString().padLeft(2, '0')}';
}
