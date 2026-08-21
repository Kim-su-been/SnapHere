import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SnapHere'),
        actions: [
          IconButton(
            tooltip: '검색',
            onPressed: () => context.push('/search'),
            icon: const Icon(Icons.search),
          ),
          IconButton(
            tooltip: '알림',
            onPressed: () => context.push('/notifications'),
            icon: const Icon(Icons.notifications_none),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
        children: [
          Text(
            '어디의 순간을 볼까요?',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final region in ['서울', '부산', '대전', '제주', '강원'])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      label: Text(region),
                      onPressed: () => context.push('/regions/$region'),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Text('이번 주 인기 사진', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          _PhotoCard(
            onTap: () => context.push('/photos/sample-photo'),
            onPlaceTap: () => context.push('/places/sample-place'),
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
    );
  }
}

class _PhotoCard extends StatelessWidget {
  const _PhotoCard({required this.onTap, required this.onPlaceTap});

  final VoidCallback onTap;
  final VoidCallback onPlaceTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 220,
              color: Theme.of(context).colorScheme.primaryContainer,
              alignment: Alignment.center,
              child: const Icon(Icons.landscape_outlined, size: 72),
            ),
            ListTile(
              title: const Text('여행자가 발견한 오늘의 풍경'),
              subtitle: TextButton.icon(
                onPressed: onPlaceTap,
                icon: const Icon(Icons.place_outlined, size: 18),
                label: const Text('관광지 상세 보기'),
              ),
              trailing: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.favorite_border),
                  SizedBox(width: 4),
                  Text('128'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
