import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:snap_here/src/features/explore/application/explore_providers.dart';

class RankingsScreen extends ConsumerWidget {
  const RankingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final regions = ref.watch(mapRegionsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('랭킹')),
      body: regions.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('랭킹을 불러오지 못했어요'),
                const SizedBox(height: 8),
                Text('$error', textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => ref.invalidate(mapRegionsProvider),
                  child: const Text('다시 시도'),
                ),
              ],
            ),
          ),
        ),
        data: (items) {
          final ranked = [...items]
            ..sort((a, b) => b.postCount.compareTo(a.postCount));
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(mapRegionsProvider),
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
              itemCount: ranked.length,
              separatorBuilder: (_, _) => const Divider(),
              itemBuilder: (context, index) {
                final region = ranked[index];
                return ListTile(
                  leading: CircleAvatar(child: Text('${index + 1}')),
                  title: Text(region.name),
                  subtitle: Text(
                    '이번 주 ${region.postCount}개 · ${region.contributorCount}명 참여',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: region.representativePost == null
                      ? () => context.push('/regions/${region.areaCode}')
                      : () => context.push(
                          '/photos/${region.representativePost!.postId}',
                        ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
