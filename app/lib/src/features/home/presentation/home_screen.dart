import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:snap_here/src/features/community/presentation/widgets/community_post_card.dart';
import 'package:snap_here/src/features/explore/application/explore_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final regions = ref.watch(regionsProvider);
    final posts = ref.watch(homePopularPostsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('SnapHere'),
        actions: [
          IconButton(
            tooltip: '검색',
            onPressed: () => context.push('/community/search'),
            icon: const Icon(Icons.search),
          ),
          IconButton(
            tooltip: '알림',
            onPressed: () => context.push('/notifications'),
            icon: const Icon(Icons.notifications_none),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(regionsProvider);
          ref.invalidate(homePopularPostsProvider);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
          children: [
            Text(
              '어디의 순간을 볼까요?',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 48,
              child: regions.when(
                loading: () => const Align(
                  alignment: Alignment.centerLeft,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                error: (error, _) => TextButton(
                  onPressed: () => ref.invalidate(regionsProvider),
                  child: Text('지역 다시 불러오기 · $error'),
                ),
                data: (items) => ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) => ActionChip(
                    label: Text(items[index].name),
                    onPressed: () =>
                        context.push('/regions/${items[index].areaCode}'),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
            Text('이번 주 인기 사진', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            posts.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => ListTile(
                leading: const Icon(Icons.cloud_off_outlined),
                title: const Text('인기 사진을 불러오지 못했어요'),
                subtitle: Text('$error'),
                trailing: const Icon(Icons.refresh),
                onTap: () => ref.invalidate(homePopularPostsProvider),
              ),
              data: (items) => items.isEmpty
                  ? const ListTile(title: Text('아직 등록된 사진이 없어요.'))
                  : CommunityPostCard(
                      post: items.first,
                      onTap: () =>
                          context.push('/photos/${items.first.postId}'),
                    ),
            ),
            const SizedBox(height: 28),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.movie_filter_outlined),
              title: const Text('K-컬처 촬영지'),
              subtitle: const Text('드라마·영화·예능 속 장소를 둘러보세요.'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/k-culture'),
            ),
          ],
        ),
      ),
    );
  }
}
