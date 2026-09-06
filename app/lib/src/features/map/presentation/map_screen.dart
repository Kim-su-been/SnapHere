import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:snap_here/src/features/explore/application/explore_providers.dart';

class MapScreen extends ConsumerWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final regions = ref.watch(mapRegionsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('지도 탐색')),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(mapRegionsProvider),
        child: regions.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              const SizedBox(height: 180),
              const Icon(Icons.cloud_off_outlined, size: 52),
              const SizedBox(height: 12),
              const Center(child: Text('지도 데이터를 불러오지 못했어요')),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text('$error', textAlign: TextAlign.center),
              ),
              Center(
                child: FilledButton.icon(
                  onPressed: () => ref.invalidate(mapRegionsProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('다시 시도'),
                ),
              ),
            ],
          ),
          data: (items) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
            children: [
              Container(
                height: 220,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(20),
                ),
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.map_outlined, size: 72),
                    const SizedBox(height: 12),
                    Text('전국 ${items.length}개 지역의 주간 스냅'),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              for (final region in items)
                Card(
                  child: ListTile(
                    leading: CircleAvatar(child: Text('${region.postCount}')),
                    title: Text(region.name),
                    subtitle: Text('기여자 ${region.contributorCount}명'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/regions/${region.areaCode}'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
